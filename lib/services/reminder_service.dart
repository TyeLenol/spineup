import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Small, local-only reminder support for Android.
///
/// SpineUp deliberately keeps this to one daily reminder. It does not create
/// an account, sync anything, or use exact alarms. The preference is scoped to
/// the local session owner and is disabled until the person opts in.
class ReminderSettings {
  final bool enabled;
  final int hour;
  final int minute;

  const ReminderSettings({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  static const defaults = ReminderSettings(enabled: false, hour: 18, minute: 0);

  ReminderSettings copyWith({bool? enabled, int? hour, int? minute}) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }
}

class ReminderService {
  ReminderService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const String _keyPrefix = 'spineup_daily_reminder_';
  static const String _enabledSuffix = '_enabled';
  static const String _hourSuffix = '_hour';
  static const String _minuteSuffix = '_minute';
  static const int _notificationId = 4201;
  static const String _channelId = 'spineup_daily_care';
  static const String _channelName = 'Daily care reminders';
  static const String _channelDescription =
      'A gentle daily reminder to return to your care routine.';

  static bool _initialized = false;
  static Future<void>? _initialization;

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<ReminderSettings> load({required String ownerUserId}) async {
    final prefs = await SharedPreferences.getInstance();
    return ReminderSettings(
      enabled:
          prefs.getBool(_key(ownerUserId, _enabledSuffix)) ??
          ReminderSettings.defaults.enabled,
      hour:
          prefs.getInt(_key(ownerUserId, _hourSuffix)) ??
          ReminderSettings.defaults.hour,
      minute:
          prefs.getInt(_key(ownerUserId, _minuteSuffix)) ??
          ReminderSettings.defaults.minute,
    );
  }

  static Future<bool> enable({
    required String ownerUserId,
    required int hour,
    required int minute,
  }) async {
    if (!isSupported) return false;
    _validateTime(hour, minute);

    final plugin = await _ensureInitialized();
    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final permission = await android?.requestNotificationsPermission();
    if (permission == false) return false;

    await _schedule(plugin, hour: hour, minute: minute);
    await _save(
      ownerUserId,
      ReminderSettings(enabled: true, hour: hour, minute: minute),
    );
    return true;
  }

  static Future<bool> updateTime({
    required String ownerUserId,
    required int hour,
    required int minute,
  }) async {
    if (!isSupported) return false;
    _validateTime(hour, minute);

    final current = await load(ownerUserId: ownerUserId);
    if (!current.enabled) return false;

    final plugin = await _ensureInitialized();
    await _schedule(plugin, hour: hour, minute: minute);
    await _save(ownerUserId, current.copyWith(hour: hour, minute: minute));
    return true;
  }

  static Future<void> disable({required String ownerUserId}) async {
    if (isSupported) {
      final plugin = await _ensureInitialized();
      await plugin.cancel(id: _notificationId);
    }

    final current = await load(ownerUserId: ownerUserId);
    await _save(ownerUserId, current.copyWith(enabled: false));
  }

  static Future<void> clear({required String ownerUserId}) async {
    if (isSupported) {
      final plugin = await _ensureInitialized();
      await plugin.cancel(id: _notificationId);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(ownerUserId, _enabledSuffix));
    await prefs.remove(_key(ownerUserId, _hourSuffix));
    await prefs.remove(_key(ownerUserId, _minuteSuffix));
  }

  static Future<void> _schedule(
    FlutterLocalNotificationsPlugin plugin, {
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: 'ic_launcher',
        playSound: false,
        enableVibration: false,
      ),
    );

    await plugin.zonedSchedule(
      id: _notificationId,
      title: 'A small care moment',
      body: 'Your SpineUp space is here when you are ready.',
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'spineup_daily_reminder',
    );
  }

  static Future<void> _save(
    String ownerUserId,
    ReminderSettings settings,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(ownerUserId, _enabledSuffix), settings.enabled);
    await prefs.setInt(_key(ownerUserId, _hourSuffix), settings.hour);
    await prefs.setInt(_key(ownerUserId, _minuteSuffix), settings.minute);
  }

  static String _key(String ownerUserId, String suffix) =>
      '$_keyPrefix$ownerUserId$suffix';

  static void _validateTime(int hour, int minute) {
    if (hour < 0 || hour > 23) {
      throw ArgumentError.value(hour, 'hour', 'must be between 0 and 23');
    }
    if (minute < 0 || minute > 59) {
      throw ArgumentError.value(minute, 'minute', 'must be between 0 and 59');
    }
  }

  static Future<FlutterLocalNotificationsPlugin> _ensureInitialized() async {
    if (!_initialized) {
      await (_initialization ??= _initialize());
    }
    return _plugin;
  }

  static Future<void> _initialize() async {
    try {
      tz.initializeTimeZones();
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));

      const settings = InitializationSettings(
        android: AndroidInitializationSettings('ic_launcher'),
      );
      await _plugin.initialize(settings: settings);
      _initialized = true;
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }
}
