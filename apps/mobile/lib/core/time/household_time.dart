// Dates and times in the household's time zone (NFR-16).
//
// Indonesia has three zones with fixed offsets and no daylight saving time,
// so a fixed UTC offset is exact. The household's zone will come from the
// account (API); until then it is derived from the device offset.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

enum HouseholdTimeZone {
  /// Waktu Indonesia Barat, UTC+7.
  wib(Duration(hours: 7)),

  /// Waktu Indonesia Tengah, UTC+8.
  wita(Duration(hours: 8)),

  /// Waktu Indonesia Timur, UTC+9.
  wit(Duration(hours: 9));

  const HouseholdTimeZone(this.utcOffset);

  final Duration utcOffset;

  /// The zone matching a device offset, or WIB when the device is not on an
  /// Indonesian offset.
  static HouseholdTimeZone fromOffset(Duration offset) =>
      values.firstWhere((zone) => zone.utcOffset == offset, orElse: () => wib);
}

/// Formats instants as the household sees them.
final class HouseholdDateFormatter {
  const HouseholdDateFormatter(this.zone);

  final HouseholdTimeZone zone;

  /// Wall-clock time in the household zone. The result's fields are local
  /// to the household; do not compare it with real instants.
  DateTime toHouseholdWallClock(DateTime instant) =>
      instant.toUtc().add(zone.utcOffset);

  /// "10 Nov 2026" in both languages (copy README 1).
  String date(DateTime instant, String languageCode) =>
      DateFormat('d MMM y', languageCode).format(toHouseholdWallClock(instant));

  /// "16.00" in Bahasa Indonesia; the device clock format in English.
  String time(
    DateTime instant,
    String languageCode, {
    required bool use24HourFormat,
  }) {
    final pattern = languageCode == 'id'
        ? 'HH.mm'
        : (use24HourFormat ? 'HH:mm' : 'h:mm a');
    return DateFormat(
      pattern,
      languageCode,
    ).format(toHouseholdWallClock(instant));
  }
}

final householdTimeZoneProvider = Provider<HouseholdTimeZone>(
  (ref) => HouseholdTimeZone.fromOffset(DateTime.now().timeZoneOffset),
);

final householdDateFormatterProvider = Provider<HouseholdDateFormatter>(
  (ref) => HouseholdDateFormatter(ref.watch(householdTimeZoneProvider)),
);
