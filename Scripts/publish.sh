#!/bin/zsh
# Publishes the DMG that release.sh built:
#   1. a GitHub Release (tag <version>, e.g. 6.1.9, no "v" as in earlier releases) in
#      perez987/DownloadFullInstaller holding Download.Full.Installer.<version>.dmg
#   2. the Sparkle update feed (appcast.xml at the repository root, on main) pointing at it.
#
# Usage (from anywhere), one change per line, either in Scripts/RELEASE_NOTES.txt:
#   ./Scripts/publish.sh
# or in a variable, which takes precedence over the file:
#   RELEASE_NOTES=$'First change\nSecond change' ./Scripts/publish.sh
# The notes are listed on the GitHub Release and added at the top of the appcast description
# as "What's New in Download Full Installer <version>" (the earlier history in appcast.xml is
# kept). HTML such as <i>…</i> is allowed.
#
# Needs: release.sh run first; `gh` installed and signed in (gh auth login); the Sparkle EdDSA
# private key in the login keychain (the one matching SUPublicEDKey in Info.plist). Sparkle's
# generate_keys stores it under the account "ed25519" unless --account was used; if you used
# another account, run with SPARKLE_ACCOUNT=<name>.

# This script uses zsh syntax: if started with sh/bash, run it again under zsh.
[ -n "${ZSH_VERSION:-}" ] || exec /bin/zsh "$0" "$@"

set -euo pipefail

SCRIPT_DIR="${0:A:h}"                 # .../DownloadFullInstaller/Scripts
REPO_ROOT="${SCRIPT_DIR:h}"           # .../DownloadFullInstaller (repository root, where appcast.xml lives)
XCODE_DIR="$REPO_ROOT/Xcode-project"  # where DownloadFullInstaller.xcodeproj lives
SCHEME=DownloadFullInstaller
APP="Download Full Installer"
ASSET_BASE="Download.Full.Installer"
PROJECT="$XCODE_DIR/$SCHEME.xcodeproj"
REPO=perez987/DownloadFullInstaller
BRANCH=main                           # SUFeedURL reads appcast.xml from this branch
SPARKLE_ACCOUNT="${SPARKLE_ACCOUNT:-ed25519}"
WORK="$HOME/Library/Caches/DownloadFullInstallerRelease"
APPCAST="$REPO_ROOT/appcast.xml"
NOTES_FILE="$SCRIPT_DIR/RELEASE_NOTES.txt"

# --- Checks ---------------------------------------------------------------------------------
command -v gh >/dev/null || { echo "gh is missing: brew install gh && gh auth login"; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "gh isn't signed in: gh auth login"; exit 1; }

SIGN_UPDATE="$WORK/DerivedData/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update"
[[ -x "$SIGN_UPDATE" ]] || { echo "Sparkle's sign_update isn't there — run release.sh first."; exit 1; }

current_branch=$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD)
[[ "$current_branch" == "$BRANCH" ]] || { echo "Switch to $BRANCH first (now on $current_branch)."; exit 1; }
git -C "$REPO_ROOT" diff --quiet -- appcast.xml \
  || { echo "appcast.xml has uncommitted changes; commit or discard them first."; exit 1; }

settings=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release -showBuildSettings 2>/dev/null)
VERSION=$(print -r -- "$settings" | awk -F' = ' '/ MARKETING_VERSION = /{print $2; exit}')
BUILD=$(print -r -- "$settings" | awk -F' = ' '/ CURRENT_PROJECT_VERSION = /{print $2; exit}')
MINIMUM=$(print -r -- "$settings" | awk -F' = ' '/ MACOSX_DEPLOYMENT_TARGET = /{print $2; exit}')
[[ -n "$VERSION" && -n "$BUILD" && -n "$MINIMUM" ]] || { echo "Couldn't read the version from $PROJECT"; exit 1; }
TAG="$VERSION"
ASSET="$ASSET_BASE.$VERSION.dmg"
DMG="$REPO_ROOT/Distribute/$ASSET"

[[ -f "$DMG" ]] || { echo "No $DMG — run release.sh first."; exit 1; }
if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
  echo "Release $TAG already exists. Raise the version (and build number) first."
  exit 1
fi

# --- Release notes --------------------------------------------------------------------------
# From the RELEASE_NOTES variable if set, otherwise from Scripts/RELEASE_NOTES.txt. In the file,
# lines starting with # are comments, a leading "- " is dropped, and the line "Version: <x>"
# must match the project's version so old notes are never published by mistake.
if [[ -z "${RELEASE_NOTES:-}" && -f "$NOTES_FILE" ]]; then
  file_version=$(sed -n 's/^[[:space:]]*Version:[[:space:]]*\([^[:space:]]*\).*/\1/p' "$NOTES_FILE" | head -1)
  [[ "$file_version" == "$VERSION" ]] \
    || { echo "$NOTES_FILE is for version '${file_version:-?}', the project is $VERSION: update it first."; exit 1; }
  RELEASE_NOTES=$(grep -v -E '^[[:space:]]*(#|Version:)' "$NOTES_FILE" | sed -E 's/^[[:space:]]*-[[:space:]]+//; s/[[:space:]]+$//')
  echo "==> Release notes read from $NOTES_FILE"
fi
[[ "${RELEASE_NOTES:-}" != *']]>'* ]] || { echo "The release notes can't contain ]]>."; exit 1; }
changes=("${(@f)${RELEASE_NOTES:-}}")
changes=(${changes:#})                       # drop empty lines
# Every version in appcast.xml has its own "What's New" list, so notes are required.
(( ${#changes} )) || { echo "No release notes: fill in $NOTES_FILE or set RELEASE_NOTES=\$'First change\\nSecond change'."; exit 1; }
notes=$(printf -- '- %s\n' "${changes[@]}")

echo "==> $APP $VERSION ($BUILD) → $REPO $TAG"

# --- Sparkle signature ----------------------------------------------------------------------
echo "==> Signing the update for Sparkle (keychain account: $SPARKLE_ACCOUNT)"
# Prints: sparkle:edSignature="…" length="…"
signature=$("$SIGN_UPDATE" --account "$SPARKLE_ACCOUNT" "$DMG")
[[ "$signature" == *edSignature=* && "$signature" == *length=* ]] || { echo "sign_update failed: $signature"; exit 1; }

# --- GitHub Release -------------------------------------------------------------------------
echo "==> Creating GitHub Release $TAG"
gh release create "$TAG" "$DMG" --repo "$REPO" --target "$BRANCH" \
  --title "$APP $VERSION" --notes "$notes"

# --- Update feed ----------------------------------------------------------------------------
echo "==> Updating appcast.xml"
APPCAST="$APPCAST" APPNAME="$APP" VERSION="$VERSION" BUILD="$BUILD" MINIMUM="$MINIMUM" \
SIGNATURE="$signature" PUBDATE="$(LC_ALL=C date "+%a, %d %b %Y %H:%M:%S %z")" \
URL="https://github.com/$REPO/releases/download/$TAG/$ASSET" \
CHANGES="${(pj:\n:)changes}" \
/usr/bin/python3 - <<'PY'
import os, re, sys

e = os.environ
path = e["APPCAST"]
with open(path, encoding="utf-8") as f:
    xml = f.read()

start = xml.find("<item>")
end = xml.find("</item>", start)
if start < 0 or end < 0:
    sys.exit("appcast.xml: no <item> found")
item = xml[start:end]

def replace(pattern, new):
    global item
    item, n = re.subn(pattern, lambda m: new, item, count=1, flags=re.S)
    if n != 1:
        sys.exit(f"appcast.xml: {pattern!r} not found in <item>")

name, v = e["APPNAME"], e["VERSION"]
sig = re.search(r'sparkle:edSignature="([^"]+)"', e["SIGNATURE"])
length = re.search(r'length="(\d+)"', e["SIGNATURE"])
if not sig or not length:
    sys.exit("sign_update output not understood: " + e["SIGNATURE"])

replace(r"<title>.*?</title>", f"<title>{name} {v}</title>")
replace(r"<pubDate>.*?</pubDate>", f"<pubDate>{e['PUBDATE']}</pubDate>")
replace(r"<sparkle:version>.*?</sparkle:version>", f"<sparkle:version>{e['BUILD']}</sparkle:version>")
replace(r"<sparkle:shortVersionString>.*?</sparkle:shortVersionString>",
        f"<sparkle:shortVersionString>{v}</sparkle:shortVersionString>")
replace(r"<sparkle:minimumSystemVersion>.*?</sparkle:minimumSystemVersion>",
        f"<sparkle:minimumSystemVersion>{e['MINIMUM']}</sparkle:minimumSystemVersion>")
replace(r"<enclosure\b.*?/>",
        "<enclosure \n"
        f"            url=\"{e['URL']}\" \n"
        f"            length=\"{length.group(1)}\" \n"
        "            type=\"application/octet-stream\" \n"
        f"            sparkle:edSignature=\"{sig.group(1)}\"/>")

changes = [c.strip() for c in e.get("CHANGES", "").split("\n") if c.strip()]
block = (f"\n\t\t\t\t<h3>What's New in {name} {v}</h3>\n\t\t\t\t<ul>\n"
         + "".join(f"\t\t\t\t\t<li>{c}</li>\n" for c in changes)
         + "\t\t\t\t</ul>")
item, n = re.subn(r"(<description[^>]*><!\[CDATA\[)", lambda m: m.group(1) + block, item, count=1)
if n != 1:
    sys.exit("appcast.xml: no <description><![CDATA[ found in <item>")

with open(path, "w", encoding="utf-8") as f:
    f.write(xml[:start] + item + xml[end:])
PY

git -C "$REPO_ROOT" add appcast.xml
git -C "$REPO_ROOT" commit -q -m "Publish update feed for $APP $VERSION"
git -C "$REPO_ROOT" push -q origin "$BRANCH"
echo "==> Done: https://github.com/$REPO/releases/tag/$TAG"
echo "    Remember to add the changes to NOTES-<version>.md if you keep it up to date."
