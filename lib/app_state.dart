import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'models.dart';
import 'i18n.dart';

const _prefsKey = 'talking_clock_settings_v1';

/// Fires once whenever a reminder/announcement goes off, so the clock
/// screen can show a brief on-screen pulse/banner. Kept separate from
/// AppState's own settings-change notifications so a firing reminder
/// doesn't trigger a full settings-dependent rebuild everywhere.
class FireEvent {
  final String id;
  final String title;
  final bool isAdvanceNotice;
  FireEvent({required this.id, required this.title, this.isAdvanceNotice = false});
}

class AppState extends ChangeNotifier {
  AppSettings settings = AppSettings();
  bool loaded = false;

  final FlutterTts _tts = FlutterTts();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  final StreamController<FireEvent> _fireController = StreamController<FireEvent>.broadcast();
  Stream<FireEvent> get fireStream => _fireController.stream;

  final StreamController<void> _tickController = StreamController<void>.broadcast();
  Stream<void> get tickStream => _tickController.stream;

  Timer? _timer;
  final Set<String> _firedThisMinute = {};
  String _lastMinuteMark = '';

  String t(String key) => I18n.t(settings.language, key);

  Future<void> init() async {
    await _loadSettings();
    await _initNotifications();
    await _applyTtsSettings();
    if (settings.others.keepAwake) {
      WakelockPlus.enable();
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    loaded = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fireController.close();
    _tickController.close();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        settings = AppSettings.fromJson(jsonDecode(raw));
      } catch (_) {
        settings = AppSettings();
      }
    }
  }

  Future<void> persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(settings.toJson()));
    notifyListeners();
  }

  Future<void> _initNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _notifications.initialize(initSettings);
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> _applyTtsSettings() async {
    await _tts.setLanguage(settings.language == 'ar' ? 'ar' : 'en-US');
    await _tts.setSpeechRate(settings.tts.rate);
    await _tts.setPitch(settings.tts.pitch);
    await _tts.setVolume(settings.tts.volume);
  }

  Future<void> speak(String text) async {
    if (settings.others.mute) return;
    await _applyTtsSettings();
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> notify(String title, String body) async {
    if (settings.others.mute) return;
    const androidDetails = AndroidNotificationDetails(
      'talking_clock_channel',
      'Talking Clock',
      channelDescription: 'Reminders and time announcements',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _notifications.show(DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body, details);
  }

  Future<void> setKeepAwake(bool value) async {
    settings.others.keepAwake = value;
    if (value) {
      await WakelockPlus.enable();
    } else {
      await WakelockPlus.disable();
    }
    await persist();
  }

  // ---------------- scheduler ----------------

  void _tick() {
    _tickController.add(null);
    final now = DateTime.now();
    final minuteKey = '${now.hour}:${now.minute}';
    if (minuteKey != _lastMinuteMark) {
      _lastMinuteMark = minuteKey;
      _firedThisMinute.clear();
    }

    final hhmm =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final dow = now.weekday % 7; // Dart: Mon=1..Sun=7 -> convert Sun=0..Sat=6

    for (final r in settings.reminders) {
      if (!r.enabled) continue;

      final daysMatch = r.days.isEmpty || r.days.length == 7 || r.days.contains(dow);
      if (r.time == hhmm && daysMatch) {
        final key = 'custom:${r.id}';
        if (!_firedThisMinute.contains(key)) {
          _firedThisMinute.add(key);
          _fireReminder(r);
        }
      }
      if (_isAdvanceNoticeDue(r, now)) {
        final key = 'advance:${r.id}';
        if (!_firedThisMinute.contains(key)) {
          _firedThisMinute.add(key);
          _fireAdvanceNotice(r);
        }
      }
    }

    if (now.second == 0 && settings.timeReminder.enabled) {
      final interval = settings.timeReminder.intervalMinutes.clamp(1, 1440);
      final totalMinutes = now.hour * 60 + now.minute;
      if (totalMinutes % interval == 0) {
        final key = 'periodic:$hhmm';
        if (!_firedThisMinute.contains(key)) {
          _firedThisMinute.add(key);
          _firePeriodicAnnouncement(now);
        }
      }
    }
  }

  static const _weekMinutes = 7 * 1440;
  bool _isAdvanceNoticeDue(Reminder r, DateTime now) {
    final adv = r.advanceNotice;
    if (!adv.enabled) return false;
    final minutesBefore = adv.minutesBefore.clamp(1, 180);

    final parts = r.time.split(':');
    final reminderMinutesOfDay = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    final days = (r.days.isEmpty) ? const [0, 1, 2, 3, 4, 5, 6] : r.days;

    final dow = now.weekday % 7;
    final currentWeekMinute = dow * 1440 + now.hour * 60 + now.minute;

    for (final d in days) {
      final weekMinute = d * 1440 + reminderMinutesOfDay;
      final advanceWeekMinute = (weekMinute - minutesBefore + _weekMinutes) % _weekMinutes;
      if (advanceWeekMinute == currentWeekMinute) return true;
    }
    return false;
  }

  void _fireReminder(Reminder r) {
    notify(r.title, _recurrenceLabel(r));
    speak(r.title);
    _fireController.add(FireEvent(id: r.id, title: r.title));
  }

  void _fireAdvanceNotice(Reminder r) {
    final minutes = r.advanceNotice.minutesBefore;
    final text = '${r.title} in $minutes minute${minutes == 1 ? '' : 's'}';
    notify(t('notify_before'), text);
    speak(text);
    _fireController.add(FireEvent(id: r.id, title: text, isAdvanceNotice: true));
  }

  void _firePeriodicAnnouncement(DateTime now) {
    if (settings.timeReminder.voiceAnnouncement) {
      speak('The time is ${_spokenTime(now)}');
    }
    if (settings.timeReminder.systemNotification) {
      final hh = now.hour.toString().padLeft(2, '0');
      final mm = now.minute.toString().padLeft(2, '0');
      notify(t('app_title'), '$hh:$mm');
    }
  }

  /// Manually fires a reminder right now — used by the "Test" button in
  /// the reminders list, so previewing an alert is a perfect 1:1 match
  /// for what will actually happen when its time comes.
  void testFire(Reminder r) => _fireReminder(r);
  void testAdvance(Reminder r) => _fireAdvanceNotice(r);

  String _recurrenceLabel(Reminder r) {
    const names = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    if (r.days.isEmpty || r.days.length == 7) {
      return '${t('every_day')} ${t('at')} ${r.time}';
    }
    final sorted = [...r.days]..sort();
    return '${t('every_week_on')} ${sorted.map((d) => names[d]).join(', ')} ${t('at')} ${r.time}';
  }

  static const _ones = [
    'zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten',
    'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen'
  ];
  static const _tens = ['', '', 'twenty', 'thirty', 'forty', 'fifty'];

  static String _numberToWords(int n) {
    n = n.clamp(0, 59);
    if (n < 20) return _ones[n];
    final tensPart = n ~/ 10;
    final onesPart = n % 10;
    return _tens[tensPart] + (onesPart != 0 ? '-${_ones[onesPart]}' : '');
  }

  static String _spokenTime(DateTime now) {
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    int h12 = now.hour % 12;
    if (h12 == 0) h12 = 12;
    final hourWord = _numberToWords(h12);
    String minutePhrase;
    if (now.minute == 0) {
      minutePhrase = "o'clock";
    } else if (now.minute < 10) {
      minutePhrase = 'oh ${_numberToWords(now.minute)}';
    } else {
      minutePhrase = _numberToWords(now.minute);
    }
    return '$hourWord $minutePhrase $ampm';
  }

  // ---------------- reminder CRUD ----------------

  Future<void> addReminder(Reminder r) async {
    settings.reminders.add(r);
    await persist();
  }

  Future<void> updateReminder(Reminder r) async {
    final idx = settings.reminders.indexWhere((x) => x.id == r.id);
    if (idx != -1) settings.reminders[idx] = r;
    await persist();
  }

  Future<void> deleteReminder(String id) async {
    settings.reminders.removeWhere((r) => r.id == id);
    await persist();
  }

  Future<void> toggleReminder(String id, bool enabled) async {
    final r = settings.reminders.firstWhere((x) => x.id == id);
    r.enabled = enabled;
    await persist();
  }
}
