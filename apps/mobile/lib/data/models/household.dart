import 'package:flutter/foundation.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../../core/time/household_time.dart';
import 'sourced.dart';

/// The household (contract `Household`, ACC-03).
@immutable
final class HouseholdInfo {
  const HouseholdInfo({
    required this.id,
    required this.name,
    required this.city,
    required this.timeZoneName,
    required this.language,
    required this.managerAccountId,
    required this.managerProfileId,
    required this.updatedAt,
    required this.source,
  });

  final String id;
  final String? name;
  final String? city;

  /// The IANA name as stored on the server.
  final String timeZoneName;

  /// Household language. Which language wins on a new phone is open
  /// (QUESTIONS #57); the app language stays the phone's choice for now.
  final api.Language language;
  final String managerAccountId;
  final String managerProfileId;
  final DateTime updatedAt;
  final DataSource source;

  /// WIB, WITA or WIT; any other IANA name is WIB (PR #6 review F4).
  HouseholdTimeZone get timeZone => HouseholdTimeZone.fromIana(timeZoneName);

  @override
  String toString() => 'HouseholdInfo($id)';
}

/// The standard allergen list in display order (PRF-04). Codes this app
/// version does not know are left out by the generated decoder, so the
/// picker never shows them.
@immutable
final class AllergenReference {
  const AllergenReference({
    required this.ruleSetVersion,
    required this.items,
    required this.source,
  });

  final String ruleSetVersion;
  final List<api.StandardAllergen> items;
  final DataSource source;
}
