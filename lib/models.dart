class AdvanceNotice {
  bool enabled;
  int minutesBefore;
  AdvanceNotice({this.enabled = false, this.minutesBefore = 5});

  Map<String, dynamic> toJson() => {'enabled': enabled, 'minutesBefore': minutesBefore};
  factory AdvanceNotice.fromJson(Map<String, dynamic>? j) => AdvanceNotice(
        enabled: j?['enabled'] ?? false,
        minutesBefore: j?['minutesBefore'] ?? 5,
      );
}

class Reminder {
  String id;
  String title;
  String time; // "HH:MM", 24h
  List<int> days; // 0=Sun .. 6=Sat, empty/full = every day
  bool enabled;
  AdvanceNotice advanceNotice;

  Reminder({
    required this.id,
    required this.title,
    required this.time,
    required this.days,
    this.enabled = true,
    AdvanceNotice? advanceNotice,
  }) : advanceNotice = advanceNotice ?? AdvanceNotice();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'time': time,
        'days': days,
        'enabled': enabled,
        'advanceNotice': advanceNotice.toJson(),
      };

  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
        id: j['id'],
        title: j['title'],
        time: j['time'],
        days: List<int>.from(j['days'] ?? const [0, 1, 2, 3, 4, 5, 6]),
        enabled: j['enabled'] ?? true,
        advanceNotice: AdvanceNotice.fromJson(j['advanceNotice']),
      );
}

class TimeReminderSettings {
  bool enabled;
  int intervalMinutes;
  bool voiceAnnouncement;
  bool systemNotification;
  TimeReminderSettings({
    this.enabled = true,
    this.intervalMinutes = 30,
    this.voiceAnnouncement = true,
    this.systemNotification = false,
  });

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'intervalMinutes': intervalMinutes,
        'voiceAnnouncement': voiceAnnouncement,
        'systemNotification': systemNotification,
      };
  factory TimeReminderSettings.fromJson(Map<String, dynamic>? j) => TimeReminderSettings(
        enabled: j?['enabled'] ?? true,
        intervalMinutes: j?['intervalMinutes'] ?? 30,
        voiceAnnouncement: j?['voiceAnnouncement'] ?? true,
        systemNotification: j?['systemNotification'] ?? false,
      );
}

class TtsSettings {
  double rate;
  double pitch;
  double volume;
  TtsSettings({this.rate = 0.5, this.pitch = 1.0, this.volume = 1.0});

  Map<String, dynamic> toJson() => {'rate': rate, 'pitch': pitch, 'volume': volume};
  factory TtsSettings.fromJson(Map<String, dynamic>? j) => TtsSettings(
        rate: (j?['rate'] ?? 0.5).toDouble(),
        pitch: (j?['pitch'] ?? 1.0).toDouble(),
        volume: (j?['volume'] ?? 1.0).toDouble(),
      );
}

class ClockSettings {
  bool showSeconds;
  bool showDate;
  bool showReminders;
  bool showHolidays;
  int hourFormat; // 12 or 24
  String textSize; // normal | large | xlarge
  String theme; // aurora | cyan | amber | minimal

  ClockSettings({
    this.showSeconds = true,
    this.showDate = true,
    this.showReminders = true,
    this.showHolidays = true,
    this.hourFormat = 24,
    this.textSize = 'large',
    this.theme = 'aurora',
  });

  Map<String, dynamic> toJson() => {
        'showSeconds': showSeconds,
        'showDate': showDate,
        'showReminders': showReminders,
        'showHolidays': showHolidays,
        'hourFormat': hourFormat,
        'textSize': textSize,
        'theme': theme,
      };
  factory ClockSettings.fromJson(Map<String, dynamic>? j) => ClockSettings(
        showSeconds: j?['showSeconds'] ?? true,
        showDate: j?['showDate'] ?? true,
        showReminders: j?['showReminders'] ?? true,
        showHolidays: j?['showHolidays'] ?? true,
        hourFormat: j?['hourFormat'] ?? 24,
        textSize: j?['textSize'] ?? 'large',
        theme: j?['theme'] ?? 'aurora',
      );
}

class OtherSettings {
  bool mute;
  bool keepAwake;
  OtherSettings({this.mute = false, this.keepAwake = true});

  Map<String, dynamic> toJson() => {'mute': mute, 'keepAwake': keepAwake};
  factory OtherSettings.fromJson(Map<String, dynamic>? j) => OtherSettings(
        mute: j?['mute'] ?? false,
        keepAwake: j?['keepAwake'] ?? true,
      );
}

class AppSettings {
  String language; // 'en' | 'ar'
  List<Reminder> reminders;
  TimeReminderSettings timeReminder;
  TtsSettings tts;
  ClockSettings clock;
  OtherSettings others;

  AppSettings({
    this.language = 'en',
    List<Reminder>? reminders,
    TimeReminderSettings? timeReminder,
    TtsSettings? tts,
    ClockSettings? clock,
    OtherSettings? others,
  })  : reminders = reminders ?? defaultReminders(),
        timeReminder = timeReminder ?? TimeReminderSettings(),
        tts = tts ?? TtsSettings(),
        clock = clock ?? ClockSettings(),
        others = others ?? OtherSettings();

  static List<Reminder> defaultReminders() => [
        Reminder(id: 'r1', title: 'Morning stand-up', time: '10:00', days: const [0, 1, 2, 3, 4, 5, 6]),
        Reminder(id: 'r2', title: 'Check the news', time: '15:00', days: const [1, 2, 3, 4, 5]),
        Reminder(id: 'r3', title: 'Team meeting', time: '16:20', days: const [1, 2, 3, 4, 5]),
        Reminder(id: 'r4', title: 'Evening walk', time: '21:30', days: const [0, 1, 2, 3, 4, 5, 6]),
      ];

  Map<String, dynamic> toJson() => {
        'language': language,
        'reminders': reminders.map((r) => r.toJson()).toList(),
        'timeReminder': timeReminder.toJson(),
        'tts': tts.toJson(),
        'clock': clock.toJson(),
        'others': others.toJson(),
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        language: j['language'] ?? 'en',
        reminders: (j['reminders'] as List?)
                ?.map((e) => Reminder.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            defaultReminders(),
        timeReminder: TimeReminderSettings.fromJson(j['timeReminder']),
        tts: TtsSettings.fromJson(j['tts']),
        clock: ClockSettings.fromJson(j['clock']),
        others: OtherSettings.fromJson(j['others']),
      );
}
