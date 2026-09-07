import 'package:flutter/material.dart';
import 'app_state.dart';
import 'models.dart';
import 'themes.dart';
import 'reminder_dialog.dart';

class SettingsScreen extends StatefulWidget {
  final AppState app;
  const SettingsScreen({super.key, required this.app});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final palette = appPalettes[app.settings.clock.theme]!;
    final isAr = app.settings.language == 'ar';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: AnimatedBuilder(
        animation: app,
        builder: (context, _) {
          return Scaffold(
            backgroundColor: const Color(0xFF0E0E18),
            appBar: AppBar(
              backgroundColor: const Color(0xFF0E0E18),
              elevation: 0,
              title: Text(app.t('settings')),
              bottom: TabBar(
                controller: _tabs,
                isScrollable: true,
                indicatorColor: palette.accent,
                labelColor: palette.accent,
                unselectedLabelColor: Colors.white54,
                tabs: [
                  Tab(text: app.t('tab_reminders')),
                  Tab(text: app.t('tab_time_reminder')),
                  Tab(text: app.t('tab_voice')),
                  Tab(text: app.t('tab_display')),
                  Tab(text: app.t('tab_others')),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabs,
              children: [
                _RemindersTab(app: app, palette: palette),
                _TimeReminderTab(app: app),
                _VoiceTab(app: app),
                _DisplayTab(app: app, palette: palette),
                _OthersTab(app: app),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(text.toUpperCase(),
            style: const TextStyle(color: Color(0xFF93A4C9), fontSize: 12, letterSpacing: 1.1)),
      );
}

class _RemindersTab extends StatelessWidget {
  final AppState app;
  final AppPalette palette;
  const _RemindersTab({required this.app, required this.palette});

  @override
  Widget build(BuildContext context) {
    final reminders = app.settings.reminders;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: reminders.isEmpty
                ? Center(child: Text(app.t('no_reminders_today'), style: const TextStyle(color: Colors.white54)))
                : ListView.separated(
                    itemCount: reminders.length,
                    separatorBuilder: (_, __) => const Divider(color: Color(0x1AFFFFFF)),
                    itemBuilder: (ctx, i) {
                      final r = reminders[i];
                      return ListTile(
                        title: Text(r.title, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(r.time, style: const TextStyle(color: Color(0xFF93A4C9))),
                        leading: Switch(
                          value: r.enabled,
                          activeColor: palette.accent,
                          onChanged: (v) => app.toggleReminder(r.id, v),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_active, color: Colors.white54, size: 20),
                              tooltip: app.t('test'),
                              onPressed: () => app.testFire(r),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white54, size: 20),
                              onPressed: () => showReminderDialog(context, app, existing: r),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                              onPressed: () => app.deleteReminder(r.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: palette.accent, foregroundColor: Colors.black),
              onPressed: () => showReminderDialog(context, app),
              child: Text(app.t('add_reminder_btn')),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeReminderTab extends StatelessWidget {
  final AppState app;
  const _TimeReminderTab({required this.app});

  @override
  Widget build(BuildContext context) {
    final tr = app.settings.timeReminder;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SwitchListTile(
          title: Text(app.t('enable'), style: const TextStyle(color: Colors.white)),
          value: tr.enabled,
          onChanged: (v) { tr.enabled = v; app.persist(); },
        ),
        const _SectionTitle('announce_interval'),
        Row(
          children: [
            SizedBox(
              width: 90,
              child: TextFormField(
                initialValue: tr.intervalMinutes.toString(),
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onChanged: (v) {
                  final n = int.tryParse(v);
                  if (n != null) { tr.intervalMinutes = n.clamp(1, 1440); app.persist(); }
                },
              ),
            ),
            const SizedBox(width: 10),
            Text(app.t('minutes'), style: const TextStyle(color: Colors.white70)),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(app.t('interval_hint'), style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ),
        const _SectionTitle('actions'),
        SwitchListTile(
          title: Text(app.t('voice_announcement'), style: const TextStyle(color: Colors.white)),
          value: tr.voiceAnnouncement,
          onChanged: (v) { tr.voiceAnnouncement = v; app.persist(); },
        ),
        SwitchListTile(
          title: Text(app.t('system_notification'), style: const TextStyle(color: Colors.white)),
          value: tr.systemNotification,
          onChanged: (v) { tr.systemNotification = v; app.persist(); },
        ),
      ],
    );
  }
}

class _VoiceTab extends StatelessWidget {
  final AppState app;
  const _VoiceTab({required this.app});

  @override
  Widget build(BuildContext context) {
    final tts = app.settings.tts;
    final testCtrl = TextEditingController();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(app.t('rate'), style: const TextStyle(color: Color(0xFF93A4C9))),
        Slider(
          value: tts.rate, min: 0.1, max: 1.0,
          onChanged: (v) { tts.rate = v; app.persist(); },
        ),
        Text(app.t('pitch'), style: const TextStyle(color: Color(0xFF93A4C9))),
        Slider(
          value: tts.pitch, min: 0.5, max: 2.0,
          onChanged: (v) { tts.pitch = v; app.persist(); },
        ),
        Text(app.t('volume'), style: const TextStyle(color: Color(0xFF93A4C9))),
        Slider(
          value: tts.volume, min: 0.0, max: 1.0,
          onChanged: (v) { tts.volume = v; app.persist(); },
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: testCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(hintText: app.t('test_voice_placeholder'), hintStyle: const TextStyle(color: Colors.white38)),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => app.speak(testCtrl.text.isEmpty ? 'This is a test' : testCtrl.text),
              child: Text(app.t('test_voice')),
            ),
          ],
        ),
      ],
    );
  }
}

class _DisplayTab extends StatelessWidget {
  final AppState app;
  final AppPalette palette;
  const _DisplayTab({required this.app, required this.palette});

  @override
  Widget build(BuildContext context) {
    final clock = app.settings.clock;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _SectionTitle('language'),
        RadioListTile<String>(
          value: 'en',
          groupValue: app.settings.language,
          activeColor: palette.accent,
          title: Text(app.t('lang_en'), style: const TextStyle(color: Colors.white)),
          onChanged: (v) { app.settings.language = v!; app.persist(); },
        ),
        RadioListTile<String>(
          value: 'ar',
          groupValue: app.settings.language,
          activeColor: palette.accent,
          title: Text(app.t('lang_ar'), style: const TextStyle(color: Colors.white)),
          onChanged: (v) { app.settings.language = v!; app.persist(); },
        ),
        const _SectionTitle('color_theme'),
        Wrap(
          spacing: 14,
          children: appPalettes.values.map((p) {
            final selected = clock.theme == p.id;
            final labelKey = 'theme_${p.id}';
            return GestureDetector(
              onTap: () { clock.theme = p.id; app.persist(); },
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [p.accent, p.accent2]),
                      border: selected ? Border.all(color: Colors.white, width: 2) : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(app.t(labelKey), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            );
          }).toList(),
        ),
        const _SectionTitle('display'),
        SwitchListTile(
          title: Text(app.t('display_seconds'), style: const TextStyle(color: Colors.white)),
          value: clock.showSeconds,
          activeColor: palette.accent,
          onChanged: (v) { clock.showSeconds = v; app.persist(); },
        ),
        SwitchListTile(
          title: Text(app.t('display_date'), style: const TextStyle(color: Colors.white)),
          value: clock.showDate,
          activeColor: palette.accent,
          onChanged: (v) { clock.showDate = v; app.persist(); },
        ),
        SwitchListTile(
          title: Text(app.t('display_reminders'), style: const TextStyle(color: Colors.white)),
          value: clock.showReminders,
          activeColor: palette.accent,
          onChanged: (v) { clock.showReminders = v; app.persist(); },
        ),
        SwitchListTile(
          title: Text(app.t('display_holidays'), style: const TextStyle(color: Colors.white)),
          value: clock.showHolidays,
          activeColor: palette.accent,
          onChanged: (v) { clock.showHolidays = v; app.persist(); },
        ),
        const _SectionTitle('text_size'),
        ...['normal', 'large', 'xlarge'].map((size) => RadioListTile<String>(
              value: size,
              groupValue: clock.textSize,
              activeColor: palette.accent,
              title: Text(app.t('size_$size'), style: const TextStyle(color: Colors.white)),
              onChanged: (v) { clock.textSize = v!; app.persist(); },
            )),
        const _SectionTitle('hour_format'),
        RadioListTile<int>(
          value: 12,
          groupValue: clock.hourFormat,
          activeColor: palette.accent,
          title: Text(app.t('hour_12'), style: const TextStyle(color: Colors.white)),
          onChanged: (v) { clock.hourFormat = v!; app.persist(); },
        ),
        RadioListTile<int>(
          value: 24,
          groupValue: clock.hourFormat,
          activeColor: palette.accent,
          title: Text(app.t('hour_24'), style: const TextStyle(color: Colors.white)),
          onChanged: (v) { clock.hourFormat = v!; app.persist(); },
        ),
      ],
    );
  }
}

class _OthersTab extends StatelessWidget {
  final AppState app;
  const _OthersTab({required this.app});

  @override
  Widget build(BuildContext context) {
    final others = app.settings.others;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SwitchListTile(
          title: Text(app.t('mute_all'), style: const TextStyle(color: Colors.white)),
          value: others.mute,
          onChanged: (v) { others.mute = v; app.persist(); },
        ),
        SwitchListTile(
          title: Text(app.t('keep_awake'), style: const TextStyle(color: Colors.white)),
          value: others.keepAwake,
          onChanged: (v) => app.setKeepAwake(v),
        ),
      ],
    );
  }
}
