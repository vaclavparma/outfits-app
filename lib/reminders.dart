import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'models.dart';
import 'wardrobe_store.dart';

/// The daily "log your outfit" reminder, as local notifications.
///
/// Rather than one repeating notification, each of the next [_days] days
/// gets its own — so a day already logged in the diary can be skipped.
/// [schedule] is called again whenever that could change (the app opens,
/// the diary or the setting changes), which also keeps the window moving;
/// someone who hasn't opened the app for two weeks stops being reminded.
///
/// Every call is best-effort: without the plugin (tests) or with
/// notifications off, it quietly does nothing.
class DailyReminder {
  DailyReminder._();

  static const _days = 14;
  static const _firstId = 100;
  static const _channelId = 'diary_reminder';

  static final _plugin = FlutterLocalNotificationsPlugin();
  static Future<bool>? _ready;

  /// Called (once ready) when the app is opened from a reminder.
  static VoidCallback? onOpened;

  static Future<bool> _init() => _ready ??= () async {
    try {
      tzdata.initializeTimeZones();
      try {
        final zone = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(zone.identifier));
      } catch (_) {
        // Unknown zone name: UTC times would be off by the offset, but
        // there's nothing better to fall back on.
      }
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification'),
          // Asked for when the reminder is switched on, not at launch.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (_) => onOpened?.call(),
      );
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) onOpened?.call();
      return true;
    } catch (_) {
      // No plugin (tests) or it failed to start — reminders just don't work.
      return false;
    }
  }();

  /// Starts up the plugin (and handles a launch from a reminder).
  static Future<void> init() => _init();

  /// Asks to show notifications; whether they're allowed.
  static Future<bool> requestPermission() async {
    if (!await _init()) return false;
    try {
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) return await ios.requestPermissions(alert: true, sound: true) ?? false;
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) return await android.requestNotificationsPermission() ?? false;
    } on PlatformException {
      return false;
    }
    return false;
  }

  static NotificationDetails _details(String channelName) => NotificationDetails(
    android: AndroidNotificationDetails(_channelId, channelName, importance: Importance.defaultImportance),
    iOS: const DarwinNotificationDetails(),
  );

  /// Shows the reminder right away (debug screen) — asking for permission
  /// first if need be; whether it could.
  static Future<bool> showNow({required String title, required String body, required String channelName}) async {
    if (!await requestPermission()) return false;
    try {
      await _plugin.show(id: _firstId - 1, title: title, body: body, notificationDetails: _details(channelName));
      return true;
    } on PlatformException {
      return false;
    }
  }

  /// How many reminders are scheduled (debug screen); `null` if unknown.
  static Future<int?> pendingCount() async {
    if (!await _init()) return null;
    try {
      return (await _plugin.pendingNotificationRequests()).length;
    } on PlatformException {
      return null;
    }
  }

  /// Replaces the scheduled reminders: daily at [minutes] after midnight,
  /// from today (unless [skipToday], or the time has passed) for the next
  /// [_days] days — or none, when not [enabled].
  static Future<void> schedule({
    required bool enabled,
    required int minutes,
    required bool skipToday,
    required String title,
    required String body,
    required String channelName,
  }) async {
    if (!await _init()) return;
    try {
      for (var i = 0; i < _days; i++) {
        await _plugin.cancel(id: _firstId + i);
      }
      if (!enabled) return;
      final now = tz.TZDateTime.now(tz.local);
      final details = _details(channelName);
      for (var i = 0; i < _days; i++) {
        final at = tz.TZDateTime(tz.local, now.year, now.month, now.day + i, minutes ~/ 60, minutes % 60);
        if (!at.isAfter(now) || (i == 0 && skipToday)) continue;
        await _plugin.zonedSchedule(
          id: _firstId + i,
          scheduledDate: at,
          notificationDetails: details,
          // Within a few minutes is fine for a reminder, and needs no
          // exact-alarm permission on Android.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: title,
          body: body,
        );
      }
    } on PlatformException {
      // Notifications turned off at the system level — nothing to do.
    }
  }
}

/// Keeps the scheduled reminders in step with the app: whenever the
/// setting, today's diary, the language or the date changes — checked on
/// every store change and whenever the app comes back to the foreground.
class ReminderSync with WidgetsBindingObserver {
  final WardrobeStore store;
  String? _scheduled;

  ReminderSync._(this.store);

  /// Starts syncing [store] (once it's loaded), and opens the diary when
  /// the app is opened from a reminder.
  static void start(WardrobeStore store) {
    final sync = ReminderSync._(store);
    DailyReminder.onOpened = () => store.setScreen(WardrobeTabKind.diary);
    store.addListener(sync._sync);
    WidgetsBinding.instance.addObserver(sync);
    sync._sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _sync();
  }

  void _sync() {
    final now = DateTime.now();
    final texts = store.texts;
    final state = [
      store.reminderEnabled,
      store.reminderMinutes,
      store.loggedToday,
      texts.localeName,
      '${now.year}-${now.month}-${now.day}',
    ].join('|');
    if (state == _scheduled) return;
    _scheduled = state;
    unawaited(
      DailyReminder.schedule(
        enabled: store.reminderEnabled,
        minutes: store.reminderMinutes,
        skipToday: store.loggedToday,
        title: texts.reminderTitle,
        body: texts.reminderBody,
        channelName: texts.reminderChannel,
      ),
    );
  }
}
