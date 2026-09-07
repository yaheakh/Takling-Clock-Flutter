class JordanHoliday {
  final DateTime date;
  final String nameEn;
  final String nameAr;
  const JordanHoliday(this.date, this.nameEn, this.nameAr);
}

/// Official Jordan public holidays. Islamic-calendar holidays (Eid
/// al-Fitr, Eid al-Adha, Islamic New Year, the Prophet's Birthday) shift
/// every year based on moon sightings, so they're a hand-maintained
/// per-year table rather than computed — add a new year's dates here
/// once they're officially announced/published.
final List<JordanHoliday> jordanHolidays = [
  // ---- 2026 ----
  JordanHoliday(DateTime(2026, 1, 1), "New Year's Day", 'رأس السنة الميلادية'),
  JordanHoliday(DateTime(2026, 3, 20), 'Eid al-Fitr', 'عيد الفطر'),
  JordanHoliday(DateTime(2026, 3, 21), 'Eid al-Fitr Holiday', 'عطلة عيد الفطر'),
  JordanHoliday(DateTime(2026, 3, 22), 'Eid al-Fitr Holiday', 'عطلة عيد الفطر'),
  JordanHoliday(DateTime(2026, 3, 23), 'Eid al-Fitr Holiday', 'عطلة عيد الفطر'),
  JordanHoliday(DateTime(2026, 5, 1), 'Labour Day', 'عيد العمال'),
  JordanHoliday(DateTime(2026, 5, 25), 'Independence Day', 'عيد الاستقلال'),
  JordanHoliday(DateTime(2026, 5, 26), 'Arafat Day', 'يوم عرفة'),
  JordanHoliday(DateTime(2026, 5, 27), 'Eid al-Adha', 'عيد الأضحى'),
  JordanHoliday(DateTime(2026, 5, 28), 'Eid al-Adha Holiday', 'عطلة عيد الأضحى'),
  JordanHoliday(DateTime(2026, 5, 29), 'Eid al-Adha Holiday', 'عطلة عيد الأضحى'),
  JordanHoliday(DateTime(2026, 5, 30), 'Eid al-Adha Holiday', 'عطلة عيد الأضحى'),
  JordanHoliday(DateTime(2026, 6, 16), 'Islamic New Year', 'رأس السنة الهجرية'),
  JordanHoliday(DateTime(2026, 8, 25), "Prophet Muhammad's Birthday", 'المولد النبوي الشريف'),
  JordanHoliday(DateTime(2026, 12, 25), 'Christmas Day', 'عيد الميلاد المجيد'),

  // ---- 2027 (Islamic dates tentative, pending moon-sighting confirmation) ----
  JordanHoliday(DateTime(2027, 1, 1), "New Year's Day", 'رأس السنة الميلادية'),
  JordanHoliday(DateTime(2027, 3, 9), 'Eid al-Fitr', 'عيد الفطر'),
  JordanHoliday(DateTime(2027, 3, 10), 'Eid al-Fitr Holiday', 'عطلة عيد الفطر'),
  JordanHoliday(DateTime(2027, 3, 11), 'Eid al-Fitr Holiday', 'عطلة عيد الفطر'),
  JordanHoliday(DateTime(2027, 3, 12), 'Eid al-Fitr Holiday', 'عطلة عيد الفطر'),
  JordanHoliday(DateTime(2027, 5, 1), 'Labour Day', 'عيد العمال'),
  JordanHoliday(DateTime(2027, 5, 15), 'Arafat Day', 'يوم عرفة'),
  JordanHoliday(DateTime(2027, 5, 16), 'Eid al-Adha', 'عيد الأضحى'),
  JordanHoliday(DateTime(2027, 5, 17), 'Eid al-Adha Holiday', 'عطلة عيد الأضحى'),
  JordanHoliday(DateTime(2027, 5, 18), 'Eid al-Adha Holiday', 'عطلة عيد الأضحى'),
  JordanHoliday(DateTime(2027, 5, 19), 'Eid al-Adha Holiday', 'عطلة عيد الأضحى'),
  JordanHoliday(DateTime(2027, 5, 25), 'Independence Day', 'عيد الاستقلال'),
  JordanHoliday(DateTime(2027, 6, 6), 'Islamic New Year', 'رأس السنة الهجرية'),
  JordanHoliday(DateTime(2027, 8, 14), "Prophet Muhammad's Birthday", 'المولد النبوي الشريف'),
  JordanHoliday(DateTime(2027, 12, 25), 'Christmas Day', 'عيد الميلاد المجيد'),
];

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

JordanHoliday? holidayOn(DateTime day) {
  for (final h in jordanHolidays) {
    if (_sameDate(h.date, day)) return h;
  }
  return null;
}

JordanHoliday? nextHolidayAfter(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  for (final h in jordanHolidays) {
    if (h.date.isAfter(today)) return h;
  }
  return null;
}
