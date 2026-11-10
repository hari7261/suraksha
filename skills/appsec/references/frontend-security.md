# Frontend Security

## 1. Objective
Prevent XSS, CSRF, open redirects, insecure browser storage of credentials, and client-side secret exposure in web applications (React, Next.js, Vue, HTML/JS).

## 2. Threat Model
- **Attackers:** Malicious users injecting HTML/JS payloads (stored, reflected, DOM XSS), third-party scripts abusing weak CSP, or phishing links chaining open redirects.
- **Attack surface:** Rich-text rendering, `dangerouslySetInnerHTML`, `href`/`src` URL attributes, `localStorage`, CORS/cookies, and `NEXT_PUBLIC_*` / `VITE_*` build variables.

## 3. Common Vulnerabilities
- **XSS (CWE-79):** Rendering unsanitized HTML via `dangerouslySetInnerHTML`, `innerHTML`, or `v-html`.
- **Unsafe URL schemes:** Rendering `javascript:` or `data:` links in `<a href={userUrl}>`.
- **Storing tokens in `localStorage`:** Exposes long-lived auth tokens to any XSS or compromised third-party dependency.
- **Client secret exposure:** Prefixing private API keys with `NEXT_PUBLIC_`, `VITE_`, or `REACT_APP_` so they bundle into browser JS.
- **Open Redirect (CWE-601):** Redirecting `next` / `redirectTo` query parameters to arbitrary external origins.
- **Missing CSRF protection:** State-changing cookie-authenticated endpoints lacking `SameSite` + CSRF tokens.

## 4. Vulnerable Example
```tsx
// React / Next.js — VULNERABLE: DOM XSS + unsafe javascript: URL + client secret leak
export function ProfileBio({ bioHtml, websiteUrl }: { bioHtml: string; websiteUrl: string }) {
  const apiKey = process.env.NEXT_PUBLIC_STRIPE_SECRET_KEY; // bundled to browser!
  return (
    <div>
      <a href={websiteUrl}>Website</a>
      <div dangerouslySetInnerHTML={{ __html: bioHtml }} />
    </div>
  );
}
```

## 5. Secure Example
```tsx
// SECURE: Strict URL protocol allowlist, DOMPurify sanitization only when HTML is truly required
import DOMPurify from "dompurify";

function safeHttpUrl(raw: string): string {
  try {
    const u = new URL(raw);
    return u.protocol === "https:" || u.protocol === "http:" ? u.toString() : "#";
  } catch {
    return "#";
  }
}

export function ProfileBio({ bioHtml, websiteUrl }: { bioHtml: string; websiteUrl: string }) {
  const cleanHtml = DOMPurify.sanitize(bioHtml, { ALLOWED_TAGS: ["b", "i", "em", "strong", "p", "br"] });
  return (
    <div>
      <a href={safeHttpUrl(websiteUrl)} rel="noopener noreferrer">Website</a>
      <div dangerouslySetInnerHTML={{ __html: cleanHtml }} />
    </div>
  );
}
```

## 6. Framework Notes
- **React / Next.js:** Keep secrets strictly in Server Components / Route Handlers (`process.env.STRIPE_SECRET_KEY`, never `NEXT_PUBLIC_*`). Validate Next.js Server Actions as public HTTP endpoints (auth + input schema!).
- **Cookies & Auth State:** Prefer `HttpOnly; Secure; SameSite=Lax` cookies over `localStorage` for session tokens.
- **CSP:** Ship a strict `Content-Security-Policy` avoiding `unsafe-inline` and `unsafe-eval` where possible; add `X-Content-Type-Options: nosniff` and `frame-ancestors 'none'`.

## 7. Detection Strategy
- Search for `dangerouslySetInnerHTML`, `innerHTML`, `eval(`, `document.write`, `target="_blank"` without `rel="noopener noreferrer"`, and `NEXT_PUBLIC_` / `VITE_` containing `SECRET`, `KEY`, or `TOKEN`.

## 8. Remediation
- Replace raw HTML injection with plain JSX text rendering, or sanitize with a maintained library (`DOMPurify`) paired with CSP.
- Restrict redirect targets to relative paths or an explicit domain allowlist.

## 9. Testing Requirements
- Test `<img src=x onerror=alert(1)>` and `javascript:alert(1)` inputs against all rendered user content and link fields.
- Verify secret environment variables do not appear in compiled client bundles.

## 10. Standards References
- OWASP Top 10 (2021) — A03:2021 Injection, A05:2021 Security Misconfiguration
- OWASP ASVS 4.0.3 (V5.3 Output Encoding, V14.4 HTTP Security Headers)
- CWE-79 (XSS), CWE-352 (CSRF), CWE-601 (Open Redirect)

