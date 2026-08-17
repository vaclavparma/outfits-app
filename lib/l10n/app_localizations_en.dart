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
  String get delete => 'Delete';

  @override
  String get create => 'Create';

  @override
  String get add => 'add';

  @override
  String get actionCannotBeUndone => 'This action can\'t be undone.';

  @override
  String get noTags => 'no tags';

  @override
  String get rename => 'Rename';

  @override
  String get addTopPlaceholder => 'Add a top';

  @override
  String get addBottomPlaceholder => 'Add a bottom';

  @override
  String get addShoesPlaceholder => 'Add shoes';

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
  String get pickTopTitle => 'Choose a top or dress';

  @override
  String get pickBottomTitle => 'Choose a bottom';

  @override
  String get pickShoesTitle => 'Choose shoes';

  @override
  String get addLayerTitle => 'Add a layer';

  @override
  String get changeLayerTitle => 'Change layer';

  @override
  String layerLimitMessage(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'You can have at most $max extra layers.',
      one: 'You can have at most $max extra layer.',
    );
    return '$_temp0';
  }

  @override
  String get noMoreLayers => 'No more layers to add.';

  @override
  String get addItemTitle => 'Add clothing';

  @override
  String get sectionCategory => 'category';

  @override
  String get sectionTagsOptional => 'tags (optional)';

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
  String get sectionOutfitName => 'outfit name';

  @override
  String get outfitNameHint => 'e.g. Monday meeting';

  @override
  String get sectionCollection => 'collection';

  @override
  String get needCollectionHint =>
      'Create a collection in the Collections tab first.';

  @override
  String get manageTagsTitle => 'Manage tags';

  @override
  String get newTagHint => 'new tag';

  @override
  String get noTagsYet => 'No tags yet.';

  @override
  String get renameTagTitle => 'Rename tag';

  @override
  String get deleteTagTitle => 'Delete tag?';

  @override
  String deleteTagMessage(String tag) {
    return 'The tag “$tag” will be deleted and removed from every item.';
  }

  @override
  String toastSavedWithPhoto(String category) {
    return 'Saved to “$category” · photo stored in app files';
  }

  @override
  String toastSavedNoPhoto(String category) {
    return 'Saved to “$category”';
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
  String toastOutfitSaved(String name, String col) {
    return '“$name” saved to the $col collection';
  }

  @override
  String get toastNeedCollectionFirst => 'Add a collection first';

  @override
  String defaultOutfitName(int n) {
    return 'Outfit $n';
  }

  @override
  String get aboutTagline => 'A wardrobe for planning outfits';

  @override
  String get aboutGithub => 'Source code on GitHub';

  @override
  String get aboutSupport => 'Support development — Buy Me a Coffee';

  @override
  String aboutVersionLine(String version, String buildNumber) {
    return 'v$version ($buildNumber) · Václav Parma';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionLanguage => 'language';

  @override
  String get languageSystemOption => 'System default';

  @override
  String get showDressesLabel => 'Show dresses in wardrobe';

  @override
  String get showDressesHint =>
      'Hides the dresses category in the wardrobe and when adding clothes. Dresses already in your wardrobe stay put.';
}
