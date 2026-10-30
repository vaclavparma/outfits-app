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
  String get sellerHint => 'Váš oblíbený obchod';

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
    return 'Uloženo do „$category“ · fotka v souborech aplikace';
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
  String get onboardingTitle => 'Vítejte v Outfits';

  @override
  String get onboardingSubtitle =>
      'Za pár minut si nastavíte šatník po svém a poskládáte první outfit. Všechno půjde později změnit.';

  @override
  String get onboardingContinue => 'Pokračovat';

  @override
  String get defaultWardrobeName => 'Můj šatník';

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
      'Vyberte barvu pod fotkou a pak klepněte na místo na fotce, odkud ji má převzít.';

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
    return 'V druhu „$name“ je ještě $items (počítají se všechny šatníky). Nejdřív je přesuňte do jiného druhu nebo smažte.';
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
      'Druhy jsou karty na hlavní stránce, typy třídí oblečení uvnitř druhu. Pořadí změníte přetažením za úchyt.';

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
      'Na plátně zatím nic není.\nPřidejte karty tlačítky dole — podržením je pak přesunete, dvěma prsty změníte velikost.';

  @override
  String get otherTypeName => 'Ostatní';

  @override
  String get defaultTypesDress => 'Letní, Společenské';

  @override
  String deleteTypeMoveMessage(String name, String items) {
    return 'V typu „$name“ je $items. Kam je přesunout?';
  }

  @override
  String canvasFull(int count) {
    return 'Na plátně může být nejvýš $count karet. Nějakou odeberte — podržte ji a přetáhněte do koše.';
  }

  @override
  String get rateAppHint => 'Pomůžete tím ostatním aplikaci najít';

  @override
  String get rateApp => 'Ohodnotit Outfits';

  @override
  String get sectionData => 'Data';

  @override
  String get exportData => 'Exportovat data';

  @override
  String get exportDataHint =>
      'Šatníky, fotky, outfity, deník i nastavení v jednom souboru .zip';

  @override
  String get importData => 'Importovat data';

  @override
  String get importDataHint =>
      'Ze zálohy .zip — nahradí všechno, co je teď v aplikaci';

  @override
  String wardrobeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count šatníků',
      few: '$count šatníky',
      one: '$count šatník',
    );
    return '$_temp0';
  }

  @override
  String get importConfirmTitle => 'Nahradit všechna data?';

  @override
  String importConfirmMessage(String wardrobes, String items, String outfits) {
    return 'Záloha obsahuje $wardrobes, $items a $outfits. Nahradí všechno, co je teď v aplikaci — šatníky, fotky, outfity, deník i nastavení. Jestli chcete mít současný stav schovaný, nejdřív ho exportujte.';
  }

  @override
  String get importConfirm => 'Nahradit';

  @override
  String get importDone => 'Data jsou naimportovaná';

  @override
  String get importFailedTitle => 'Import se nepovedl';

  @override
  String get importNotABackup => 'Tento soubor není záloha z Outfits.';

  @override
  String get importNewerVersion =>
      'Záloha je z novější verze Outfits. Aktualizujte aplikaci a zkuste to znovu.';

  @override
  String get importFailed =>
      'Data se nepodařilo naimportovat. V aplikaci zůstalo všechno, jak bylo.';

  @override
  String get exportFailed => 'Data se nepodařilo vyexportovat.';

  @override
  String get deleteForGood => 'Opravdu smazat';

  @override
  String get showPhoto => 'Zobrazit fotku';

  @override
  String get photoAccessTitle => 'Fotku se nepodařilo získat';

  @override
  String get photoAccessDenied =>
      'Aplikace nemá přístup k fotoaparátu nebo k fotkám. Povolte ho v Nastavení telefonu.';

  @override
  String get photoAccessFailed =>
      'Fotoaparát ani galerii se nepodařilo otevřít. Zkuste to prosím znovu.';

  @override
  String get dropToRemove => 'Pusťte sem pro odebrání';

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
  String get diaryDayEmpty => 'Na tento den zatím nemáte nic zapsané.';

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
      'Statistiky se objeví, až v kalendáři zapíšete první outfit.';

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
      'název z barvy a typu · přepíšete v podrobnostech';

  @override
  String get sectionDetails => 'podrobnosti · volitelné';

  @override
  String get reminderTitle => 'Co máte dnes na sobě?';

  @override
  String get reminderBody => 'Zapište si dnešní outfit do deníku.';

  @override
  String get reminderChannel => 'Upomínka deníku';

  @override
  String get sectionDiary => 'deník';

  @override
  String get reminderLabel => 'Denní upomínka';

  @override
  String get reminderHint =>
      'Připomene vám zapsat outfit — jen když ten den ještě nemáte nic zapsané.';

  @override
  String get reminderTime => 'Čas';

  @override
  String get reminderDeniedTitle => 'Notifikace jsou vypnuté';

  @override
  String get reminderDeniedMessage =>
      'Aby upomínka mohla přijít, povolte aplikaci notifikace v Nastavení telefonu.';

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
  String get outfitSaved => 'Uloženo';

  @override
  String get outfitAlreadySavedHere =>
      'Tuto kombinaci už máte mezi outfity. Uložit i tak?';

  @override
  String outfitAlreadySavedIn(String wardrobe) {
    return 'Tuto kombinaci už máte uloženou v šatníku „$wardrobe“. Uložit i tak?';
  }

  @override
  String get deleteOutfitPlain => 'Outfit bude smazán.';

  @override
  String get outfitsEmpty =>
      'Zatím nemáte žádné uložené outfity. Poskládejte si nějaký na hlavní stránce a uložte ho.';

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
  String get editOnCanvas => 'Přenést na plátno';

  @override
  String get diaryRemoveEntryTitle => 'Odebrat z deníku?';

  @override
  String get diaryRemoveEntryMessage =>
      'Zápis tohoto outfitu u dne bude smazán.';

  @override
  String get nameTaken => 'Tento název už existuje.';

  @override
  String get onboardingStart => 'Začít';

  @override
  String get onboardingLooksTitle => 'Vzhled a jazyk';

  @override
  String get onboardingLooksBody =>
      'Jak má aplikace vypadat a jakou řečí mluvit.';

  @override
  String get onboardingWardrobeTitle => 'Váš šatník';

  @override
  String get onboardingWardrobeBody =>
      'Pojmenujte ho — třeba „Doma“. Další šatníky (chata, kancelář…) přidáte kdykoli v nastavení.';

  @override
  String get onboardingKindsTitle => 'Co nosíte';

  @override
  String get onboardingKindsBody =>
      'Vyberte druhy oblečení, se kterými chcete pracovat. Každý druh je karta na plátně, typy uvnitř (trička, košile…) upravíte v nastavení.';

  @override
  String get onboardingReminderTitle => 'Denní upomínka';

  @override
  String get onboardingReminderBody =>
      'Z deníku se počítá, co nosíte nejčastěji a co leží ve skříni. Upomínka vám připomene zapsat dnešní outfit — klidně ji nechte vypnutou.';

  @override
  String get tourAddTitle => 'Přidejte první kusy';

  @override
  String get tourAddBody =>
      'Vyfoťte nebo vyberte z galerie pár kousků — třeba tričko, kalhoty a boty. Barvy i název se doplní samy.';

  @override
  String get tourAddButton => 'Přidat oblečení';

  @override
  String get tourAddMore => 'Přidat další';

  @override
  String get tourCanvasTitle => 'Váš první outfit';

  @override
  String get tourCanvasBody =>
      'Vaše kusy jsou na plátně. Ťukněte na kartu a vyberte jiný kus, podržte ji a přesuňte, dvěma prsty změníte velikost. Pak outfit uložte.';

  @override
  String get tourOutfitsBody =>
      'Tady jsou uložené outfity. Najdete je podle oblečení, srdíčkem si označíte oblíbené a ťuknutím otevřete detail.';

  @override
  String get tourDiaryBody =>
      'Zapisujte, co máte na sobě — tlačítkem + nebo ťuknutím na den. Ze zápisů vznikají statistiky: co nosíte nejvíc a co ne.';

  @override
  String get tourNext => 'Dál';

  @override
  String get tourSkip => 'Přeskočit';

  @override
  String get tourClose => 'Ukončit prohlídku';
}
