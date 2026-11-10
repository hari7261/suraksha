# Mobile Security

## 1. Objective
Protect mobile applications (iOS Swift, Android Kotlin, React Native, Expo) against insecure local storage, WebView/deep-link abuse, weak transport trust, and client-side trust assumptions.

## 2. Threat Model
- **Attackers:** Physical device attackers, malicious apps on the same device probing exported components/deep links, and network MITM attackers on untrusted Wi-Fi.
- **Attack surface:** `AsyncStorage`/`SharedPreferences`/`UserDefaults`, Keychain/Keystore, deep links / Universal Links, `WebView`, local SQLite/Realm DBs, clipboard/screenshots, and debug builds.

## 3. Common Vulnerabilities
- Storing tokens, PINs, or PII in unencrypted `AsyncStorage`, `SharedPreferences`, or `UserDefaults`.
- **Android exported components / deep links:** Unvalidated `intent://` or custom URL scheme (`myapp://open?url=...`) leading to open redirect or privileged screen bypass.
- **WebView abuse:** Enabling `javaScriptEnabled` + JS bridges (`addJavascriptInterface`) on untrusted URLs, or allowing `file://` access.
- **Debug artifacts in release:** `android:debuggable="true"`, verbose logs, or embedded test credentials in APK/IPA bundles (anything bundled in JS/native binary is extractable!).
- **Screenshot / clipboard leakage:** Sensitive screens cached in app switcher snapshots or OTPs/passwords exposed via system clipboard.

## 4. Vulnerable Example
```typescript
// React Native — VULNERABLE: storing JWT in plaintext AsyncStorage + unvalidated deep link
import AsyncStorage from "@react-native-async-storage/async-storage";

await AsyncStorage.setItem("access_token", jwtToken); // readable on rooted/backed-up devices!
Linking.addEventListener("url", ({ url }) => {
  const target = new URL(url).searchParams.get("next");
  webViewRef.current?.loadUrl(target); // arbitrary URL in WebView!
});
```

## 5. Secure Example
```typescript
// React Native / Expo — SECURE: Keychain/Keystore via expo-secure-store + strict deep-link allowlist
import * as SecureStore from "expo-secure-store";

await SecureStore.setItemAsync("access_token", jwtToken, {
  keychainAccessible: SecureStore.WHEN_UNLOCKED_THIS_DEVICE_ONLY,
});

const ALLOWED_ROUTES = new Set(["/orders", "/profile"]);
function handleDeepLink(rawUrl: string): string {
  const parsed = new URL(rawUrl);
  const route = parsed.pathname;
  return ALLOWED_ROUTES.has(route) ? route : "/home";
}
```

## 6. Framework Notes
- **iOS:** Use Keychain Services with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`; keep App Transport Security (ATS) enabled (`NSAllowsArbitraryLoads = false`).
- **Android:** Use `EncryptedSharedPreferences` / Android Keystore, set `android:allowBackup="false"` (or exclude sensitive files), `usesCleartextTraffic="false"`, and `android:exported="false"` on internal Activities/Services/Receivers.
- **React Native / Expo:** Never bundle private API secrets via `EXPO_PUBLIC_*` or `react-native-config` expecting secrecy—clients are untrusted; enforce auth/rate-limits on the backend.
- **Certificate Pinning (Trade-offs):** Pinning protects against rogue CAs and MITM inspection, **but** carries operational risk: expired/rotated pins can brick installed app versions until users update. Discuss pin rotation (backup pins, short-lived SPKI pins, remote config caveats) rather than mandating pinning unconditionally.
- **Root / Jailbreak Detection:** Treat client-side root/jailbreak checks as **defense-in-depth telemetry/friction**, never as a security boundary (can be hooked/bypassed).
- **Local DBs / UI:** Use SQLCipher for sensitive offline DBs, `FLAG_SECURE` (Android) / blur overlay (iOS) on sensitive screens, and avoid copying secrets to clipboard.

## 7. Detection Strategy
- Search for `AsyncStorage`, `UserDefaults`, `MODE_WORLD_READABLE`, `allowsArbitraryLoads`, `usesCleartextTraffic`, `setJavaScriptEnabled(true)`, and `android:exported="true"`.

## 8. Remediation
- Migrate secrets to Keychain / Android Keystore, validate deep-link hosts/paths against strict allowlists, restrict WebViews to trusted HTTPS origins, and strip debug flags from release builds.

## 9. Testing Requirements
- Inspect release APK/IPA with `Manifest` checks (`debuggable=false`, `exported` components), test malformed deep-link URIs, and verify tokens are absent from plaintext app storage.

## 10. Standards References
- OWASP MASVS 2.1.0 (MASVS-STORAGE, MASVS-CRYPTO, MASVS-NETWORK, MASVS-PLATFORM)
- OWASP Mobile Top 10 (2024)
- CWE-312, CWE-926, CWE-749

