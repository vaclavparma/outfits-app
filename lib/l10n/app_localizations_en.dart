// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tabOutfit => 'Outfit';

  @override
  String get tabWardrobe => 'Wardrobe';

  @override
  String get tabCollections => 'Collections';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get done => 'Done';

  @override
  String get close => 'Close';

  @override
  String get delete => 'Delete';

  @override
  String get create => 'Create';

  @override
  String get add => 'add';

  @override
  String get actionCannotBeUndone => 'This action can\'t be undone.';

  @override
  String get rename => 'Rename';

  @override
  String get unsortedName => 'Unsorted';

  @override
  String get shuffleButton => 'Shuffle';

  @override
  String get saveOutfitButton => 'Save outfit';

  @override
  String get categoryHorni => 'Top';

  @override
  String get categorySaty => 'Dresses';

  @override
  String get categoryDolni => 'Bottom';

  @override
  String get categoryBoty => 'Shoes';

  @override
  String get defaultTypesTop => 'T-shirts, Shirts, Hoodies, Sweaters';

  @override
  String get defaultTypesBottom => 'Trousers, Jeans, Skirts, Shorts';

  @override
  String get defaultTypesShoes => 'Sneakers, Dress shoes, Sandals';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '$count item',
    );
    return '$_temp0';
  }

  @override
  String get newCollectionTile => 'new collection';

  @override
  String get newCollectionDialogTitle => 'New collection';

  @override
  String get newCollectionHint => 'e.g. Work';

  @override
  String outfitCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count outfits',
      one: '$count outfit',
    );
    return '$_temp0';
  }

  @override
  String get collectionEmptyHint =>
      'Nothing here yet. Save an outfit and pick this collection.';

  @override
  String get renameCollectionTitle => 'Rename collection';

  @override
  String get deleteCollectionTitle => 'Delete collection?';

  @override
  String deleteCollectionMessage(String name) {
    return 'The collection “$name” and everything in it will be deleted.';
  }

  @override
  String get deleteOutfitTitle => 'Delete outfit?';

  @override
  String deleteOutfitMessage(String name) {
    return '“$name” will be deleted.';
  }

  @override
  String get addItemTitle => 'Add clothing';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get fromGallery => 'From gallery';

  @override
  String get itemDetailTitle => 'Clothing detail';

  @override
  String get useInOutfit => 'Use in outfit';

  @override
  String get deleteItemTitle => 'Delete this item?';

  @override
  String get deleteItemMessage => 'This item will be deleted.';

  @override
  String get moveTitle => 'Move';

  @override
  String toastMovedToWardrobe(String name) {
    return 'Moved to the “$name” wardrobe';
  }

  @override
  String get wearWhereTitle => 'Where in the outfit?';

  @override
  String get wornHere => 'here now';

  @override
  String get searchHint => 'Search clothes';

  @override
  String get nothingFound => 'Nothing found.';

  @override
  String get sectionItemName => 'name';

  @override
  String get itemNameHint => 'e.g. Green linen shirt';

  @override
  String get sectionSeller => 'seller';

  @override
  String get sellerHint => 'e.g. Zara';

  @override
  String get sectionSize => 'size';

  @override
  String get sizeHint => 'e.g. M';

  @override
  String get sectionPrice => 'price';

  @override
  String get priceHint => 'e.g. \$35';

  @override
  String get sectionNote => 'note';

  @override
  String get noteHint => 'e.g. wash at 30 °C';

  @override
  String get sectionOutfitName => 'outfit name';

  @override
  String get outfitNameHint => 'e.g. Monday meeting';

  @override
  String get sectionCollection => 'collection';

  @override
  String toastSavedWithPhoto(String category) {
    return 'Saved to “$category” · photo stored in app files';
  }

  @override
  String toastSavedPhotoFailed(String category) {
    return 'Saved to “$category” · couldn\'t save the photo';
  }

  @override
  String toastSavedMultiple(int count, String category) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Saved $count items to “$category”',
      one: 'Saved $count item to “$category”',
    );
    return '$_temp0';
  }

  @override
  String get outfitAlreadySavedTitle => 'Outfit already saved';

  @override
  String outfitAlreadySavedMessage(String name, String wardrobe, String col) {
    return 'This combination is already saved as “$name” in $wardrobe / $col. Save it anyway?';
  }

  @override
  String get saveAnyway => 'Save anyway';

  @override
  String toastOutfitSaved(String name, String col) {
    return '“$name” saved to the $col collection';
  }

  @override
  String defaultOutfitName(int n) {
    return 'Outfit $n';
  }

  @override
  String get aboutTagline => 'A wardrobe for planning outfits';

  @override
  String aboutVersionLine(String version, String buildNumber) {
    return 'v$version ($buildNumber) · Václav Parma';
  }

  @override
  String get sectionWardrobes => 'wardrobes';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionLanguage => 'language';

  @override
  String get languageSystemOption => 'System default';

  @override
  String get sectionAppearance => 'appearance';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get onboardingTitle => 'Welcome to Outfits';

  @override
  String get onboardingSubtitle =>
      'A few things to start — you can change all of them later.';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get defaultWardrobeName => 'My wardrobe';

  @override
  String get sectionWardrobeName => 'wardrobe name';

  @override
  String get newWardrobe => 'New wardrobe';

  @override
  String get newWardrobeHint => 'e.g. Cottage';

  @override
  String get renameWardrobeTitle => 'Rename wardrobe';

  @override
  String get deleteWardrobeTitle => 'Delete wardrobe?';

  @override
  String deleteWardrobeMessage(String name) {
    return 'The wardrobe “$name” will be deleted, along with all its clothes, photos, collections and outfits.';
  }

  @override
  String get colorsTitle => 'Colors';

  @override
  String get colorsEdit => 'Edit colors';

  @override
  String get colorsHint =>
      'Choose a color below the photo, then tap the spot on the photo to take it from.';

  @override
  String get colorsRedetect => 'Detect again automatically';

  @override
  String get colorAdd => 'Add color';

  @override
  String get colorRemove => 'Remove color';

  @override
  String colorSlot(int n) {
    return 'Color $n';
  }

  @override
  String get ok => 'OK';

  @override
  String get sectionKinds => 'kinds and types';

  @override
  String get addTypeChip => 'type';

  @override
  String get newKind => 'Custom kind';

  @override
  String get newKindHint => 'e.g. Hats';

  @override
  String get renameKindTitle => 'Rename kind';

  @override
  String get deleteKindTitle => 'Delete kind?';

  @override
  String deleteKindMessage(String name) {
    return 'The kind “$name” and its types will be deleted.';
  }

  @override
  String get kindNotEmptyTitle => 'Kind isn’t empty';

  @override
  String kindNotEmptyMessage(String name, String items) {
    return '“$name” still has $items (counting every wardrobe). Move them to another kind or delete them first.';
  }

  @override
  String get newTypeTitle => 'New type';

  @override
  String get newTypeHint => 'e.g. Shirts';

  @override
  String get renameTypeTitle => 'Rename type';

  @override
  String get deleteTypeTitle => 'Delete type?';

  @override
  String get kindsHint =>
      'Kinds are the cards on the main page; types sort clothes within a kind. Drag the handle to reorder.';

  @override
  String get sectionKind => 'kind';

  @override
  String get sectionType => 'type';

  @override
  String get sectionWardrobe => 'wardrobe';

  @override
  String wearOnCard(String kind, int n) {
    return '$kind $n';
  }

  @override
  String get wearNewCard => 'New card';

  @override
  String get all => 'All';

  @override
  String get addClothes => 'Add';

  @override
  String get canvasEmpty =>
      'Nothing on the canvas yet.\nAdd cards with the buttons below — hold one to move it, pinch to resize it.';

  @override
  String get otherTypeName => 'Other';

  @override
  String get defaultTypesDress => 'Summer, Formal';

  @override
  String deleteTypeMoveMessage(String name, String items) {
    return '“$name” has $items. Where should they go?';
  }

  @override
  String get dropToRemove => 'Drop here to remove';

  @override
  String get reorder => 'Reorder';

  @override
  String get newTypeTile => 'new type';
}
