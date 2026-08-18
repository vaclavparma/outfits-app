// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get tabOutfit => 'Outfit';

  @override
  String get tabWardrobe => 'Šatník';

  @override
  String get tabCollections => 'Kolekce';

  @override
  String get cancel => 'Zrušit';

  @override
  String get save => 'Uložit';

  @override
  String get delete => 'Smazat';

  @override
  String get create => 'Vytvořit';

  @override
  String get add => 'přidat';

  @override
  String get actionCannotBeUndone => 'Tuto akci nelze vrátit.';

  @override
  String get noFolder => 'bez složky';

  @override
  String get rename => 'Přejmenovat';

  @override
  String get addTopPlaceholder => 'Přidej top';

  @override
  String get addBottomPlaceholder => 'Přidej spodek';

  @override
  String get addShoesPlaceholder => 'Přidej boty';

  @override
  String get shuffleButton => 'Zamíchat';

  @override
  String get saveOutfitButton => 'Uložit outfit';

  @override
  String get categoryHorni => 'Horní díl';

  @override
  String get categorySaty => 'Šaty';

  @override
  String get categoryDolni => 'Dolní díl';

  @override
  String get categoryBoty => 'Boty';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kusů',
      few: '$count kusy',
      one: '$count kus',
    );
    return '$_temp0';
  }

  @override
  String get newCollectionTile => 'nová kolekce';

  @override
  String get newCollectionDialogTitle => 'Nová kolekce';

  @override
  String get newCollectionHint => 'např. Práce';

  @override
  String outfitCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count outfitů',
      few: '$count outfity',
      one: '$count outfit',
    );
    return '$_temp0';
  }

  @override
  String get collectionEmptyHint =>
      'Zatím prázdné. Ulož outfit a vyber tuto kolekci.';

  @override
  String get renameCollectionTitle => 'Přejmenovat kolekci';

  @override
  String get deleteCollectionTitle => 'Smazat kolekci?';

  @override
  String deleteCollectionMessage(String name) {
    return 'Kolekce „$name“ a vše v ní bude smazáno.';
  }

  @override
  String get deleteOutfitTitle => 'Smazat outfit?';

  @override
  String deleteOutfitMessage(String name) {
    return '„$name“ bude smazán.';
  }

  @override
  String get pickTopTitle => 'Vyber top nebo šaty';

  @override
  String get pickBottomTitle => 'Vyber spodek';

  @override
  String get pickShoesTitle => 'Vyber boty';

  @override
  String get addLayerTitle => 'Přidat vrstvu';

  @override
  String get changeLayerTitle => 'Vyměnit vrstvu';

  @override
  String layerLimitMessage(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'Můžeš mít nejvýš $max vrstev navíc.',
      few: 'Můžeš mít nejvýš $max vrstvy navíc.',
      one: 'Můžeš mít nejvýš $max vrstvu navíc.',
    );
    return '$_temp0';
  }

  @override
  String get noMoreLayers => 'Žádné další vrstvy k přidání.';

  @override
  String get addItemTitle => 'Přidat oblečení';

  @override
  String get sectionCategory => 'kategorie';

  @override
  String get sectionFolder => 'složka';

  @override
  String get needFolderHint => 'Nejdřív vytvoř složku v šatníku.';

  @override
  String get takePhoto => 'Vyfotit';

  @override
  String get fromGallery => 'Z galerie';

  @override
  String get itemDetailTitle => 'Detail oblečení';

  @override
  String get useInOutfit => 'Použít v outfitu';

  @override
  String get deleteItemTitle => 'Smazat oblečení?';

  @override
  String get deleteItemMessage => 'Oblečení bude smazáno.';

  @override
  String get sectionOutfitName => 'název outfitu';

  @override
  String get outfitNameHint => 'např. Pondělní porada';

  @override
  String get sectionCollection => 'kolekce';

  @override
  String get needCollectionHint => 'Nejdřív vytvoř kolekci v záložce Kolekce.';

  @override
  String get newFolderTile => 'nová složka';

  @override
  String get newFolderDialogTitle => 'Nová složka';

  @override
  String get newFolderHint => 'např. Košile';

  @override
  String get renameFolderTitle => 'Přejmenovat složku';

  @override
  String get deleteFolderTitle => 'Smazat složku?';

  @override
  String deleteFolderMessage(String folder) {
    return 'Složka „$folder“ bude smazána. Oblečení v ní se přesune do složky „Nezařazené“.';
  }

  @override
  String toastSavedWithPhoto(String category) {
    return 'Uloženo do „$category“ · fotka v souborech apky';
  }

  @override
  String toastSavedNoPhoto(String category) {
    return 'Uloženo do „$category“';
  }

  @override
  String toastSavedPhotoFailed(String category) {
    return 'Uloženo do „$category“ · fotku se nepodařilo uložit';
  }

  @override
  String toastSavedMultiple(int count, String category) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Uloženo $count kusů do „$category“',
      few: 'Uloženo $count kusy do „$category“',
      one: 'Uloženo $count kus do „$category“',
    );
    return '$_temp0';
  }

  @override
  String toastOutfitSaved(String name, String col) {
    return '„$name“ uloženo do kolekce $col';
  }

  @override
  String get toastNeedCollectionFirst => 'Nejdřív přidej kolekci';

  @override
  String defaultOutfitName(int n) {
    return 'Outfit $n';
  }

  @override
  String get aboutTagline => 'Šatník pro plánování outfitů';

  @override
  String get aboutGithub => 'Zdrojový kód na GitHubu';

  @override
  String get aboutSupport => 'Podpoř vývoj — Buy Me a Coffee';

  @override
  String aboutVersionLine(String version, String buildNumber) {
    return 'v$version ($buildNumber) · Václav Parma';
  }

  @override
  String get settingsTitle => 'Nastavení';

  @override
  String get sectionLanguage => 'jazyk';

  @override
  String get languageSystemOption => 'Podle systému';

  @override
  String get showDressesLabel => 'Zobrazovat šaty v šatníku';

  @override
  String get showDressesHint =>
      'Skryje kategorii šatů v šatníku a při přidávání oblečení. Šaty, které už máš v šatníku, zůstanou beze změny.';

  @override
  String get onboardingTitle => 'Vítej v Šatníku';

  @override
  String get onboardingSubtitle =>
      'Pár věcí na začátek — obojí pak najdeš i v nastavení.';

  @override
  String get onboardingContinue => 'Pokračovat';
}
