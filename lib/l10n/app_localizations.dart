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

  /// No description provided for @tabCollections.
  ///
  /// In cs, this message translates to:
  /// **'Kolekce'**
  String get tabCollections;

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

  /// No description provided for @noTags.
  ///
  /// In cs, this message translates to:
  /// **'bez tagů'**
  String get noTags;

  /// No description provided for @rename.
  ///
  /// In cs, this message translates to:
  /// **'Přejmenovat'**
  String get rename;

  /// No description provided for @slotTop.
  ///
  /// In cs, this message translates to:
  /// **'top'**
  String get slotTop;

  /// No description provided for @slotDressFull.
  ///
  /// In cs, this message translates to:
  /// **'šaty · celé tělo'**
  String get slotDressFull;

  /// No description provided for @slotBottom.
  ///
  /// In cs, this message translates to:
  /// **'spodek'**
  String get slotBottom;

  /// No description provided for @slotSkirt.
  ///
  /// In cs, this message translates to:
  /// **'sukně'**
  String get slotSkirt;

  /// No description provided for @slotShoes.
  ///
  /// In cs, this message translates to:
  /// **'boty'**
  String get slotShoes;

  /// No description provided for @addTopPlaceholder.
  ///
  /// In cs, this message translates to:
  /// **'Přidej top'**
  String get addTopPlaceholder;

  /// No description provided for @addBottomPlaceholder.
  ///
  /// In cs, this message translates to:
  /// **'Přidej spodek'**
  String get addBottomPlaceholder;

  /// No description provided for @addShoesPlaceholder.
  ///
  /// In cs, this message translates to:
  /// **'Přidej boty'**
  String get addShoesPlaceholder;

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

  /// No description provided for @categoryTricka.
  ///
  /// In cs, this message translates to:
  /// **'Trička / topy'**
  String get categoryTricka;

  /// No description provided for @categorySaty.
  ///
  /// In cs, this message translates to:
  /// **'Šaty'**
  String get categorySaty;

  /// No description provided for @categoryBundy.
  ///
  /// In cs, this message translates to:
  /// **'Bundy / vrstvy'**
  String get categoryBundy;

  /// No description provided for @categoryKalhoty.
  ///
  /// In cs, this message translates to:
  /// **'Kalhoty'**
  String get categoryKalhoty;

  /// No description provided for @categorySukne.
  ///
  /// In cs, this message translates to:
  /// **'Sukně'**
  String get categorySukne;

  /// No description provided for @categoryBoty.
  ///
  /// In cs, this message translates to:
  /// **'Boty'**
  String get categoryBoty;

  /// No description provided for @itemCount.
  ///
  /// In cs, this message translates to:
  /// **'{count, plural, one{{count} kus} few{{count} kusy} other{{count} kusů}}'**
  String itemCount(int count);

  /// No description provided for @newCollectionTile.
  ///
  /// In cs, this message translates to:
  /// **'nová kolekce'**
  String get newCollectionTile;

  /// No description provided for @newCollectionDialogTitle.
  ///
  /// In cs, this message translates to:
  /// **'Nová kolekce'**
  String get newCollectionDialogTitle;

  /// No description provided for @newCollectionHint.
  ///
  /// In cs, this message translates to:
  /// **'např. Práce'**
  String get newCollectionHint;

  /// No description provided for @outfitCount.
  ///
  /// In cs, this message translates to:
  /// **'{count, plural, one{{count} outfit} few{{count} outfity} other{{count} outfitů}}'**
  String outfitCount(int count);

  /// No description provided for @collectionEmptyHint.
  ///
  /// In cs, this message translates to:
  /// **'Zatím prázdné. Ulož outfit a vyber tuto kolekci.'**
  String get collectionEmptyHint;

  /// No description provided for @renameCollectionTitle.
  ///
  /// In cs, this message translates to:
  /// **'Přejmenovat kolekci'**
  String get renameCollectionTitle;

  /// No description provided for @deleteCollectionTitle.
  ///
  /// In cs, this message translates to:
  /// **'Smazat kolekci?'**
  String get deleteCollectionTitle;

  /// No description provided for @deleteCollectionMessage.
  ///
  /// In cs, this message translates to:
  /// **'Kolekce „{name}“ a vše v ní bude smazáno.'**
  String deleteCollectionMessage(String name);

  /// No description provided for @deleteOutfitTitle.
  ///
  /// In cs, this message translates to:
  /// **'Smazat outfit?'**
  String get deleteOutfitTitle;

  /// No description provided for @deleteOutfitMessage.
  ///
  /// In cs, this message translates to:
  /// **'„{name}“ bude smazán.'**
  String deleteOutfitMessage(String name);

  /// No description provided for @pickTopTitle.
  ///
  /// In cs, this message translates to:
  /// **'Vyber top nebo šaty'**
  String get pickTopTitle;

  /// No description provided for @pickBottomTitle.
  ///
  /// In cs, this message translates to:
  /// **'Vyber spodek'**
  String get pickBottomTitle;

  /// No description provided for @pickShoesTitle.
  ///
  /// In cs, this message translates to:
  /// **'Vyber boty'**
  String get pickShoesTitle;

  /// No description provided for @addLayerTitle.
  ///
  /// In cs, this message translates to:
  /// **'Přidat vrstvu'**
  String get addLayerTitle;

  /// No description provided for @layerLimitMessage.
  ///
  /// In cs, this message translates to:
  /// **'{max, plural, one{Můžeš mít nejvýš {max} vrstvu navíc.} few{Můžeš mít nejvýš {max} vrstvy navíc.} other{Můžeš mít nejvýš {max} vrstev navíc.}}'**
  String layerLimitMessage(int max);

  /// No description provided for @noMoreLayers.
  ///
  /// In cs, this message translates to:
  /// **'Žádné další vrstvy k přidání.'**
  String get noMoreLayers;

  /// No description provided for @addItemTitle.
  ///
  /// In cs, this message translates to:
  /// **'Přidat oblečení'**
  String get addItemTitle;

  /// No description provided for @sectionCategory.
  ///
  /// In cs, this message translates to:
  /// **'kategorie'**
  String get sectionCategory;

  /// No description provided for @sectionTagsOptional.
  ///
  /// In cs, this message translates to:
  /// **'tagy (nepovinné)'**
  String get sectionTagsOptional;

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

  /// No description provided for @itemDetailTitle.
  ///
  /// In cs, this message translates to:
  /// **'Detail oblečení'**
  String get itemDetailTitle;

  /// No description provided for @useInOutfit.
  ///
  /// In cs, this message translates to:
  /// **'Použít v outfitu'**
  String get useInOutfit;

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

  /// No description provided for @sectionOutfitName.
  ///
  /// In cs, this message translates to:
  /// **'název outfitu'**
  String get sectionOutfitName;

  /// No description provided for @outfitNameHint.
  ///
  /// In cs, this message translates to:
  /// **'např. Pondělní porada'**
  String get outfitNameHint;

  /// No description provided for @sectionCollection.
  ///
  /// In cs, this message translates to:
  /// **'kolekce'**
  String get sectionCollection;

  /// No description provided for @needCollectionHint.
  ///
  /// In cs, this message translates to:
  /// **'Nejdřív vytvoř kolekci v záložce Kolekce.'**
  String get needCollectionHint;

  /// No description provided for @manageTagsTitle.
  ///
  /// In cs, this message translates to:
  /// **'Spravovat tagy'**
  String get manageTagsTitle;

  /// No description provided for @newTagHint.
  ///
  /// In cs, this message translates to:
  /// **'nový tag'**
  String get newTagHint;

  /// No description provided for @noTagsYet.
  ///
  /// In cs, this message translates to:
  /// **'Zatím žádné tagy.'**
  String get noTagsYet;

  /// No description provided for @renameTagTitle.
  ///
  /// In cs, this message translates to:
  /// **'Přejmenovat tag'**
  String get renameTagTitle;

  /// No description provided for @deleteTagTitle.
  ///
  /// In cs, this message translates to:
  /// **'Smazat tag?'**
  String get deleteTagTitle;

  /// No description provided for @deleteTagMessage.
  ///
  /// In cs, this message translates to:
  /// **'Tag „{tag}“ bude smazán a odebrán ze všech kusů oblečení.'**
  String deleteTagMessage(String tag);

  /// No description provided for @toastSavedWithPhoto.
  ///
  /// In cs, this message translates to:
  /// **'Uloženo do „{category}“ · fotka v souborech apky'**
  String toastSavedWithPhoto(String category);

  /// No description provided for @toastSavedNoPhoto.
  ///
  /// In cs, this message translates to:
  /// **'Uloženo do „{category}“'**
  String toastSavedNoPhoto(String category);

  /// No description provided for @toastSavedPhotoFailed.
  ///
  /// In cs, this message translates to:
  /// **'Uloženo do „{category}“ · fotku se nepodařilo uložit'**
  String toastSavedPhotoFailed(String category);

  /// No description provided for @toastOutfitSaved.
  ///
  /// In cs, this message translates to:
  /// **'„{name}“ uloženo do kolekce {col}'**
  String toastOutfitSaved(String name, String col);

  /// No description provided for @toastNeedCollectionFirst.
  ///
  /// In cs, this message translates to:
  /// **'Nejdřív přidej kolekci'**
  String get toastNeedCollectionFirst;

  /// No description provided for @defaultOutfitName.
  ///
  /// In cs, this message translates to:
  /// **'Outfit {n}'**
  String defaultOutfitName(int n);

  /// No description provided for @aboutTagline.
  ///
  /// In cs, this message translates to:
  /// **'Šatník pro plánování outfitů'**
  String get aboutTagline;

  /// No description provided for @aboutGithub.
  ///
  /// In cs, this message translates to:
  /// **'Zdrojový kód na GitHubu'**
  String get aboutGithub;

  /// No description provided for @aboutSupport.
  ///
  /// In cs, this message translates to:
  /// **'Podpoř vývoj — Buy Me a Coffee'**
  String get aboutSupport;

  /// No description provided for @aboutVersionLine.
  ///
  /// In cs, this message translates to:
  /// **'v{version} ({buildNumber}) · Václav Parma'**
  String aboutVersionLine(String version, String buildNumber);

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

  /// No description provided for @showDressesLabel.
  ///
  /// In cs, this message translates to:
  /// **'Zobrazovat šaty v šatníku'**
  String get showDressesLabel;

  /// No description provided for @showDressesHint.
  ///
  /// In cs, this message translates to:
  /// **'Skryje kategorii šatů v šatníku a při přidávání oblečení. Šaty, které už máš v šatníku, zůstanou beze změny.'**
  String get showDressesHint;

  /// No description provided for @showSkirtsLabel.
  ///
  /// In cs, this message translates to:
  /// **'Zobrazovat sukně v šatníku'**
  String get showSkirtsLabel;

  /// No description provided for @showSkirtsHint.
  ///
  /// In cs, this message translates to:
  /// **'Skryje kategorii sukní v šatníku a při přidávání oblečení. Sukně, které už máš v šatníku, zůstanou beze změny.'**
  String get showSkirtsHint;
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
