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
  String get done => 'Hotovo';

  @override
  String get close => 'Zavřít';

  @override
  String get delete => 'Smazat';

  @override
  String get create => 'Vytvořit';

  @override
  String get add => 'přidat';

  @override
  String get actionCannotBeUndone => 'Tuto akci nelze vrátit.';

  @override
  String get rename => 'Přejmenovat';

  @override
  String get unsortedName => 'Nezařazené';

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
  String get defaultTypesTop => 'Trička, Košile, Mikiny, Svetry';

  @override
  String get defaultTypesBottom => 'Kalhoty, Džíny, Sukně, Kraťasy';

  @override
  String get defaultTypesShoes => 'Tenisky, Polobotky, Sandály';

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
  String get addItemTitle => 'Přidat oblečení';

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
  String get moveTitle => 'Přesunout';

  @override
  String toastMovedToWardrobe(String name) {
    return 'Přesunuto do šatníku „$name“';
  }

  @override
  String get wearWhereTitle => 'Kam do outfitu?';

  @override
  String get wornHere => 'teď tady';

  @override
  String get searchHint => 'Hledat oblečení';

  @override
  String get nothingFound => 'Nic nenalezeno.';

  @override
  String get sectionItemName => 'název';

  @override
  String get itemNameHint => 'např. Zelená lněná košile';

  @override
  String get sectionSeller => 'prodejce';

  @override
  String get sellerHint => 'např. Zara';

  @override
  String get sectionSize => 'velikost';

  @override
  String get sizeHint => 'např. M';

  @override
  String get sectionPrice => 'cena';

  @override
  String get priceHint => 'např. 890 Kč';

  @override
  String get sectionNote => 'poznámka';

  @override
  String get noteHint => 'např. prát na 30 °C';

  @override
  String get sectionOutfitName => 'název outfitu';

  @override
  String get outfitNameHint => 'např. Pondělní porada';

  @override
  String get sectionCollection => 'kolekce';

  @override
  String toastSavedWithPhoto(String category) {
    return 'Uloženo do „$category“ · fotka v souborech apky';
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
  String get outfitAlreadySavedTitle => 'Outfit už je uložený';

  @override
  String outfitAlreadySavedMessage(String name, String wardrobe, String col) {
    return 'Tahle kombinace je už uložená jako „$name“ v $wardrobe / $col. Uložit ji i tak?';
  }

  @override
  String get saveAnyway => 'Uložit i tak';

  @override
  String toastOutfitSaved(String name, String col) {
    return '„$name“ uloženo do kolekce $col';
  }

  @override
  String defaultOutfitName(int n) {
    return 'Outfit $n';
  }

  @override
  String get aboutTagline => 'Šatník pro plánování outfitů';

  @override
  String aboutVersionLine(String version, String buildNumber) {
    return 'v$version ($buildNumber) · Václav Parma';
  }

  @override
  String get sectionWardrobes => 'šatníky';

  @override
  String get settingsTitle => 'Nastavení';

  @override
  String get sectionLanguage => 'jazyk';

  @override
  String get languageSystemOption => 'Podle systému';

  @override
  String get sectionAppearance => 'vzhled';

  @override
  String get themeLight => 'Světlý';

  @override
  String get themeDark => 'Tmavý';

  @override
  String get onboardingTitle => 'Vítej v Šatníku';

  @override
  String get onboardingSubtitle =>
      'Pár věcí na začátek — všechno půjde později změnit.';

  @override
  String get onboardingContinue => 'Pokračovat';

  @override
  String get defaultWardrobeName => 'Můj šatník';

  @override
  String get sectionWardrobeName => 'název šatníku';

  @override
  String get newWardrobe => 'Nový šatník';

  @override
  String get newWardrobeHint => 'např. Chata';

  @override
  String get renameWardrobeTitle => 'Přejmenovat šatník';

  @override
  String get deleteWardrobeTitle => 'Smazat šatník?';

  @override
  String deleteWardrobeMessage(String name) {
    return 'Šatník „$name“ bude smazán, včetně všeho oblečení, fotek, kolekcí a outfitů v něm.';
  }

  @override
  String get colorsTitle => 'Barvy';

  @override
  String get colorsEdit => 'Upravit barvy';

  @override
  String get colorsHint =>
      'Vyber barvu pod fotkou a pak klepni na místo na fotce, odkud ji má převzít.';

  @override
  String get colorsRedetect => 'Zjistit znovu automaticky';

  @override
  String get colorAdd => 'Přidat barvu';

  @override
  String get colorRemove => 'Odebrat barvu';

  @override
  String colorSlot(int n) {
    return 'Barva $n';
  }

  @override
  String get ok => 'OK';

  @override
  String get sectionKinds => 'druhy a typy';

  @override
  String get addTypeChip => 'typ';

  @override
  String get newKind => 'Vlastní druh';

  @override
  String get newKindHint => 'např. Čepice';

  @override
  String get renameKindTitle => 'Přejmenovat druh';

  @override
  String get deleteKindTitle => 'Smazat druh?';

  @override
  String deleteKindMessage(String name) {
    return 'Druh „$name“ i s jeho typy bude smazán.';
  }

  @override
  String get kindNotEmptyTitle => 'Druh není prázdný';

  @override
  String kindNotEmptyMessage(String name, String items) {
    return 'V druhu „$name“ je ještě $items (počítají se všechny šatníky). Nejdřív je přesuň do jiného druhu nebo smaž.';
  }

  @override
  String get newTypeTitle => 'Nový typ';

  @override
  String get newTypeHint => 'např. Košile';

  @override
  String get renameTypeTitle => 'Přejmenovat typ';

  @override
  String get deleteTypeTitle => 'Smazat typ?';

  @override
  String get kindsHint =>
      'Druhy jsou karty na hlavní stránce, typy třídí oblečení uvnitř druhu. Pořadí změníš přetažením za úchyt.';

  @override
  String get sectionKind => 'druh';

  @override
  String get sectionType => 'typ';

  @override
  String get sectionWardrobe => 'šatník';

  @override
  String wearOnCard(String kind, int n) {
    return '$kind $n';
  }

  @override
  String get wearNewCard => 'Nová karta';

  @override
  String get all => 'Vše';

  @override
  String get addClothes => 'Přidat';

  @override
  String get canvasEmpty =>
      'Na plátně zatím nic není.\nPřidej karty tlačítky dole — podržením je pak přesuneš, dvěma prsty změníš velikost.';

  @override
  String get otherTypeName => 'Ostatní';

  @override
  String get defaultTypesDress => 'Letní, Společenské';

  @override
  String deleteTypeMoveMessage(String name, String items) {
    return 'V typu „$name“ je $items. Kam je přesunout?';
  }

  @override
  String get dropToRemove => 'Pusť sem pro odebrání';

  @override
  String get reorder => 'Změnit pořadí';

  @override
  String get newTypeTile => 'nový typ';
}
