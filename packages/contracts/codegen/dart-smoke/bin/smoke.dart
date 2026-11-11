// TEST FIXTURE: not real safety or nutrition data. Fictional IDs and names.
//
// Decodes and encodes contract-shaped JSON with the generated Dart client to
// prove it compiles and behaves as the mobile app expects.
import 'dart:convert';
import 'dart:io';

import 'package:keluargamakan_api/api.dart';

var failures = 0;

void check(bool ok, String what) {
  if (ok) {
    stdout.writeln('ok    $what');
  } else {
    stderr.writeln('FAIL  $what');
    failures++;
  }
}

Map<String, dynamic> roundTrip(Object value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

const consentState = {
  'status': 'declined',
  'consentRecordId': 'consent-test-1',
  'decidedAt': '2026-01-01T00:00:00Z',
  'textVersion': 'test-v1',
  'deletionDueBy': null,
};

const childProfile = {
  'id': 'profile-test-1',
  'name': 'Adik',
  'avatar': {'style': 'initials', 'colorToken': 'avatar_1', 'illustrationId': null},
  'ageGroup': 'child',
  'isChild': true,
  'isManager': false,
  'guardianConfirmation': {
    'consentRecordId': 'consent-test-0',
    'confirmedAt': '2026-01-01T00:00:00Z',
    'textVersion': 'test-v1',
  },
  'portions': {
    'portionSize': 'small',
    'portionSizeIsDefault': true,
    'ricePortion': 'small',
    'ricePortionIsDefault': true,
  },
  'rules': {'consent': consentState, 'items': <Object>[]},
  'preferences': {
    'spiceLevel': null,
    'lessOf': ['santan'],
    'textures': <Object>[],
    'updatedAt': null,
  },
  'likesDislikes': {'likes': <Object>[], 'dislikes': <Object>[], 'updatedAt': null},
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
};

void main() {
  final profile = Profile.fromJson(childProfile);
  check(profile != null, 'Profile decodes');
  check(profile?.isChild == true, 'PRF-18 child flag decodes');
  check(profile?.ageGroup == AgeGroup.child, 'PRF-01 age group decodes');
  check(profile?.rules.consent.status == RulesConsentStatus.declined,
      'ACC-08 declined consent state decodes');
  check(profile?.rules.items.isEmpty == true, 'declined consent has no rules');
  check(profile?.preferences.spiceLevel == null, 'PRF-05 unset spice level is null');

  final rule = HardRule.fromJson({
    'id': 'rule-test-1',
    'type': 'free_text',
    'allergen': null,
    'freeText': 'contoh bahan fiktif',
    'mapping': {
      'status': 'unmapped',
      'ingredients': <Object>[],
      'confirmedBy': null,
      'updatedAt': '2026-01-01T00:00:00Z',
    },
    'createdAt': '2026-01-01T00:00:00Z',
  });
  check(rule?.mapping?.status == MappingStatus.unmapped, 'PRF-08 mapping status decodes');

  // Fail closed: an unknown value in a required enum field must not decode to
  // any known value. The generated client throws, and the app shows an error.
  var unknownRejected = false;
  try {
    HardRule.fromJson({
      'id': 'rule-test-2',
      'type': 'a_type_from_a_newer_server',
      'allergen': null,
      'freeText': null,
      'mapping': null,
      'createdAt': '2026-01-01T00:00:00Z',
    });
  } on Error {
    unknownRejected = true;
  }
  check(unknownRejected, 'unknown value in a required enum fails to decode');
  check(RulesConsentStatus.fromJson('a_state_from_a_newer_server') == null,
      'unknown enum value is never mapped to a known value');

  final create = roundTrip(ProfileCreate(
    name: 'Kakak',
    ageGroup: AgeGroup.teen,
    guardianConfirmation: Optional.present(GuardianConfirmationInput(
      confirmed: true,
      textVersion: 'test-v1',
      language: Language.id,
    )),
  ));
  check(!create.containsKey('avatar'), 'absent optional field is omitted, not sent as null');
  check(create['ageGroup'] == 'teen', 'enum encodes to its wire value');
  check((create['guardianConfirmation'] as Map)['confirmed'] == true,
      'SET-10 guardian confirmation encodes');

  final update = roundTrip(HouseholdUpdate(city: const Optional.present(null)));
  check(jsonEncode(update) == '{"city":null}', 'PATCH sends only present fields; null clears');

  final problem = Problem.fromJson({
    'type': 'urn:keluargamakan:problem:consent_required',
    'title': 'Consent required',
    'status': 409,
    'code': 'consent_required',
    'requestId': 'req-test-1',
  });
  check(problem?.code == ErrorCode.consentRequired, 'error model decodes the stable code');

  if (failures > 0) {
    stderr.writeln('$failures check(s) failed');
    exit(1);
  }
}
