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
  String get deleteOutfitTitle => 'Smazat outfit?';

  @override
  String get addItemTitle => 'Přidat oblečení';

  @override
  String get takePhoto => 'Vyfotit';

  @override
  String get fromGallery => 'Z galerie';

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
  String get searchHint => 'Hledat oblečení';

  @override
  String get nothingFound => 'Nic nenalezeno.';

  @override
  String get sectionItemName => 'název';

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
  String get saveAnyway => 'Uložit i tak';

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

  @override
  String get tabDiary => 'Deník';

  @override
  String get diaryCalendar => 'Kalendář';

  @override
  String get diaryStats => 'Statistiky';

  @override
  String diaryDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dní',
      few: '$count dny',
      one: '$count den',
    );
    return '$_temp0';
  }

  @override
  String get diaryToday => 'Dnes';

  @override
  String get diaryYesterday => 'Včera';

  @override
  String get diaryDayEmpty => 'Na tenhle den zatím nemáš nic zapsané.';

  @override
  String get diaryFromCanvas => 'Z plátna';

  @override
  String get diaryFromSaved => 'Z uložených';

  @override
  String get diaryCanvasEmpty => 'Na plátně zatím není žádné oblečení.';

  @override
  String get diaryPickSavedTitle => 'Uložené outfity';

  @override
  String get diaryRemoveEntry => 'Odebrat z deníku';

  @override
  String statsDaysLogged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'dní zapsáno tento měsíc',
      few: 'dny zapsány tento měsíc',
      one: 'den zapsán tento měsíc',
    );
    return '$_temp0';
  }

  @override
  String get statsItemsWorn => 'kusů nošeno tento měsíc';

  @override
  String get statsTimesWorn => 'Počet nošení';

  @override
  String get statsAllTime => 'celkem';

  @override
  String statsShowAll(int count) {
    return 'zobrazit všech $count';
  }

  @override
  String get statsShowLess => 'zobrazit méně';

  @override
  String get statsNotWorn => 'Dlouho nenošené';

  @override
  String get statsNever => 'nikdy';

  @override
  String statsDaysAgo(int n) {
    return 'před $n dny';
  }

  @override
  String statsNothingUnworn(int n) {
    return 'Všechno oblečení bylo za posledních $n dní aspoň jednou na řadě.';
  }

  @override
  String get statsEmpty =>
      'Statistiky se objeví, až v kalendáři zapíšeš první outfit.';

  @override
  String timesWorn(int n) {
    return '$n×';
  }

  @override
  String colorFamily(String color) {
    String _temp0 = intl.Intl.selectLogic(color, {
      'white': 'Bílá',
      'beige': 'Béžová',
      'yellow': 'Žlutá',
      'orange': 'Oranžová',
      'red': 'Červená',
      'pink': 'Růžová',
      'purple': 'Fialová',
      'blue': 'Modrá',
      'green': 'Zelená',
      'brown': 'Hnědá',
      'grey': 'Šedá',
      'black': 'Černá',
      'other': 'Jiná',
    });
    return '$_temp0';
  }

  @override
  String get statsColors => 'Barvy';

  @override
  String get statsInWardrobe => 'v šatníku';

  @override
  String get statsWornLabel => 'na sobě';

  @override
  String get statsColWardrobe => 'šatník';

  @override
  String get statsNotWornSince => '30+ dní';

  @override
  String get diaryLogOutfit => 'Zapsat outfit';

  @override
  String get sectionDay => 'den';

  @override
  String get diaryOtherDay => 'Jiný den…';

  @override
  String toastLogged(String date) {
    return 'Zapsáno do deníku · $date';
  }

  @override
  String get itemWornLabel => 'nošeno';

  @override
  String get itemLastWornLabel => 'naposledy';

  @override
  String get itemPerWearLabel => 'za nošení';

  @override
  String get itemLastToday => 'dnes';

  @override
  String get itemLastYesterday => 'včera';

  @override
  String get itemAutoNameHint =>
      'název z barvy a typu · přepíšeš v podrobnostech';

  @override
  String get sectionDetails => 'podrobnosti · volitelné';

  @override
  String get reminderTitle => 'Co máš dnes na sobě?';

  @override
  String get reminderBody => 'Zapiš si dnešní outfit do deníku.';

  @override
  String get reminderChannel => 'Upomínka deníku';

  @override
  String get sectionDiary => 'deník';

  @override
  String get reminderLabel => 'Denní upomínka';

  @override
  String get reminderHint =>
      'Připomene ti zapsat outfit — jen když ten den ještě nemáš nic zapsané.';

  @override
  String get reminderTime => 'Čas';

  @override
  String get reminderDeniedTitle => 'Notifikace jsou vypnuté';

  @override
  String get reminderDeniedMessage =>
      'Aby upomínka mohla přijít, povol aplikaci notifikace v Nastavení telefonu.';

  @override
  String get tabOutfits => 'Sbírka';

  @override
  String get searchOutfitsHint => 'Hledat podle oblečení';

  @override
  String get filterFavorites => 'Oblíbené';

  @override
  String get filterOftenWorn => 'Často nošené';

  @override
  String get favorite => 'Oblíbený';

  @override
  String get toastOutfitSavedPlain => 'Outfit uložen';

  @override
  String get outfitAlreadySavedHere =>
      'Tuhle kombinaci už máš mezi outfity. Uložit i tak?';

  @override
  String outfitAlreadySavedIn(String wardrobe) {
    return 'Tuhle kombinaci už máš uloženou v šatníku „$wardrobe“. Uložit i tak?';
  }

  @override
  String get deleteOutfitPlain => 'Outfit bude smazán.';

  @override
  String get outfitsEmpty =>
      'Zatím nemáš žádné uložené outfity. Poskládej si nějaký na hlavní stránce a ulož ho.';

  @override
  String outfitUsualWeekday(String weekday) {
    String _temp0 = intl.Intl.selectLogic(weekday, {
      '1': 'nejčastěji v pondělí',
      '2': 'nejčastěji v úterý',
      '3': 'nejčastěji ve středu',
      '4': 'nejčastěji ve čtvrtek',
      '5': 'nejčastěji v pátek',
      '6': 'nejčastěji v sobotu',
      '7': 'nejčastěji v neděli',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get wearToday => 'Nosím dnes';

  @override
  String get outfitWornToday => 'Dnes zapsáno';

  @override
  String get editOnCanvas => 'Upravit na plátně';

  @override
  String get diaryRemoveEntryTitle => 'Odebrat z deníku?';

  @override
  String get diaryRemoveEntryMessage =>
      'Zápis tohoto outfitu u dne bude smazán.';

  @override
  String get nameTaken => 'Tenhle název už existuje.';
}
