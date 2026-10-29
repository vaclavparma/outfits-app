import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_cs.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('cs'),
    Locale('en'),
  ];

  /// No description provided for @tabOutfit.
  ///
  /// In cs, this message translates to:
  /// **'Outfit'**
  String get tabOutfit;

  /// No description provided for @tabWardrobe.
  ///
  /// In cs, this message translates to:
  /// **'Šatník'**
  String get tabWardrobe;

  /// No description provided for @cancel.
  ///
  /// In cs, this message translates to:
  /// **'Zrušit'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In cs, this message translates to:
  /// **'Uložit'**
  String get save;

  /// No description provided for @done.
  ///
  /// In cs, this message translates to:
  /// **'Hotovo'**
  String get done;

  /// No description provided for @close.
  ///
  /// In cs, this message translates to:
  /// **'Zavřít'**
  String get close;

  /// No description provided for @delete.
  ///
  /// In cs, this message translates to:
  /// **'Smazat'**
  String get delete;

  /// No description provided for @create.
  ///
  /// In cs, this message translates to:
  /// **'Vytvořit'**
  String get create;

  /// No description provided for @add.
  ///
  /// In cs, this message translates to:
  /// **'přidat'**
  String get add;

  /// No description provided for @actionCannotBeUndone.
  ///
  /// In cs, this message translates to:
  /// **'Tuto akci nelze vrátit.'**
  String get actionCannotBeUndone;

  /// No description provided for @rename.
  ///
  /// In cs, this message translates to:
  /// **'Přejmenovat'**
  String get rename;

  /// No description provided for @unsortedName.
  ///
  /// In cs, this message translates to:
  /// **'Nezařazené'**
  String get unsortedName;

  /// No description provided for @shuffleButton.
  ///
  /// In cs, this message translates to:
  /// **'Zamíchat'**
  String get shuffleButton;

  /// No description provided for @saveOutfitButton.
  ///
  /// In cs, this message translates to:
  /// **'Uložit outfit'**
  String get saveOutfitButton;

  /// No description provided for @categoryHorni.
  ///
  /// In cs, this message translates to:
  /// **'Horní díl'**
  String get categoryHorni;

  /// No description provided for @categorySaty.
  ///
  /// In cs, this message translates to:
  /// **'Šaty'**
  String get categorySaty;

  /// No description provided for @categoryDolni.
  ///
  /// In cs, this message translates to:
  /// **'Dolní díl'**
  String get categoryDolni;

  /// No description provided for @categoryBoty.
  ///
  /// In cs, this message translates to:
  /// **'Boty'**
  String get categoryBoty;

  /// Comma-separated types a fresh install starts with under tops.
  ///
  /// In cs, this message translates to:
  /// **'Trička, Košile, Mikiny, Svetry'**
  String get defaultTypesTop;

  /// No description provided for @defaultTypesBottom.
  ///
  /// In cs, this message translates to:
  /// **'Kalhoty, Džíny, Sukně, Kraťasy'**
  String get defaultTypesBottom;

  /// No description provided for @defaultTypesShoes.
  ///
  /// In cs, this message translates to:
  /// **'Tenisky, Polobotky, Sandály'**
  String get defaultTypesShoes;

  /// No description provided for @itemCount.
  ///
  /// In cs, this message translates to:
  /// **'{count, plural, one{{count} kus} few{{count} kusy} other{{count} kusů}}'**
  String itemCount(int count);

  /// No description provided for @outfitCount.
  ///
  /// In cs, this message translates to:
  /// **'{count, plural, one{{count} outfit} few{{count} outfity} other{{count} outfitů}}'**
  String outfitCount(int count);

  /// No description provided for @deleteOutfitTitle.
  ///
  /// In cs, this message translates to:
  /// **'Smazat outfit?'**
  String get deleteOutfitTitle;

  /// No description provided for @addItemTitle.
  ///
  /// In cs, this message translates to:
  /// **'Přidat oblečení'**
  String get addItemTitle;

  /// No description provided for @takePhoto.
  ///
  /// In cs, this message translates to:
  /// **'Vyfotit'**
  String get takePhoto;

  /// No description provided for @fromGallery.
  ///
  /// In cs, this message translates to:
  /// **'Z galerie'**
  String get fromGallery;

  /// No description provided for @deleteItemTitle.
  ///
  /// In cs, this message translates to:
  /// **'Smazat oblečení?'**
  String get deleteItemTitle;

  /// No description provided for @deleteItemMessage.
  ///
  /// In cs, this message translates to:
  /// **'Oblečení bude smazáno.'**
  String get deleteItemMessage;

  /// No description provided for @moveTitle.
  ///
  /// In cs, this message translates to:
  /// **'Přesunout'**
  String get moveTitle;

  /// No description provided for @toastMovedToWardrobe.
  ///
  /// In cs, this message translates to:
  /// **'Přesunuto do šatníku „{name}“'**
  String toastMovedToWardrobe(String name);

  /// No description provided for @searchHint.
  ///
  /// In cs, this message translates to:
  /// **'Hledat oblečení'**
  String get searchHint;

  /// No description provided for @nothingFound.
  ///
  /// In cs, this message translates to:
  /// **'Nic nenalezeno.'**
  String get nothingFound;

  /// No description provided for @sectionItemName.
  ///
  /// In cs, this message translates to:
  /// **'název'**
  String get sectionItemName;

  /// No description provided for @sectionSeller.
  ///
  /// In cs, this message translates to:
  /// **'prodejce'**
  String get sectionSeller;

  /// No description provided for @sellerHint.
  ///
  /// In cs, this message translates to:
  /// **'Tvůj oblíbený obchod'**
  String get sellerHint;

  /// No description provided for @sectionSize.
  ///
  /// In cs, this message translates to:
  /// **'velikost'**
  String get sectionSize;

  /// No description provided for @sizeHint.
  ///
  /// In cs, this message translates to:
  /// **'např. M'**
  String get sizeHint;

  /// No description provided for @sectionPrice.
  ///
  /// In cs, this message translates to:
  /// **'cena'**
  String get sectionPrice;

  /// No description provided for @priceHint.
  ///
  /// In cs, this message translates to:
  /// **'např. 890 Kč'**
  String get priceHint;

  /// No description provided for @sectionNote.
  ///
  /// In cs, this message translates to:
  /// **'poznámka'**
  String get sectionNote;

  /// No description provided for @noteHint.
  ///
  /// In cs, this message translates to:
  /// **'např. prát na 30 °C'**
  String get noteHint;

  /// No description provided for @toastSavedWithPhoto.
  ///
  /// In cs, this message translates to:
  /// **'Uloženo do „{category}“ · fotka v souborech apky'**
  String toastSavedWithPhoto(String category);

  /// No description provided for @toastSavedPhotoFailed.
  ///
  /// In cs, this message translates to:
  /// **'Uloženo do „{category}“ · fotku se nepodařilo uložit'**
  String toastSavedPhotoFailed(String category);

  /// No description provided for @toastSavedMultiple.
  ///
  /// In cs, this message translates to:
  /// **'{count, plural, one{Uloženo {count} kus do „{category}“} few{Uloženo {count} kusy do „{category}“} other{Uloženo {count} kusů do „{category}“}}'**
  String toastSavedMultiple(int count, String category);

  /// No description provided for @outfitAlreadySavedTitle.
  ///
  /// In cs, this message translates to:
  /// **'Outfit už je uložený'**
  String get outfitAlreadySavedTitle;

  /// No description provided for @saveAnyway.
  ///
  /// In cs, this message translates to:
  /// **'Uložit i tak'**
  String get saveAnyway;

  /// No description provided for @aboutTagline.
  ///
  /// In cs, this message translates to:
  /// **'Šatník pro plánování outfitů'**
  String get aboutTagline;

  /// No description provided for @aboutVersionLine.
  ///
  /// In cs, this message translates to:
  /// **'v{version} ({buildNumber}) · Václav Parma'**
  String aboutVersionLine(String version, String buildNumber);

  /// No description provided for @sectionWardrobes.
  ///
  /// In cs, this message translates to:
  /// **'šatníky'**
  String get sectionWardrobes;

  /// No description provided for @settingsTitle.
  ///
  /// In cs, this message translates to:
  /// **'Nastavení'**
  String get settingsTitle;

  /// No description provided for @sectionLanguage.
  ///
  /// In cs, this message translates to:
  /// **'jazyk'**
  String get sectionLanguage;

  /// No description provided for @languageSystemOption.
  ///
  /// In cs, this message translates to:
  /// **'Podle systému'**
  String get languageSystemOption;

  /// No description provided for @sectionAppearance.
  ///
  /// In cs, this message translates to:
  /// **'vzhled'**
  String get sectionAppearance;

  /// No description provided for @themeLight.
  ///
  /// In cs, this message translates to:
  /// **'Světlý'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In cs, this message translates to:
  /// **'Tmavý'**
  String get themeDark;

  /// No description provided for @onboardingTitle.
  ///
  /// In cs, this message translates to:
  /// **'Vítej v Outfits'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In cs, this message translates to:
  /// **'Za pár minut si nastavíš šatník po svém a poskládáš první outfit. Všechno půjde později změnit.'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingContinue.
  ///
  /// In cs, this message translates to:
  /// **'Pokračovat'**
  String get onboardingContinue;

  /// No description provided for @defaultWardrobeName.
  ///
  /// In cs, this message translates to:
  /// **'Můj šatník'**
  String get defaultWardrobeName;

  /// No description provided for @newWardrobe.
  ///
  /// In cs, this message translates to:
  /// **'Nový šatník'**
  String get newWardrobe;

  /// No description provided for @newWardrobeHint.
  ///
  /// In cs, this message translates to:
  /// **'např. Chata'**
  String get newWardrobeHint;

  /// No description provided for @renameWardrobeTitle.
  ///
  /// In cs, this message translates to:
  /// **'Přejmenovat šatník'**
  String get renameWardrobeTitle;

  /// No description provided for @deleteWardrobeTitle.
  ///
  /// In cs, this message translates to:
  /// **'Smazat šatník?'**
  String get deleteWardrobeTitle;

  /// No description provided for @deleteWardrobeMessage.
  ///
  /// In cs, this message translates to:
  /// **'Šatník „{name}“ bude smazán, včetně všeho oblečení, fotek, kolekcí a outfitů v něm.'**
  String deleteWardrobeMessage(String name);

  /// No description provided for @colorsTitle.
  ///
  /// In cs, this message translates to:
  /// **'Barvy'**
  String get colorsTitle;

  /// No description provided for @colorsEdit.
  ///
  /// In cs, this message translates to:
  /// **'Upravit barvy'**
  String get colorsEdit;

  /// No description provided for @colorsHint.
  ///
  /// In cs, this message translates to:
  /// **'Vyber barvu pod fotkou a pak klepni na místo na fotce, odkud ji má převzít.'**
  String get colorsHint;

  /// No description provided for @colorsRedetect.
  ///
  /// In cs, this message translates to:
  /// **'Zjistit znovu automaticky'**
  String get colorsRedetect;

  /// No description provided for @colorAdd.
  ///
  /// In cs, this message translates to:
  /// **'Přidat barvu'**
  String get colorAdd;

  /// No description provided for @colorRemove.
  ///
  /// In cs, this message translates to:
  /// **'Odebrat barvu'**
  String get colorRemove;

  /// No description provided for @colorSlot.
  ///
  /// In cs, this message translates to:
  /// **'Barva {n}'**
  String colorSlot(int n);

  /// No description provided for @ok.
  ///
  /// In cs, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @sectionKinds.
  ///
  /// In cs, this message translates to:
  /// **'druhy a typy'**
  String get sectionKinds;

  /// No description provided for @addTypeChip.
  ///
  /// In cs, this message translates to:
  /// **'typ'**
  String get addTypeChip;

  /// No description provided for @newKind.
  ///
  /// In cs, this message translates to:
  /// **'Vlastní druh'**
  String get newKind;

  /// No description provided for @newKindHint.
  ///
  /// In cs, this message translates to:
  /// **'např. Čepice'**
  String get newKindHint;

  /// No description provided for @renameKindTitle.
  ///
  /// In cs, this message translates to:
  /// **'Přejmenovat druh'**
  String get renameKindTitle;

  /// No description provided for @deleteKindTitle.
  ///
  /// In cs, this message translates to:
  /// **'Smazat druh?'**
  String get deleteKindTitle;

  /// No description provided for @deleteKindMessage.
  ///
  /// In cs, this message translates to:
  /// **'Druh „{name}“ i s jeho typy bude smazán.'**
  String deleteKindMessage(String name);

  /// No description provided for @kindNotEmptyTitle.
  ///
  /// In cs, this message translates to:
  /// **'Druh není prázdný'**
  String get kindNotEmptyTitle;

  /// No description provided for @kindNotEmptyMessage.
  ///
  /// In cs, this message translates to:
  /// **'V druhu „{name}“ je ještě {items} (počítají se všechny šatníky). Nejdřív je přesuň do jiného druhu nebo smaž.'**
  String kindNotEmptyMessage(String name, String items);

  /// No description provided for @newTypeTitle.
  ///
  /// In cs, this message translates to:
  /// **'Nový typ'**
  String get newTypeTitle;

  /// No description provided for @newTypeHint.
  ///
  /// In cs, this message translates to:
  /// **'např. Košile'**
  String get newTypeHint;

  /// No description provided for @renameTypeTitle.
  ///
  /// In cs, this message translates to:
  /// **'Přejmenovat typ'**
  String get renameTypeTitle;

  /// No description provided for @deleteTypeTitle.
  ///
  /// In cs, this message translates to:
  /// **'Smazat typ?'**
  String get deleteTypeTitle;

  /// No description provided for @kindsHint.
  ///
  /// In cs, this message translates to:
  /// **'Druhy jsou karty na hlavní stránce, typy třídí oblečení uvnitř druhu. Pořadí změníš přetažením za úchyt.'**
  String get kindsHint;

  /// No description provided for @sectionKind.
  ///
  /// In cs, this message translates to:
  /// **'druh'**
  String get sectionKind;

  /// No description provided for @sectionType.
  ///
  /// In cs, this message translates to:
  /// **'typ'**
  String get sectionType;

  /// No description provided for @sectionWardrobe.
  ///
  /// In cs, this message translates to:
  /// **'šatník'**
  String get sectionWardrobe;

  /// No description provided for @all.
  ///
  /// In cs, this message translates to:
  /// **'Vše'**
  String get all;

  /// No description provided for @addClothes.
  ///
  /// In cs, this message translates to:
  /// **'Přidat'**
  String get addClothes;

  /// No description provided for @canvasEmpty.
  ///
  /// In cs, this message translates to:
  /// **'Na plátně zatím nic není.\nPřidej karty tlačítky dole — podržením je pak přesuneš, dvěma prsty změníš velikost.'**
  String get canvasEmpty;

  /// No description provided for @otherTypeName.
  ///
  /// In cs, this message translates to:
  /// **'Ostatní'**
  String get otherTypeName;

  /// No description provided for @defaultTypesDress.
  ///
  /// In cs, this message translates to:
  /// **'Letní, Společenské'**
  String get defaultTypesDress;

  /// No description provided for @deleteTypeMoveMessage.
  ///
  /// In cs, this message translates to:
  /// **'V typu „{name}“ je {items}. Kam je přesunout?'**
  String deleteTypeMoveMessage(String name, String items);

  /// No description provided for @canvasFull.
  ///
  /// In cs, this message translates to:
  /// **'Na plátně může být nejvýš {count} karet. Nějakou odeber — podrž ji a přetáhni do koše.'**
  String canvasFull(int count);

  /// No description provided for @rateAppHint.
  ///
  /// In cs, this message translates to:
  /// **'Pomůžeš tím ostatním appku najít'**
  String get rateAppHint;

  /// No description provided for @rateApp.
  ///
  /// In cs, this message translates to:
  /// **'Ohodnotit Outfits'**
  String get rateApp;

  /// No description provided for @sectionData.
  ///
  /// In cs, this message translates to:
  /// **'Data'**
  String get sectionData;

  /// No description provided for @exportData.
  ///
  /// In cs, this message translates to:
  /// **'Exportovat data'**
  String get exportData;

  /// No description provided for @exportDataHint.
  ///
  /// In cs, this message translates to:
  /// **'Šatníky, fotky, outfity, deník i nastavení v jednom souboru .zip'**
  String get exportDataHint;

  /// No description provided for @importData.
  ///
  /// In cs, this message translates to:
  /// **'Importovat data'**
  String get importData;

  /// No description provided for @importDataHint.
  ///
  /// In cs, this message translates to:
  /// **'Ze zálohy .zip — nahradí všechno, co je teď v aplikaci'**
  String get importDataHint;

  /// No description provided for @wardrobeCount.
  ///
  /// In cs, this message translates to:
  /// **'{count, plural, one{{count} šatník} few{{count} šatníky} other{{count} šatníků}}'**
  String wardrobeCount(int count);

  /// No description provided for @importConfirmTitle.
  ///
  /// In cs, this message translates to:
  /// **'Nahradit všechna data?'**
  String get importConfirmTitle;

  /// No description provided for @importConfirmMessage.
  ///
  /// In cs, this message translates to:
  /// **'Záloha obsahuje {wardrobes}, {items} a {outfits}. Nahradí všechno, co je teď v aplikaci — šatníky, fotky, outfity, deník i nastavení. Jestli chceš mít současný stav schovaný, nejdřív ho exportuj.'**
  String importConfirmMessage(String wardrobes, String items, String outfits);

  /// No description provided for @importConfirm.
  ///
  /// In cs, this message translates to:
  /// **'Nahradit'**
  String get importConfirm;

  /// No description provided for @importDone.
  ///
  /// In cs, this message translates to:
  /// **'Data jsou naimportovaná'**
  String get importDone;

  /// No description provided for @importFailedTitle.
  ///
  /// In cs, this message translates to:
  /// **'Import se nepovedl'**
  String get importFailedTitle;

  /// No description provided for @importNotABackup.
  ///
  /// In cs, this message translates to:
  /// **'Tenhle soubor není záloha z Outfits.'**
  String get importNotABackup;

  /// No description provided for @importNewerVersion.
  ///
  /// In cs, this message translates to:
  /// **'Záloha je z novější verze Outfits. Aktualizuj aplikaci a zkus to znovu.'**
  String get importNewerVersion;

  /// No description provided for @importFailed.
  ///
  /// In cs, this message translates to:
  /// **'Data se nepodařilo naimportovat. V aplikaci zůstalo všechno, jak bylo.'**
  String get importFailed;

  /// No description provided for @exportFailed.
  ///
  /// In cs, this message translates to:
  /// **'Data se nepodařilo vyexportovat.'**
  String get exportFailed;

  /// No description provided for @deleteForGood.
  ///
  /// In cs, this message translates to:
  /// **'Opravdu smazat'**
  String get deleteForGood;

  /// No description provided for @dropToRemove.
  ///
  /// In cs, this message translates to:
  /// **'Pusť sem pro odebrání'**
  String get dropToRemove;

  /// No description provided for @reorder.
  ///
  /// In cs, this message translates to:
  /// **'Změnit pořadí'**
  String get reorder;

  /// No description provided for @newTypeTile.
  ///
  /// In cs, this message translates to:
  /// **'nový typ'**
  String get newTypeTile;

  /// No description provided for @tabDiary.
  ///
  /// In cs, this message translates to:
  /// **'Deník'**
  String get tabDiary;

  /// No description provided for @diaryCalendar.
  ///
  /// In cs, this message translates to:
  /// **'Kalendář'**
  String get diaryCalendar;

  /// No description provided for @diaryStats.
  ///
  /// In cs, this message translates to:
  /// **'Statistiky'**
  String get diaryStats;

  /// No description provided for @diaryDaysCount.
  ///
  /// In cs, this message translates to:
  /// **'{count, plural, one{{count} den} few{{count} dny} other{{count} dní}}'**
  String diaryDaysCount(int count);

  /// No description provided for @diaryToday.
  ///
  /// In cs, this message translates to:
  /// **'Dnes'**
  String get diaryToday;

  /// No description provided for @diaryYesterday.
  ///
  /// In cs, this message translates to:
  /// **'Včera'**
  String get diaryYesterday;

  /// No description provided for @diaryDayEmpty.
  ///
  /// In cs, this message translates to:
  /// **'Na tenhle den zatím nemáš nic zapsané.'**
  String get diaryDayEmpty;

  /// No description provided for @diaryFromCanvas.
  ///
  /// In cs, this message translates to:
  /// **'Z plátna'**
  String get diaryFromCanvas;

  /// No description provided for @diaryFromSaved.
  ///
  /// In cs, this message translates to:
  /// **'Z uložených'**
  String get diaryFromSaved;

  /// No description provided for @diaryCanvasEmpty.
  ///
  /// In cs, this message translates to:
  /// **'Na plátně zatím není žádné oblečení.'**
  String get diaryCanvasEmpty;

  /// No description provided for @diaryPickSavedTitle.
  ///
  /// In cs, this message translates to:
  /// **'Uložené outfity'**
  String get diaryPickSavedTitle;

  /// No description provided for @diaryRemoveEntry.
  ///
  /// In cs, this message translates to:
  /// **'Odebrat z deníku'**
  String get diaryRemoveEntry;

  /// No description provided for @statsDaysLogged.
  ///
  /// In cs, this message translates to:
  /// **'{count, plural, one{den zapsán tento měsíc} few{dny zapsány tento měsíc} other{dní zapsáno tento měsíc}}'**
  String statsDaysLogged(int count);

  /// No description provided for @statsItemsWorn.
  ///
  /// In cs, this message translates to:
  /// **'kusů nošeno tento měsíc'**
  String get statsItemsWorn;

  /// No description provided for @statsTimesWorn.
  ///
  /// In cs, this message translates to:
  /// **'Počet nošení'**
  String get statsTimesWorn;

  /// No description provided for @statsAllTime.
  ///
  /// In cs, this message translates to:
  /// **'celkem'**
  String get statsAllTime;

  /// No description provided for @statsShowAll.
  ///
  /// In cs, this message translates to:
  /// **'zobrazit všech {count}'**
  String statsShowAll(int count);

  /// No description provided for @statsShowLess.
  ///
  /// In cs, this message translates to:
  /// **'zobrazit méně'**
  String get statsShowLess;

  /// No description provided for @statsNotWorn.
  ///
  /// In cs, this message translates to:
  /// **'Dlouho nenošené'**
  String get statsNotWorn;

  /// No description provided for @statsNever.
  ///
  /// In cs, this message translates to:
  /// **'nikdy'**
  String get statsNever;

  /// No description provided for @statsDaysAgo.
  ///
  /// In cs, this message translates to:
  /// **'před {n} dny'**
  String statsDaysAgo(int n);

  /// No description provided for @statsNothingUnworn.
  ///
  /// In cs, this message translates to:
  /// **'Všechno oblečení bylo za posledních {n} dní aspoň jednou na řadě.'**
  String statsNothingUnworn(int n);

  /// No description provided for @statsEmpty.
  ///
  /// In cs, this message translates to:
  /// **'Statistiky se objeví, až v kalendáři zapíšeš první outfit.'**
  String get statsEmpty;

  /// No description provided for @timesWorn.
  ///
  /// In cs, this message translates to:
  /// **'{n}×'**
  String timesWorn(int n);

  /// No description provided for @colorFamily.
  ///
  /// In cs, this message translates to:
  /// **'{color, select, white{Bílá} beige{Béžová} yellow{Žlutá} orange{Oranžová} red{Červená} pink{Růžová} purple{Fialová} blue{Modrá} green{Zelená} brown{Hnědá} grey{Šedá} black{Černá} other{Jiná}}'**
  String colorFamily(String color);

  /// No description provided for @statsColors.
  ///
  /// In cs, this message translates to:
  /// **'Barvy'**
  String get statsColors;

  /// No description provided for @statsInWardrobe.
  ///
  /// In cs, this message translates to:
  /// **'v šatníku'**
  String get statsInWardrobe;

  /// No description provided for @statsWornLabel.
  ///
  /// In cs, this message translates to:
  /// **'na sobě'**
  String get statsWornLabel;

  /// No description provided for @statsColWardrobe.
  ///
  /// In cs, this message translates to:
  /// **'šatník'**
  String get statsColWardrobe;

  /// No description provided for @statsNotWornSince.
  ///
  /// In cs, this message translates to:
  /// **'30+ dní'**
  String get statsNotWornSince;

  /// No description provided for @diaryLogOutfit.
  ///
  /// In cs, this message translates to:
  /// **'Zapsat outfit'**
  String get diaryLogOutfit;

  /// No description provided for @sectionDay.
  ///
  /// In cs, this message translates to:
  /// **'den'**
  String get sectionDay;

  /// No description provided for @diaryOtherDay.
  ///
  /// In cs, this message translates to:
  /// **'Jiný den…'**
  String get diaryOtherDay;

  /// No description provided for @toastLogged.
  ///
  /// In cs, this message translates to:
  /// **'Zapsáno do deníku · {date}'**
  String toastLogged(String date);

  /// No description provided for @itemWornLabel.
  ///
  /// In cs, this message translates to:
  /// **'nošeno'**
  String get itemWornLabel;

  /// No description provided for @itemLastWornLabel.
  ///
  /// In cs, this message translates to:
  /// **'naposledy'**
  String get itemLastWornLabel;

  /// No description provided for @itemPerWearLabel.
  ///
  /// In cs, this message translates to:
  /// **'za nošení'**
  String get itemPerWearLabel;

  /// No description provided for @itemLastToday.
  ///
  /// In cs, this message translates to:
  /// **'dnes'**
  String get itemLastToday;

  /// No description provided for @itemLastYesterday.
  ///
  /// In cs, this message translates to:
  /// **'včera'**
  String get itemLastYesterday;

  /// No description provided for @itemAutoNameHint.
  ///
  /// In cs, this message translates to:
  /// **'název z barvy a typu · přepíšeš v podrobnostech'**
  String get itemAutoNameHint;

  /// No description provided for @sectionDetails.
  ///
  /// In cs, this message translates to:
  /// **'podrobnosti · volitelné'**
  String get sectionDetails;

  /// No description provided for @reminderTitle.
  ///
  /// In cs, this message translates to:
  /// **'Co máš dnes na sobě?'**
  String get reminderTitle;

  /// No description provided for @reminderBody.
  ///
  /// In cs, this message translates to:
  /// **'Zapiš si dnešní outfit do deníku.'**
  String get reminderBody;

  /// No description provided for @reminderChannel.
  ///
  /// In cs, this message translates to:
  /// **'Upomínka deníku'**
  String get reminderChannel;

  /// No description provided for @sectionDiary.
  ///
  /// In cs, this message translates to:
  /// **'deník'**
  String get sectionDiary;

  /// No description provided for @reminderLabel.
  ///
  /// In cs, this message translates to:
  /// **'Denní upomínka'**
  String get reminderLabel;

  /// No description provided for @reminderHint.
  ///
  /// In cs, this message translates to:
  /// **'Připomene ti zapsat outfit — jen když ten den ještě nemáš nic zapsané.'**
  String get reminderHint;

  /// No description provided for @reminderTime.
  ///
  /// In cs, this message translates to:
  /// **'Čas'**
  String get reminderTime;

  /// No description provided for @reminderDeniedTitle.
  ///
  /// In cs, this message translates to:
  /// **'Notifikace jsou vypnuté'**
  String get reminderDeniedTitle;

  /// No description provided for @reminderDeniedMessage.
  ///
  /// In cs, this message translates to:
  /// **'Aby upomínka mohla přijít, povol aplikaci notifikace v Nastavení telefonu.'**
  String get reminderDeniedMessage;

  /// No description provided for @tabOutfits.
  ///
  /// In cs, this message translates to:
  /// **'Sbírka'**
  String get tabOutfits;

  /// No description provided for @searchOutfitsHint.
  ///
  /// In cs, this message translates to:
  /// **'Hledat podle oblečení'**
  String get searchOutfitsHint;

  /// No description provided for @filterFavorites.
  ///
  /// In cs, this message translates to:
  /// **'Oblíbené'**
  String get filterFavorites;

  /// No description provided for @filterOftenWorn.
  ///
  /// In cs, this message translates to:
  /// **'Často nošené'**
  String get filterOftenWorn;

  /// No description provided for @favorite.
  ///
  /// In cs, this message translates to:
  /// **'Oblíbený'**
  String get favorite;

  /// No description provided for @toastOutfitSavedPlain.
  ///
  /// In cs, this message translates to:
  /// **'Outfit uložen'**
  String get toastOutfitSavedPlain;

  /// No description provided for @outfitAlreadySavedHere.
  ///
  /// In cs, this message translates to:
  /// **'Tuhle kombinaci už máš mezi outfity. Uložit i tak?'**
  String get outfitAlreadySavedHere;

  /// No description provided for @outfitAlreadySavedIn.
  ///
  /// In cs, this message translates to:
  /// **'Tuhle kombinaci už máš uloženou v šatníku „{wardrobe}“. Uložit i tak?'**
  String outfitAlreadySavedIn(String wardrobe);

  /// No description provided for @deleteOutfitPlain.
  ///
  /// In cs, this message translates to:
  /// **'Outfit bude smazán.'**
  String get deleteOutfitPlain;

  /// No description provided for @outfitsEmpty.
  ///
  /// In cs, this message translates to:
  /// **'Zatím nemáš žádné uložené outfity. Poskládej si nějaký na hlavní stránce a ulož ho.'**
  String get outfitsEmpty;

  /// No description provided for @outfitUsualWeekday.
  ///
  /// In cs, this message translates to:
  /// **'{weekday, select, 1{nejčastěji v pondělí} 2{nejčastěji v úterý} 3{nejčastěji ve středu} 4{nejčastěji ve čtvrtek} 5{nejčastěji v pátek} 6{nejčastěji v sobotu} 7{nejčastěji v neděli} other{}}'**
  String outfitUsualWeekday(String weekday);

  /// No description provided for @wearToday.
  ///
  /// In cs, this message translates to:
  /// **'Nosím dnes'**
  String get wearToday;

  /// No description provided for @outfitWornToday.
  ///
  /// In cs, this message translates to:
  /// **'Dnes zapsáno'**
  String get outfitWornToday;

  /// No description provided for @editOnCanvas.
  ///
  /// In cs, this message translates to:
  /// **'Přenést na plátno'**
  String get editOnCanvas;

  /// No description provided for @diaryRemoveEntryTitle.
  ///
  /// In cs, this message translates to:
  /// **'Odebrat z deníku?'**
  String get diaryRemoveEntryTitle;

  /// No description provided for @diaryRemoveEntryMessage.
  ///
  /// In cs, this message translates to:
  /// **'Zápis tohoto outfitu u dne bude smazán.'**
  String get diaryRemoveEntryMessage;

  /// No description provided for @nameTaken.
  ///
  /// In cs, this message translates to:
  /// **'Tenhle název už existuje.'**
  String get nameTaken;

  /// No description provided for @onboardingStart.
  ///
  /// In cs, this message translates to:
  /// **'Začít'**
  String get onboardingStart;

  /// No description provided for @onboardingLooksTitle.
  ///
  /// In cs, this message translates to:
  /// **'Vzhled a jazyk'**
  String get onboardingLooksTitle;

  /// No description provided for @onboardingLooksBody.
  ///
  /// In cs, this message translates to:
  /// **'Jak má aplikace vypadat a jakou řečí mluvit.'**
  String get onboardingLooksBody;

  /// No description provided for @onboardingWardrobeTitle.
  ///
  /// In cs, this message translates to:
  /// **'Tvůj šatník'**
  String get onboardingWardrobeTitle;

  /// No description provided for @onboardingWardrobeBody.
  ///
  /// In cs, this message translates to:
  /// **'Pojmenuj ho — třeba „Doma“. Další šatníky (chata, kancelář…) přidáš kdykoli v nastavení.'**
  String get onboardingWardrobeBody;

  /// No description provided for @onboardingKindsTitle.
  ///
  /// In cs, this message translates to:
  /// **'Co nosíš'**
  String get onboardingKindsTitle;

  /// No description provided for @onboardingKindsBody.
  ///
  /// In cs, this message translates to:
  /// **'Vyber druhy oblečení, se kterými chceš pracovat. Každý druh je karta na plátně, typy uvnitř (trička, košile…) upravíš v nastavení.'**
  String get onboardingKindsBody;

  /// No description provided for @onboardingReminderTitle.
  ///
  /// In cs, this message translates to:
  /// **'Denní upomínka'**
  String get onboardingReminderTitle;

  /// No description provided for @onboardingReminderBody.
  ///
  /// In cs, this message translates to:
  /// **'Z deníku se počítá, co nosíš nejčastěji a co leží ve skříni. Upomínka ti připomene zapsat dnešní outfit — klidně ji nech vypnutou.'**
  String get onboardingReminderBody;

  /// No description provided for @tourAddTitle.
  ///
  /// In cs, this message translates to:
  /// **'Přidej první kusy'**
  String get tourAddTitle;

  /// No description provided for @tourAddBody.
  ///
  /// In cs, this message translates to:
  /// **'Vyfoť nebo vyber z galerie pár kousků — třeba tričko, kalhoty a boty. Barvy i název se doplní samy.'**
  String get tourAddBody;

  /// No description provided for @tourAddButton.
  ///
  /// In cs, this message translates to:
  /// **'Přidat oblečení'**
  String get tourAddButton;

  /// No description provided for @tourAddMore.
  ///
  /// In cs, this message translates to:
  /// **'Přidat další'**
  String get tourAddMore;

  /// No description provided for @tourCanvasTitle.
  ///
  /// In cs, this message translates to:
  /// **'Tvůj první outfit'**
  String get tourCanvasTitle;

  /// No description provided for @tourCanvasBody.
  ///
  /// In cs, this message translates to:
  /// **'Tvoje kusy jsou na plátně. Ťukni na kartu a vyber jiný kus, podrž ji a přesuň, dvěma prsty změníš velikost. Pak outfit ulož.'**
  String get tourCanvasBody;

  /// No description provided for @tourOutfitsBody.
  ///
  /// In cs, this message translates to:
  /// **'Tady jsou uložené outfity. Najdeš je podle oblečení, srdíčkem si označíš oblíbené a ťuknutím otevřeš detail.'**
  String get tourOutfitsBody;

  /// No description provided for @tourDiaryBody.
  ///
  /// In cs, this message translates to:
  /// **'Zapisuj, co máš na sobě — tlačítkem + nebo ťuknutím na den. Ze zápisů vznikají statistiky: co nosíš nejvíc a co ne.'**
  String get tourDiaryBody;

  /// No description provided for @tourNext.
  ///
  /// In cs, this message translates to:
  /// **'Dál'**
  String get tourNext;

  /// No description provided for @tourSkip.
  ///
  /// In cs, this message translates to:
  /// **'Přeskočit'**
  String get tourSkip;

  /// No description provided for @tourClose.
  ///
  /// In cs, this message translates to:
  /// **'Ukončit prohlídku'**
  String get tourClose;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['cs', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'cs':
      return AppLocalizationsCs();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
