import 'CountryData/country_catalog.dart';

/// "Good morning / afternoon / evening" for the home headers.
///
/// US accounts get US time: the phone's own clock when the phone is set to
/// a US time zone (UTC-4 to UTC-10), otherwise US Eastern Time (with
/// daylight saving), so a US account shows the US greeting even on a phone
/// set to another country's time. Other countries use the phone's clock.
String timeGreeting([DateTime? nowUtc]) {
  final utc = (nowUtc ?? DateTime.now()).toUtc();
  final hour = _isUsAccount ? _usHour(utc) : utc.toLocal().hour;
  if (hour < 12) return 'Good morning,';
  if (hour < 17) return 'Good afternoon,';
  return 'Good evening,';
}

bool get _isUsAccount => CountryCatalog.selected.name == 'United States';

int _usHour(DateTime utc) {
  final local = utc.toLocal();
  final offsetHours = local.timeZoneOffset.inHours;
  if (offsetHours <= -4 && offsetHours >= -10) return local.hour;
  return utc.add(Duration(hours: _easternOffset(utc))).hour;
}

/// US Eastern offset from UTC: -4 during daylight saving (second Sunday of
/// March 2:00 to first Sunday of November 2:00, local), otherwise -5.
int _easternOffset(DateTime utc) {
  final year = utc.year;
  DateTime nthSunday(int month, int n) {
    var d = DateTime.utc(year, month, 1);
    while (d.weekday != DateTime.sunday) {
      d = d.add(const Duration(days: 1));
    }
    return d.add(Duration(days: 7 * (n - 1)));
  }

  // 2:00 local = 7:00 UTC in March (EST), 6:00 UTC in November (EDT).
  final dstStart = nthSunday(3, 2).add(const Duration(hours: 7));
  final dstEnd = nthSunday(11, 1).add(const Duration(hours: 6));
  return (utc.isAfter(dstStart) && utc.isBefore(dstEnd)) ? -4 : -5;
}
