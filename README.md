# Outfits

A local-first wardrobe app for planning outfits: photograph what you own, mix tops, bottoms, shoes and layers into an outfit, and save the combinations you like into collections for later. Everything lives on your device — there's no account, no backend and no network access.

[Google Play](https://play.google.com/store/apps/details?id=eu.oscillator.outfits&pcampaignid=web_share) · [App Store](#) <!-- TODO: add App Store link once live -->

## Features

- **Outfit builder** — swipe through your tops, bottoms and shoes (or pick one from a grid), stack up to two extra layers (e.g. jackets), and shuffle for a random combination.
- **Wardrobe** — add clothing with a camera photo or one from your gallery, sorted into categories (tops, dresses, jackets, trousers, skirts, shoes).
- **Tags** — tag items freely, filter the wardrobe and the outfit picker by tag, and rename or delete tags across the whole wardrobe at once.
- **Collections** — save an outfit under a named collection (e.g. "Work", "Weekend") and browse, rename or delete collections and the outfits in them later.
- **Offline, on-device storage** — wardrobe data is a single JSON file and photos are plain files in the app's documents directory; nothing leaves the device.

## Tech stack

- [Flutter](https://flutter.dev) (Dart, Material 3) targeting iOS and
  Android.
- [`provider`](https://pub.dev/packages/provider) for app state
  (`WardrobeStore`, a single `ChangeNotifier`).
- [`image_picker`](https://pub.dev/packages/image_picker) for camera/gallery photos and [`path_provider`](https://pub.dev/packages/path_provider) for on-device storage — no backend, database or third-party service involved.

## Getting started

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install)
(stable channel) with iOS and/or Android tooling set up.

```bash
git clone https://github.com/vaclavparma/outfits-app.git
cd outfits-app
flutter pub get
flutter run
```

### Project structure

```
lib/
  main.dart                    # App entry point, theme + Provider setup
  wardrobe_store.dart          # All app state + local JSON persistence
  models.dart                  # ClothingItem / SavedOutfit / categories
  home_screen.dart             # Scaffold, tab switching, toast
  outfit_tab.dart              # Outfit builder (top/bottom/shoes/layers)
  wardrobe_tab.dart            # Wardrobe grid, grouped by category
  collections_tab.dart         # Collections overview
  collection_detail_screen.dart # One collection's saved outfits
  sheets.dart                  # Bottom sheets (add item, pick, tags, save)
  widgets.dart                 # Shared UI pieces (cards, chips, dialogs)
  theme.dart                   # Colors and text styles
```

### Regenerating the app icon / splash screen

The launcher icon and splash screen are generated from
`assets/icon/app_icon.png` via [`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons) and [`flutter_native_splash`](https://pub.dev/packages/flutter_native_splash).

After replacing that file, regenerate both, then the small in-app copy
(onboarding, About) and shrink the generated splash images — the generator
writes full 32-bit PNGs, while the illustration fits a 256-color palette
(~85% smaller, visually identical). Needs Python with Pillow.
```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
python3 - <<'EOF'
from PIL import Image
import glob
Image.open('assets/icon/app_icon.png').convert('RGBA').resize((192, 192), Image.LANCZOS) \
    .save('assets/icon/app_icon_small.png')
for f in glob.glob('android/app/src/main/res/drawable*/*splash.png') \
        + glob.glob('ios/Runner/Assets.xcassets/LaunchImage.imageset/*.png') \
        + ['assets/icon/app_icon_small.png']:
    Image.open(f).convert('RGBA').quantize(256, method=Image.Quantize.FASTOCTREE,
        dither=Image.Dither.NONE).save(f, optimize=True)
EOF
```

### Build and distribution
```bash
./build-and-upload.sh
```


## License

MIT — see [LICENSE](LICENSE).

Bundled fonts ([Libre Franklin](https://fonts.google.com/specimen/Libre+Franklin) and [IBM Plex Mono](https://fonts.google.com/specimen/IBM+Plex+Mono)) are licensed separately under the [SIL Open Font License 1.1](https://openfontlicense.org/).
