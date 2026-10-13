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
  String get deleteOutfitTitle => 'Delete outfit?';

  @override
  String get addItemTitle => 'Add clothing';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get fromGallery => 'From gallery';

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
  String get searchHint => 'Search clothes';

  @override
  String get nothingFound => 'Nothing found.';

  @override
  String get sectionItemName => 'name';

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
  String get saveAnyway => 'Save anyway';

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
      'In a couple of minutes you\'ll set up your wardrobe your way and put together your first outfit. You can change everything later.';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get defaultWardrobeName => 'My wardrobe';

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

  @override
  String get tabDiary => 'Diary';

  @override
  String get diaryCalendar => 'Calendar';

  @override
  String get diaryStats => 'Stats';

  @override
  String diaryDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String get diaryToday => 'Today';

  @override
  String get diaryYesterday => 'Yesterday';

  @override
  String get diaryDayEmpty => 'Nothing logged for this day yet.';

  @override
  String get diaryFromCanvas => 'From canvas';

  @override
  String get diaryFromSaved => 'From saved';

  @override
  String get diaryCanvasEmpty => 'There are no clothes on the canvas yet.';

  @override
  String get diaryPickSavedTitle => 'Saved outfits';

  @override
  String get diaryRemoveEntry => 'Remove from diary';

  @override
  String statsDaysLogged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days logged this month',
      one: 'day logged this month',
    );
    return '$_temp0';
  }

  @override
  String get statsItemsWorn => 'items worn this month';

  @override
  String get statsTimesWorn => 'Times worn';

  @override
  String get statsAllTime => 'all time';

  @override
  String statsShowAll(int count) {
    return 'show all $count';
  }

  @override
  String get statsShowLess => 'show less';

  @override
  String get statsNotWorn => 'Not worn lately';

  @override
  String get statsNever => 'never';

  @override
  String statsDaysAgo(int n) {
    return '$n days ago';
  }

  @override
  String statsNothingUnworn(int n) {
    return 'Every piece of clothing got worn at least once in the last $n days.';
  }

  @override
  String get statsEmpty =>
      'Stats show up once you log your first outfit in the calendar.';

  @override
  String timesWorn(int n) {
    return '$n×';
  }

  @override
  String colorFamily(String color) {
    String _temp0 = intl.Intl.selectLogic(color, {
      'white': 'White',
      'beige': 'Beige',
      'yellow': 'Yellow',
      'orange': 'Orange',
      'red': 'Red',
      'pink': 'Pink',
      'purple': 'Purple',
      'blue': 'Blue',
      'green': 'Green',
      'brown': 'Brown',
      'grey': 'Grey',
      'black': 'Black',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String get statsColors => 'Colors';

  @override
  String get statsInWardrobe => 'in wardrobe';

  @override
  String get statsWornLabel => 'worn';

  @override
  String get statsColWardrobe => 'wardrobe';

  @override
  String get statsNotWornSince => '30+ days';

  @override
  String get diaryLogOutfit => 'Log an outfit';

  @override
  String get sectionDay => 'day';

  @override
  String get diaryOtherDay => 'Other day…';

  @override
  String toastLogged(String date) {
    return 'Logged in the diary · $date';
  }

  @override
  String get itemWornLabel => 'worn';

  @override
  String get itemLastWornLabel => 'last worn';

  @override
  String get itemPerWearLabel => 'per wear';

  @override
  String get itemLastToday => 'today';

  @override
  String get itemLastYesterday => 'yesterday';

  @override
  String get itemAutoNameHint =>
      'named from color and type · change it in the details';

  @override
  String get sectionDetails => 'details · optional';

  @override
  String get reminderTitle => 'What are you wearing today?';

  @override
  String get reminderBody => 'Log today\'s outfit in your diary.';

  @override
  String get reminderChannel => 'Diary reminder';

  @override
  String get sectionDiary => 'diary';

  @override
  String get reminderLabel => 'Daily reminder';

  @override
  String get reminderHint =>
      'Reminds you to log your outfit — only if nothing\'s logged for the day yet.';

  @override
  String get reminderTime => 'Time';

  @override
  String get reminderDeniedTitle => 'Notifications are off';

  @override
  String get reminderDeniedMessage =>
      'To get the reminder, allow notifications for the app in your phone\'s Settings.';

  @override
  String get tabOutfits => 'Collection';

  @override
  String get searchOutfitsHint => 'Search by clothes';

  @override
  String get filterFavorites => 'Favorites';

  @override
  String get filterOftenWorn => 'Worn often';

  @override
  String get favorite => 'Favorite';

  @override
  String get toastOutfitSavedPlain => 'Outfit saved';

  @override
  String get outfitAlreadySavedHere =>
      'You already have this combination among your outfits. Save it anyway?';

  @override
  String outfitAlreadySavedIn(String wardrobe) {
    return 'You already have this combination saved in the “$wardrobe” wardrobe. Save it anyway?';
  }

  @override
  String get deleteOutfitPlain => 'The outfit will be deleted.';

  @override
  String get outfitsEmpty =>
      'No saved outfits yet. Put one together on the main page and save it.';

  @override
  String outfitUsualWeekday(String weekday) {
    String _temp0 = intl.Intl.selectLogic(weekday, {
      '1': 'mostly on Mondays',
      '2': 'mostly on Tuesdays',
      '3': 'mostly on Wednesdays',
      '4': 'mostly on Thursdays',
      '5': 'mostly on Fridays',
      '6': 'mostly on Saturdays',
      '7': 'mostly on Sundays',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get wearToday => 'Wearing it today';

  @override
  String get outfitWornToday => 'Logged today';

  @override
  String get editOnCanvas => 'Edit on canvas';

  @override
  String get diaryRemoveEntryTitle => 'Remove from the diary?';

  @override
  String get diaryRemoveEntryMessage =>
      'This outfit will be removed from the day.';

  @override
  String get nameTaken => 'That name is already taken.';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboardingLooksTitle => 'Look and language';

  @override
  String get onboardingLooksBody =>
      'How the app should look and which language it speaks.';

  @override
  String get onboardingWardrobeTitle => 'Your wardrobe';

  @override
  String get onboardingWardrobeBody =>
      'Give it a name — say “Home”. You can add more wardrobes (cottage, office…) in settings any time.';

  @override
  String get onboardingKindsTitle => 'What you wear';

  @override
  String get onboardingKindsBody =>
      'Pick the kinds of clothing you want to work with. Each kind is a card on the canvas; the types within (t-shirts, shirts…) can be edited in settings.';

  @override
  String get onboardingReminderTitle => 'Daily reminder';

  @override
  String get onboardingReminderBody =>
      'The diary is what shows what you wear most and what just sits in the closet. The reminder nudges you to log today\'s outfit — feel free to leave it off.';

  @override
  String get tourAddTitle => 'Add your first pieces';

  @override
  String get tourAddBody =>
      'Take or pick a few photos — say a top, trousers and shoes. Colors and names fill in by themselves.';

  @override
  String get tourAddButton => 'Add clothes';

  @override
  String get tourAddMore => 'Add more';

  @override
  String get tourCanvasTitle => 'Your first outfit';

  @override
  String get tourCanvasBody =>
      'Your clothes are on the canvas. Tap a card to pick another piece, hold it to move it, pinch to resize. Then save the outfit.';

  @override
  String get tourOutfitsBody =>
      'Your saved outfits live here. Search them by clothes, heart your favorites, and tap one for its detail.';

  @override
  String get tourDiaryBody =>
      'Log what you wear — with the + button or by tapping a day. The entries add up to stats: what you wear most, and what you don\'t.';

  @override
  String get tourNext => 'Next';

  @override
  String get tourSkip => 'Skip';

  @override
  String get tourClose => 'End the tour';
}
