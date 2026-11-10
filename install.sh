#!/usr/bin/env bash
set -euo pipefail

# Suraksha Agent Skills Installer for macOS / Linux (POSIX / Bash)
# Installs, upgrades, or uninstalls Suraksha skills with SHA-256 manifest tracking.

SURAKSHA_VERSION="0.1.0"
DEFAULT_REPO_URL="https://github.com/hari7261/suraksha.git"
MANIFEST_NAME=".suraksha-install.json"
SKILLS=("appsec" "secure-review" "secure-implementation" "vulnerability-remediation")

AGENT=""
SCOPE="project"
TARGET=""
DRY_RUN=0
FORCE=0
UPGRADE=0
UNINSTALL=0
LIST=0
REPO_URL="$DEFAULT_REPO_URL"
BRANCH="main"

usage() {
  cat <<EOF
Suraksha Agent Skills Installer v${SURAKSHA_VERSION}

Usage:
  ./install.sh --agent <name> [--scope project|user] [options]
  ./install.sh --target <path> [options]
  ./install.sh --list

Options:
  --agent <name>       antigravity, claude-code, codex, gemini-cli, cursor, github-copilot
  --scope <scope>      project (default) or user
  --target <path>      Custom skill destination directory
  --dry-run            Preview actions without writing or deleting files
  --force              Overwrite differing files (creates .bak.<timestamp>) and
                       allow installing experimental adapters
  --upgrade            Upgrade existing Suraksha install using manifest hashes
  --uninstall          Remove only files recorded in ${MANIFEST_NAME}
  --list               List supported agents, status, and paths
  --repo-url <url>     Git URL when running outside a local checkout
  --branch <name>      Git branch for remote install (default: main)
  -h, --help           Show this help message
EOF
}

list_agents() {
  cat <<EOF
Supported Agents (Suraksha v${SURAKSHA_VERSION}):

  antigravity     [verified]
    project: .agents/skills
    user:    ~/.gemini/config/skills
  claude-code     [experimental]
    project: .claude/skills
    user:    ~/.claude/skills
  codex           [experimental]
    project: .codex/skills
    user:    ~/.codex/skills
  gemini-cli      [experimental]
    project: .gemini/skills
    user:    ~/.gemini/skills
  cursor          [experimental]
    project: .cursor/skills
    user:    ~/.cursor/skills
  github-copilot  [experimental]
    project: .github/skills
    user:    ~/.copilot/skills
EOF
}

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    echo "Error: sha256sum or shasum is required." >&2
    exit 1
  fi
}

adapter_status() {
  case "$1" in
    antigravity) echo "verified" ;;
    claude-code|codex|gemini-cli|cursor|github-copilot) echo "experimental" ;;
    *) echo "unknown" ;;
  esac
}

resolve_target() {
  if [ -n "$TARGET" ]; then
    echo "$TARGET"
    return
  fi
  if [ -z "$AGENT" ]; then
    echo ""
    return
  fi
  if [ "$SCOPE" != "project" ] && [ "$SCOPE" != "user" ]; then
    echo "Invalid scope: $SCOPE (must be project or user)" >&2
    exit 2
  fi
  case "$AGENT:$SCOPE" in
    antigravity:project) echo "$PWD/.agents/skills" ;;
    antigravity:user)    echo "$HOME/.gemini/config/skills" ;;
    claude-code:project) echo "$PWD/.claude/skills" ;;
    claude-code:user)    echo "$HOME/.claude/skills" ;;
    codex:project)       echo "$PWD/.codex/skills" ;;
    codex:user)          echo "$HOME/.codex/skills" ;;
    gemini-cli:project)  echo "$PWD/.gemini/skills" ;;
    gemini-cli:user)     echo "$HOME/.gemini/skills" ;;
    cursor:project)      echo "$PWD/.cursor/skills" ;;
    cursor:user)         echo "$HOME/.cursor/skills" ;;
    github-copilot:project) echo "$PWD/.github/skills" ;;
    github-copilot:user)    echo "$HOME/.copilot/skills" ;;
    *)
      echo "Unsupported agent: $AGENT" >&2
      exit 2
      ;;
  esac
}

while [ $# -gt 0 ]; do
  case "$1" in
    --agent)     AGENT="${2:?missing agent}"; shift 2 ;;
    --scope)     SCOPE="${2:?missing scope}"; shift 2 ;;
    --target)    TARGET="${2:?missing target}"; shift 2 ;;
    --repo-url)  REPO_URL="${2:?missing repo-url}"; shift 2 ;;
    --branch)    BRANCH="${2:?missing branch}"; shift 2 ;;
    --dry-run)   DRY_RUN=1; shift ;;
    --force)     FORCE=1; shift ;;
    --upgrade)   UPGRADE=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    --list)      LIST=1; shift ;;
    -h|--help)   usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

if [ "$LIST" -eq 1 ]; then
  list_agents
  exit 0
fi

DEST_DIR="$(resolve_target)"
if [ -z "$DEST_DIR" ]; then
  usage
  exit 0
fi

MANIFEST_PATH="$DEST_DIR/$MANIFEST_NAME"

if [ "$UNINSTALL" -eq 1 ]; then
  if [ ! -f "$MANIFEST_PATH" ]; then
    echo "No install manifest found at $MANIFEST_PATH." >&2
    exit 1
  fi
  SKIPPED=0
  while IFS= read -r line; do
    rel_path="$(echo "$line" | sed -n 's/.*"path": *"\([^"]*\)".*/\1/p')"
    exp_hash="$(echo "$line" | sed -n 's/.*"sha256": *"\([^"]*\)".*/\1/p')"
    if [ -z "$rel_path" ]; then
      continue
    fi
    full="$DEST_DIR/$rel_path"
    if [ -f "$full" ]; then
      cur_hash="$(sha256_file "$full")"
      if [ "$cur_hash" != "$exp_hash" ] && [ "$FORCE" -ne 1 ]; then
        echo "Warning: skipping locally modified file (use --force): $rel_path" >&2
        SKIPPED=$((SKIPPED + 1))
        continue
      fi
      if [ "$DRY_RUN" -eq 1 ]; then
        echo "[DRY-RUN] Remove $full"
      else
        rm -f "$full"
      fi
    fi
  done < "$MANIFEST_PATH"

  if [ "$SKIPPED" -gt 0 ]; then
    echo "Uninstall incomplete: $SKIPPED modified file(s) preserved." >&2
    exit 1
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "[DRY-RUN] Remove $MANIFEST_PATH"
  else
    rm -f "$MANIFEST_PATH"
    for s in "${SKILLS[@]}"; do
      if [ -d "$DEST_DIR/$s" ]; then
        find "$DEST_DIR/$s" -depth -type d -empty -delete 2>/dev/null || true
      fi
    done
    echo "Uninstalled Suraksha skills from $DEST_DIR"
  fi
  exit 0
fi

if [ -z "$TARGET" ] && [ -n "$AGENT" ]; then
  STATUS="$(adapter_status "$AGENT")"
  if [ "$STATUS" = "experimental" ] && [ "$FORCE" -ne 1 ] && [ "$DRY_RUN" -ne 1 ] && [ "$UPGRADE" -ne 1 ]; then
    echo "Adapter '$AGENT' is marked experimental. Pass --force to install or --dry-run to preview." >&2
    exit 1
  fi
fi

SCRIPT_SOURCE="${BASH_SOURCE[0]:-}"
if [ -n "$SCRIPT_SOURCE" ] && [ -f "$SCRIPT_SOURCE" ]; then
  SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_SOURCE")" && pwd)"
else
  SCRIPT_DIR="$PWD"
fi
SKILLS_SRC="$SCRIPT_DIR/skills"
TEMP_CLONE=""

cleanup() {
  if [ -n "$TEMP_CLONE" ] && [ -d "$TEMP_CLONE" ]; then
    rm -rf "$TEMP_CLONE"
  fi
}
trap cleanup EXIT

if [ ! -f "$SKILLS_SRC/appsec/SKILL.md" ]; then
  if ! command -v git >/dev/null 2>&1; then
    echo "Error: local skills/ directory not found and git is unavailable." >&2
    exit 1
  fi
  TEMP_CLONE="$(mktemp -d)"
  echo "Fetching Suraksha skills from $REPO_URL ($BRANCH)..."
  git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$TEMP_CLONE" >/dev/null
  SKILLS_SRC="$TEMP_CLONE/skills"
fi

if [ "$UPGRADE" -eq 1 ] && [ ! -f "$MANIFEST_PATH" ]; then
  echo "Cannot upgrade: no existing manifest at $MANIFEST_PATH." >&2
  exit 1
fi

TIMESTAMP="$(date -u +%Y%m%d%H%M%S)"
FILE_LIST=()
for s in "${SKILLS[@]}"; do
  while IFS= read -r -d '' f; do
    FILE_LIST+=("$f")
  done < <(find "$SKILLS_SRC/$s" -type f -print0 | sort -z)
done

# Conflict check
for src in "${FILE_LIST[@]}"; do
  rel="${src#$SKILLS_SRC/}"
  dest="$DEST_DIR/$rel"
  if [ -f "$dest" ]; then
    src_hash="$(sha256_file "$src")"
    dest_hash="$(sha256_file "$dest")"
    if [ "$src_hash" != "$dest_hash" ] && [ "$FORCE" -ne 1 ] && [ "$UPGRADE" -ne 1 ]; then
      echo "Conflict on existing file '$rel' (content differs). Pass --force to back up and overwrite." >&2
      exit 1
    fi
  fi
done

if [ "$DRY_RUN" -eq 0 ]; then
  mkdir -p "$DEST_DIR"
fi

ENTRIES=""
COUNT=0
for src in "${FILE_LIST[@]}"; do
  rel="${src#$SKILLS_SRC/}"
  dest="$DEST_DIR/$rel"
  src_hash="$(sha256_file "$src")"
  if [ -f "$dest" ]; then
    dest_hash="$(sha256_file "$dest")"
    if [ "$src_hash" != "$dest_hash" ]; then
      if [ "$DRY_RUN" -eq 1 ]; then
        echo "[DRY-RUN] Backup $dest -> $dest.bak.$TIMESTAMP"
      else
        cp "$dest" "$dest.bak.$TIMESTAMP"
      fi
    fi
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "[DRY-RUN] Copy $rel -> $dest"
  else
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
  fi
  [ -n "$ENTRIES" ] && ENTRIES="$ENTRIES,\n"
  ENTRIES="${ENTRIES}    {\"path\": \"${rel}\", \"sha256\": \"${src_hash}\"}"
  COUNT=$((COUNT + 1))
done

if [ "$DRY_RUN" -eq 1 ]; then
  echo "[DRY-RUN] Write manifest $MANIFEST_PATH ($COUNT files)"
  exit 0
fi

NOW_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
AGENT_LABEL="${AGENT:-custom}"
SCOPE_LABEL="$([ -n "$TARGET" ] && echo "custom" || echo "$SCOPE")"

printf '{\n  "package": "suraksha",\n  "version": "%s",\n  "agent": "%s",\n  "scope": "%s",\n  "installed_at": "%s",\n  "skills": ["appsec", "secure-review", "secure-implementation", "vulnerability-remediation"],\n  "files": [\n%b\n  ]\n}\n' \
  "$SURAKSHA_VERSION" "$AGENT_LABEL" "$SCOPE_LABEL" "$NOW_UTC" "$ENTRIES" > "$MANIFEST_PATH"

echo "Installed Suraksha skills ($COUNT files) into $DEST_DIR"
echo "Manifest written to $MANIFEST_PATH"

