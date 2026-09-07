import 'package:flutter/material.dart';
import 'app_state.dart';
import 'models.dart';
import 'themes.dart';

Future<void> showReminderDialog(BuildContext context, AppState app, {Reminder? existing}) {
  final palette = appPalettes[app.settings.clock.theme]!;
  final titleCtrl = TextEditingController(text: existing?.title ?? '');
  TimeOfDay time = existing != null
      ? TimeOfDay(
          hour: int.parse(existing.time.split(':')[0]),
          minute: int.parse(existing.time.split(':')[1]))
      : const TimeOfDay(hour: 9, minute: 0);
  Set<int> days = (existing?.days.isNotEmpty ?? false)
      ? existing!.days.toSet()
      : {0, 1, 2, 3, 4, 5, 6};
  bool enabled = existing?.enabled ?? true;
  bool advanceEnabled = existing?.advanceNotice.enabled ?? false;
  int advanceMinutes = existing?.advanceNotice.minutesBefore ?? 5;
  String? titleError;

  final dayKeys = ['day_sun', 'day_mon', 'day_tue', 'day_wed', 'day_thu', 'day_fri', 'day_sat'];

  return showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          backgroundColor: const Color(0xFF12121E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            existing == null ? app.t('modal_add_title') : app.t('modal_edit_title'),
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.t('title_label'), style: const TextStyle(color: Color(0xFF93A4C9), fontSize: 13)),
                const SizedBox(height: 4),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: app.t('title_placeholder'),
                    hintStyle: const TextStyle(color: Color(0xFF6B6B7A)),
                    errorText: titleError,
                    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0x33FFFFFF))),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: palette.accent)),
                  ),
                ),
                const SizedBox(height: 14),
                Text(app.t('time_label'), style: const TextStyle(color: Color(0xFF93A4C9), fontSize: 13)),
                const SizedBox(height: 4),
                OutlinedButton(
                  onPressed: () async {
                    final picked = await showTimePicker(context: ctx, initialTime: time);
                    if (picked != null) setState(() => time = picked);
                  },
                  child: Text(
                    time.format(ctx),
                    style: TextStyle(color: palette.accent),
                  ),
                ),
                const SizedBox(height: 14),
                Text(app.t('repeat_on'), style: const TextStyle(color: Color(0xFF93A4C9), fontSize: 13)),
                Wrap(
                  spacing: 6,
                  children: List.generate(7, (i) {
                    final selected = days.contains(i);
                    return FilterChip(
                      label: Text(app.t(dayKeys[i]), style: TextStyle(fontSize: 12, color: selected ? Colors.black : Colors.white70)),
                      selected: selected,
                      selectedColor: palette.accent,
                      backgroundColor: const Color(0x1AFFFFFF),
                      onSelected: (v) => setState(() => v ? days.add(i) : days.remove(i)),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: palette.accent,
                  title: Text(app.t('enable'), style: const TextStyle(color: Colors.white, fontSize: 14)),
                  value: enabled,
                  onChanged: (v) => setState(() => enabled = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: palette.accent,
                  title: Text(app.t('notify_before'), style: const TextStyle(color: Colors.white, fontSize: 14)),
                  value: advanceEnabled,
                  onChanged: (v) => setState(() => advanceEnabled = v),
                ),
                if (advanceEnabled)
                  Row(
                    children: [
                      SizedBox(
                        width: 70,
                        child: TextFormField(
                          initialValue: advanceMinutes.toString(),
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0x33FFFFFF))),
                          ),
                          onChanged: (v) {
                            final n = int.tryParse(v);
                            if (n != null) advanceMinutes = n.clamp(1, 180);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(app.t('minutes_before'), style: const TextStyle(color: Color(0xFF93A4C9))),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(app.t('cancel'), style: const TextStyle(color: Color(0xFF93A4C9))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: palette.accent, foregroundColor: Colors.black),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) {
                  setState(() => titleError = app.t('title_error'));
                  return;
                }
                final hh = time.hour.toString().padLeft(2, '0');
                final mm = time.minute.toString().padLeft(2, '0');
                final reminder = Reminder(
                  id: existing?.id ?? 'r${DateTime.now().millisecondsSinceEpoch}',
                  title: titleCtrl.text.trim(),
                  time: '$hh:$mm',
                  days: days.toList(),
                  enabled: enabled,
                  advanceNotice: AdvanceNotice(enabled: advanceEnabled, minutesBefore: advanceMinutes),
                );
                if (existing == null) {
                  await app.addReminder(reminder);
                } else {
                  await app.updateReminder(reminder);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(app.t('save')),
            ),
          ],
        );
      });
    },
  );
}
