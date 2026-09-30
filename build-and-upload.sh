#!/bin/bash
set -e

PUBSPEC="pubspec.yaml"
PLIST_PATH="ios/ExportOptions.plist"

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
echo "⬆️  Version bumped: ${VERSION_NAME}+${CURRENT_BUILD} -> ${VERSION_NAME}+${NEW_BUILD}"

# 3. Git commit
git add "$PUBSPEC"
git commit -m "chore(release): bump build number to ${NEW_BUILD}"
echo "📝 Git commit created."

# 4. Clean & Build
echo "🧹 Cleaning project..."
flutter clean

echo "📦 Fetching dependencies..."
flutter pub get

echo "🏗️  Building IPA archive (${VERSION_NAME}+${NEW_BUILD})..."
flutter build ipa --release

echo "🏗️  Building App Bundle (${VERSION_NAME}+${NEW_BUILD})..."
flutter build appbundle --release

# 5. Upload to Google Play Store
echo "🚀 Uploading to Google Play Store..."
(cd android && ./gradlew publishReleaseBundle)

# 6. Check for ExportOptions.plist existence
if [ ! -f "$PLIST_PATH" ]; then
  echo "❌ Error: $PLIST_PATH not found!"
  exit 1
fi

# 7. Upload to App Store Connect
echo "🚀 Uploading to App Store Connect..."
xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportOptionsPlist "$PLIST_PATH" \
  -exportPath build/ios/ipa \
  -allowProvisioningUpdates

echo "✅ Success! Build ${VERSION_NAME}+${NEW_BUILD} uploaded to App Store Connect."
