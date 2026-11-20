#!/bin/bash
set -e

PUBSPEC="pubspec.yaml"
PLIST_PATH="ios/ExportOptions.plist"

# What's running and what's done, for the summary at the end — which stays
# readable after pages of build logs, whether it all worked or not.
STEP="Starting"
PLAY_DONE=""
APP_STORE_DONE=""
BOLD=$(tput bold 2>/dev/null || true)
RESET=$(tput sgr0 2>/dev/null || true)

summary() {
  local status=$?
  local took="$((SECONDS / 60))m $((SECONDS % 60))s"
  echo
  echo "════════════════════════════════════════════════════"
  if [ $status -eq 0 ]; then
    echo "${BOLD}✅ Outfits ${VERSION_NAME}+${NEW_BUILD} uploaded to both stores${RESET}"
  else
    echo "${BOLD}❌ Failed: ${STEP}${RESET}"
  fi
  echo "   Google Play       ${PLAY_DONE:-—}"
  echo "   App Store Connect ${APP_STORE_DONE:-—}"
  if [ $status -ne 0 ] && [ -n "$NEW_BUILD" ]; then
    echo "   Build number was already bumped and committed (${NEW_BUILD})."
  fi
  if [ -n "$SYMBOLS_DIR" ] && [ -d "$SYMBOLS_DIR" ]; then
    echo "   Debug symbols     $SYMBOLS_DIR"
  fi
  echo "   Took              $took"
  echo "════════════════════════════════════════════════════"
}
trap summary EXIT

# 1. Check for pubspec.yaml existence
if [ ! -f "$PUBSPEC" ]; then
  echo "❌ Error: $PUBSPEC not found!"
  exit 1
fi

# 2. Increment build number in pubspec.yaml
CURRENT_VERSION_LINE=$(grep '^version: ' "$PUBSPEC")
VERSION_NAME=$(echo "$CURRENT_VERSION_LINE" | sed -E 's/version: ([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)/\1/')
CURRENT_BUILD=$(echo "$CURRENT_VERSION_LINE" | sed -E 's/version: ([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)/\2/')

if [ -z "$CURRENT_BUILD" ] || [ -z "$VERSION_NAME" ]; then
  echo "❌ Error: Failed to parse version from $PUBSPEC (expected format: X.Y.Z+N)"
  exit 1
fi

NEW_BUILD=$((CURRENT_BUILD + 1))
NEW_VERSION_LINE="version: ${VERSION_NAME}+${NEW_BUILD}"

sed -i '' "s/^version: .*/$NEW_VERSION_LINE/" "$PUBSPEC"
echo "⬆️  Build number bumped: ${VERSION_NAME}+${CURRENT_BUILD} -> ${VERSION_NAME}+${NEW_BUILD}"

# 3. Git commit
STEP="Committing the build number"
git add "$PUBSPEC"
git commit -m "chore(release): bump build number to ${NEW_BUILD}"
echo "📝 Git commit created."

# 4. Clean & Build
STEP="Cleaning and fetching dependencies"
echo "🧹 Cleaning project..."
flutter clean

echo "📦 Fetching dependencies..."
flutter pub get

# Smaller app: Dart debug info goes to a side folder and symbol names are
# shortened. Keep that folder — `flutter symbolize -i <stack trace>
# -d debug-info/<version>` needs it to make crash reports readable.
SYMBOLS_DIR="debug-info/${VERSION_NAME}+${NEW_BUILD}"
SIZE_FLAGS=(--obfuscate --split-debug-info="$SYMBOLS_DIR")

STEP="Building the IPA"
echo "🏗️  Building IPA archive (${VERSION_NAME}+${NEW_BUILD})..."
flutter build ipa --release "${SIZE_FLAGS[@]}"

STEP="Building the App Bundle"
echo "🏗️  Building App Bundle (${VERSION_NAME}+${NEW_BUILD})..."
flutter build appbundle --release "${SIZE_FLAGS[@]}"

# 5. Upload to Google Play Store
STEP="Uploading to Google Play"
echo "🚀 Uploading to Google Play Store..."
(cd android && ./gradlew publishReleaseBundle)
PLAY_DONE="✓ uploaded — https://play.google.com/console"
echo "✅ Success! Build ${VERSION_NAME}+${NEW_BUILD} uploaded to Google Play Store."

# 6. Check for ExportOptions.plist existence
STEP="Checking $PLIST_PATH"
if [ ! -f "$PLIST_PATH" ]; then
  echo "❌ Error: $PLIST_PATH not found!"
  exit 1
fi

# 7. Upload to App Store Connect
STEP="Uploading to App Store Connect"
echo "🚀 Uploading to App Store Connect..."
xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportOptionsPlist "$PLIST_PATH" \
  -exportPath build/ios/ipa \
  -allowProvisioningUpdates

APP_STORE_DONE="✓ uploaded — https://appstoreconnect.apple.com"
echo "✅ Success! Build ${VERSION_NAME}+${NEW_BUILD} uploaded to App Store Connect."
