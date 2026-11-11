import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:keluargamakan/core/time/household_time.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id');
    await initializeDateFormatting('en');
  });

  group('NFR-16 dates and times in the household time zone', () {
    final instant = DateTime.utc(2026, 11, 10, 9);

    test('NFR-16 WIB, WITA and WIT are UTC+7, +8 and +9', () {
      expect(HouseholdTimeZone.wib.utcOffset, const Duration(hours: 7));
      expect(HouseholdTimeZone.wita.utcOffset, const Duration(hours: 8));
      expect(HouseholdTimeZone.wit.utcOffset, const Duration(hours: 9));
    });

    test('NFR-16 the same instant shows each zone\'s wall-clock time', () {
      String idTime(HouseholdTimeZone zone) =>
          HouseholdDateFormatter(zone)
              .time(instant, 'id', use24HourFormat: false);
      expect(idTime(HouseholdTimeZone.wib), '16.00');
      expect(idTime(HouseholdTimeZone.wita), '17.00');
      expect(idTime(HouseholdTimeZone.wit), '18.00');
    });

    test('NFR-16 Bahasa Indonesia uses 24-hour "16.00"; English follows the '
        'device clock', () {
      const f = HouseholdDateFormatter(HouseholdTimeZone.wib);
      expect(f.time(instant, 'id', use24HourFormat: false), '16.00');
      expect(f.time(instant, 'en', use24HourFormat: true), '16:00');
      expect(f.time(instant, 'en', use24HourFormat: false), '4:00 PM');
    });

    test('NFR-16 dates read "10 Nov 2026" and roll over at local midnight', () {
      const wib = HouseholdDateFormatter(HouseholdTimeZone.wib);
      const wit = HouseholdDateFormatter(HouseholdTimeZone.wit);
      expect(wib.date(instant, 'id'), '10 Nov 2026');
      expect(wib.date(instant, 'en'), '10 Nov 2026');

      final lateUtc = DateTime.utc(2026, 11, 10, 15, 30);
      expect(wib.date(lateUtc, 'id'), '10 Nov 2026'); // 22.30 WIB
      expect(wit.date(lateUtc, 'id'), '11 Nov 2026'); // 00.30 WIT
      expect(wit.time(lateUtc, 'id', use24HourFormat: true), '00.30');
    });

    test('NFR-16 device offsets map to the matching zone, else WIB', () {
      expect(
        HouseholdTimeZone.fromOffset(const Duration(hours: 8)),
        HouseholdTimeZone.wita,
      );
      expect(
        HouseholdTimeZone.fromOffset(const Duration(hours: 9)),
        HouseholdTimeZone.wit,
      );
      expect(
        HouseholdTimeZone.fromOffset(Duration.zero),
        HouseholdTimeZone.wib,
      );
    });
  });
}
