# Outfits

A local-first wardrobe app for planning outfits: photograph what you own, mix tops, bottoms, shoes and layers into an outfit, save the combinations you like, and keep a diary of what you wore. Everything lives on your device — there's no account, no backend and no network access.

[Google Play](https://play.google.com/store/apps/details?id=eu.oscillator.outfits&pcampaignid=web_share) · [App Store](https://apps.apple.com/us/app/outfits-app/id6802752111)

## Features

- **Outfit canvas** — lay out cards for the kinds of clothing you want to combine (top, trousers, shoes, a hat, a second layer…): hold a card to move it, pinch to resize it, swipe it for the next item, pin the ones you want to keep, and shuffle the rest.
- **Wardrobe** — add clothing with a camera photo or one from your gallery, sorted into kinds and types (e.g. Tops → Shirts, T-shirts), with detected colors and optional details (name, seller, size, price, note), and search across all of it.
- **Kinds and types** — fully your own: create, rename, reorder or delete them in settings, and move clothing between them (or between wardrobes) at any time.
- **Collection** — every saved outfit in one place: search them by the clothes in them, heart your favorites, and filter by favorites, worn often or not worn lately; open one for its wear stats.
- **Diary and stats** — log what you wore each day (with an optional daily reminder) and see how often each piece and color gets worn.
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
  models.dart                  # ClothingItem / kinds + types / canvas / SavedOutfit
  home_screen.dart             # Scaffold, tab switching, toast
  outfit_tab.dart              # Outfit canvas (cards, layout editing)
  outfits_tab.dart             # Saved outfits: search, favorites, filters
  diary_tab.dart               # Diary calendar and stats
  wardrobe_tab.dart            # Wardrobe, one section per kind with type folders
  type_detail_screen.dart      # One type's clothing
  settings_screen.dart         # Settings: wardrobes, kinds and types, reminder, options
  sheets.dart                  # Sheets and the item detail (add, pick, move, log)
  reminders.dart               # Daily diary reminder (local notifications)
  color_detect.dart            # Garment color detection from photos
  color_names.dart             # Named color families
  auto_name.dart               # "<color> <type>" names for unnamed items
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
