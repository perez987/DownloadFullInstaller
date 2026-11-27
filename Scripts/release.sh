#!/bin/zsh
# Builds a signed, notarized DMG of Download Full Installer that opens without Gatekeeper
# warnings on any Mac:
#   <repo>/Distribute/Download.Full.Installer.<version>.dmg
# Then publish.sh uploads it to a GitHub Release and updates the Sparkle feed (appcast.xml).
#
# Usage:
#   ./release.sh                    full run: archive, export, notarize app, DMG
#   DMG_ONLY=1 ./release.sh         reuse the app already notarized in the cache
#                                           and only rebuild, sign and notarize the DMG
#   DMG_TOOL=node ./release.sh      choose how the DMG is made (see below)
#
# DMG_TOOL:
#   appdmg (default)  appdmg (npm) with our own background (Xcode-project/Backgrounds/background.png and
#                     background@2x.png) and icon layout. Writes the window layout (.DS_Store)
#                     directly, without scripting Finder, so it works on Tahoe on Intel.
#   node              sindresorhus' create-dmg (npm) with its own standard design.
#
# Needs, all kept OUT of this repository:
#   - a "Developer ID Application" certificate (team ER43ZD2S4U) in the login keychain
#   - notarization credentials stored once in the keychain (the app-specific password is typed
#     at the prompt, never written in a file):
#       xcrun notarytool store-credentials "notary-profile" --apple-id <your Apple ID> --team-id ER43ZD2S4U
#   - the DMG tool: npm install -g appdmg   (or npm install -g create-dmg for DMG_TOOL=node)
#
# Before each release raise MARKETING_VERSION and CURRENT_PROJECT_VERSION in the project:
# Sparkle compares the build number (CURRENT_PROJECT_VERSION, e.g. 6.1.8 → 0618).

# This script uses zsh syntax. If it was started with "sh release.sh" or "bash release.sh",
# run it again under zsh.
[ -n "${ZSH_VERSION:-}" ] || exec /bin/zsh "$0" "$@"

set -euo pipefail

SCRIPT_DIR="${0:A:h}"                 # .../DownloadFullInstaller/Scripts
REPO_ROOT="${SCRIPT_DIR:h}"           # .../DownloadFullInstaller (git repository root)
XCODE_DIR="$REPO_ROOT/Xcode-project"  # where DownloadFullInstaller.xcodeproj lives
SCHEME=DownloadFullInstaller          # project and scheme name
APP="Download Full Installer"         # PRODUCT_NAME: the .app and the DMG volume name
ASSET_BASE="Download.Full.Installer"  # DMG file name used by earlier releases (no spaces)
PROJECT="$XCODE_DIR/$SCHEME.xcodeproj"
TEAM=ER43ZD2S4U
IDENTITY="Developer ID Application"
NOTARY_PROFILE=notary-profile
# Built outside the repository and outside synced folders (iCloud/Dropbox add extended
# attributes that make code signing fail).
WORK="$HOME/Library/Caches/DownloadFullInstallerRelease"
DIST="$REPO_ROOT/Distribute"
APP_PATH="$WORK/export/$APP.app"
DMG_TOOL="${DMG_TOOL:-appdmg}"
DMG_ONLY="${DMG_ONLY:-0}"
BG="$XCODE_DIR/Backgrounds/background.png"         # 600 × 380
BG2="$XCODE_DIR/Backgrounds/background@2x.png"     # 1200 × 760

# --- Checks ---------------------------------------------------------------------------------
security find-identity -v -p codesigning | grep -q "$IDENTITY" \
  || { echo "No \"$IDENTITY\" certificate in the keychain."; exit 1; }

# Finds the DMG tool before the long build, so a missing tool fails at once.
case "$DMG_TOOL" in
  appdmg)
    # A global appdmg, or the copy that the npm create-dmg already brings with it.
    APPDMG=()
    if command -v appdmg >/dev/null; then
      APPDMG=("$(command -v appdmg)")
    elif command -v npm >/dev/null; then
      npm_root="$(npm root -g 2>/dev/null)"
      for js in "$npm_root/appdmg/bin/appdmg.js" "$npm_root/create-dmg/node_modules/appdmg/bin/appdmg.js"; do
        if [[ -f "$js" ]]; then APPDMG=(node "$js"); break; fi
      done
    fi
    (( ${#APPDMG} )) || { echo "appdmg is missing: npm install -g appdmg"; exit 1; }
    [[ -f "$BG" && -f "$BG2" ]] || { echo "Missing $BG or $BG2"; exit 1; }
    ;;
  node)
    command -v create-dmg >/dev/null \
      || { echo "The npm create-dmg is missing: npm install -g create-dmg"; exit 1; }
    ;;
  *) echo "Unknown DMG_TOOL=$DMG_TOOL (use appdmg or node)"; exit 1 ;;
esac

# Submits a file to Apple's notary service and fails if it isn't accepted.
notarize() {
  local file=$1 out id
  out=$(xcrun notarytool submit "$file" --keychain-profile "$NOTARY_PROFILE" --wait --output-format json) || true
  print -r -- "$out"
  if ! print -r -- "$out" | grep -q '"status" *: *"Accepted"'; then
    id=$(print -r -- "$out" | sed -n 's/.*"id" *: *"\([^"]*\)".*/\1/p' | head -1)
    echo "Notarization failed for $file"
    [[ -n "$id" ]] && xcrun notarytool log "$id" --keychain-profile "$NOTARY_PROFILE"
    exit 1
  fi
}

# --- Version --------------------------------------------------------------------------------
settings=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release -showBuildSettings 2>/dev/null)
VERSION=$(print -r -- "$settings" | awk -F' = ' '/ MARKETING_VERSION = /{print $2; exit}')
BUILD=$(print -r -- "$settings" | awk -F' = ' '/ CURRENT_PROJECT_VERSION = /{print $2; exit}')
[[ -n "$VERSION" && -n "$BUILD" ]] || { echo "Couldn't read the version from $PROJECT"; exit 1; }
echo "==> $APP $VERSION ($BUILD), DMG made with $DMG_TOOL"
mkdir -p "$WORK" "$DIST"

if [[ "$DMG_ONLY" == 1 ]]; then
  # --- Reuse the app from the last full run ---------------------------------------------------
  [[ -d "$APP_PATH" ]] || { echo "No $APP_PATH: run once without DMG_ONLY=1."; exit 1; }
  built=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$APP_PATH/Contents/Info.plist")
  [[ "$built" == "$BUILD" ]] \
    || { echo "The cached app is build $built, the project is $BUILD: run without DMG_ONLY=1."; exit 1; }
  xcrun stapler validate "$APP_PATH" >/dev/null \
    || { echo "The cached app isn't notarized: run without DMG_ONLY=1."; exit 1; }
  echo "==> Reusing the notarized app in $APP_PATH"
else
  rm -rf "$WORK/export" "$WORK/$SCHEME.xcarchive" "$WORK/$SCHEME.zip"

  # --- Archive and export -------------------------------------------------------------------
  echo "==> Archiving a Release build"
  # DerivedData is kept between runs: publish.sh uses Sparkle's sign_update from it.
  xcodebuild archive -quiet \
    -project "$PROJECT" -scheme "$SCHEME" -configuration Release \
    -destination "generic/platform=macOS" \
    -archivePath "$WORK/$SCHEME.xcarchive" -derivedDataPath "$WORK/DerivedData" \
    CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="$IDENTITY" DEVELOPMENT_TEAM="$TEAM"

  echo "==> Exporting, signed with Developer ID"
  cat > "$WORK/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key><string>developer-id</string>
  <key>teamID</key><string>$TEAM</string>
  <key>signingStyle</key><string>manual</string>
  <key>signingCertificate</key><string>$IDENTITY</string>
</dict>
</plist>
PLIST
  xcodebuild -exportArchive -quiet \
    -archivePath "$WORK/$SCHEME.xcarchive" \
    -exportOptionsPlist "$WORK/ExportOptions.plist" \
    -exportPath "$WORK/export"
  [[ -d "$APP_PATH" ]] || { echo "The export didn't produce $APP_PATH"; exit 1; }
  codesign --verify --deep --strict --verbose=2 "$APP_PATH"

  # --- Notarize the app ---------------------------------------------------------------------
  echo "==> Notarizing the app"
  ditto -c -k --keepParent "$APP_PATH" "$WORK/$SCHEME.zip"
  notarize "$WORK/$SCHEME.zip"
  xcrun stapler staple "$APP_PATH"
fi

# --- DMG ------------------------------------------------------------------------------------
echo "==> Building the DMG"
DMG="$DIST/$ASSET_BASE.$VERSION.dmg"
rm -f "$DMG"

case "$DMG_TOOL" in
  appdmg)
    # Window 600 × 380, the size of the background. 148-point icons at 160 and 440 across
    # (even about the 300-point middle) and 205 down, level with the arrow in the background.
    # appdmg picks up background@2x.png next to background.png for Retina displays.
    cat > "$WORK/appdmg.json" <<JSON
{
  "title": "$APP",
  "background": "$BG",
  "icon-size": 148,
  "window": { "size": { "width": 600, "height": 380 } },
  "format": "UDZO",
  "contents": [
    { "x": 160, "y": 205, "type": "file", "path": "$APP_PATH" },
    { "x": 440, "y": 205, "type": "link", "path": "/Applications" }
  ]
}
JSON
    "${APPDMG[@]}" "$WORK/appdmg.json" "$DMG"
    ;;
  node)
    # Its own design (app icon on a disk image, standard background). We sign the DMG below.
    rm -rf "$WORK/node-dmg"
    mkdir -p "$WORK/node-dmg"
    create-dmg "$APP_PATH" "$WORK/node-dmg" --overwrite --no-code-sign --dmg-title="$APP"
    made=("$WORK"/node-dmg/*.dmg(N))
    (( ${#made} == 1 )) || { echo "create-dmg didn't leave one DMG in $WORK/node-dmg"; exit 1; }
    mv "$made[1]" "$DMG"
    ;;
esac
[[ -f "$DMG" ]] || { echo "No DMG was made at $DMG"; exit 1; }

echo "==> Signing and notarizing the DMG"
codesign --force --sign "$IDENTITY" --timestamp "$DMG"
notarize "$DMG"
xcrun stapler staple "$DMG"

echo "==> What Gatekeeper will say on another Mac"
spctl --assess --type open --context context:primary-signature --verbose=2 "$DMG"
spctl --assess --type execute --verbose=2 "$APP_PATH"
echo "==> Done: $DMG"
echo "    Next: RELEASE_NOTES=\$'First line of the release notes\\nSecond line of the release notes' ./publish.sh"
