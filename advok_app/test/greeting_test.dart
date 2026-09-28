import 'package:advok_app/Utils/CountryData/country_catalog.dart';
import 'package:advok_app/Utils/greeting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('US account uses US Eastern time on a non-US phone', () {
    CountryCatalog.select('United States');
    // 12:30 UTC on 28 Sep (EDT, UTC-4) = 8:30 AM New York.
    expect(timeGreeting(DateTime.utc(2026, 9, 28, 12, 30)), 'Good morning,');
    // 18:00 UTC = 2 PM New York.
    expect(timeGreeting(DateTime.utc(2026, 9, 28, 18)), 'Good afternoon,');
    // 23:30 UTC = 7:30 PM New York.
    expect(timeGreeting(DateTime.utc(2026, 9, 28, 23, 30)), 'Good evening,');
    // January (EST, UTC-5): 16:30 UTC = 11:30 AM New York.
    expect(timeGreeting(DateTime.utc(2026, 1, 15, 16, 30)), 'Good morning,');
  });
}
