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
  'renewalRequired': false,
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

const customItem = {
  'id': 'item-test-1',
  'ingredientId': null,
  'isCustom': true,
  'displayName': null,
  'customName': 'Daun fiktif',
  'category': 'spices_aromatics',
  'state': 'out',
  'quantity': null,
  'brand': null,
  'isDefaultStaple': false,
  'usageRank': null,
  'changedAt': '2026-01-01T00:00:00Z',
  'createdAt': '2026-01-01T00:00:00Z',
};

const staple = {
  'id': 'item-test-2',
  'ingredientId': 'fx_smoke_beras',
  'isCustom': false,
  'displayName': {'id': 'Beras fiksi', 'en': 'Fictional rice'},
  'customName': null,
  'category': 'staples',
  'state': 'available',
  'quantity': 'plenty',
  'brand': null,
  'isDefaultStaple': true,
  'usageRank': 1,
  'changedAt': '2026-01-01T00:00:00Z',
  'createdAt': '2026-01-01T00:00:00Z',
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

  final decision = roundTrip(HealthDataConsentDecision(
    decision: ConsentDecision.given,
    textVersion: 'test-v1',
    language: Language.id,
    expectedConsent: ExpectedConsentState(
      status: RulesConsentStatus.none,
      consentRecordId: null,
    ),
  ));
  final expected = decision['expectedConsent'] as Map;
  check(expected['status'] == 'none' && expected.containsKey('consentRecordId') &&
          expected['consentRecordId'] == null,
      'M1 consent precondition encodes, with an explicit null record for none');

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

  // Contract 0.2: Dapur Saya.
  final list = KitchenItemList.fromJson({
    'items': [customItem, staple],
    'maxItems': 500,
    'referenceVersion': null,
  });
  check(list?.items.length == 2, 'KIT-01 kitchen list decodes');
  final custom = list?.items.first;
  check(custom?.ingredientId == null && custom?.isCustom == true && custom?.customName == 'Daun fiktif',
      'KIT-05 custom item has no reference ID and is flagged');
  check(custom?.category == KitchenCategory.spicesAromatics, 'KIT-03 category code decodes');
  check(list?.items.last.isDefaultStaple == true && list?.items.last.state == KitchenItemState.available,
      'KIT-07 default staple decodes as available');

  var unknownStateRejected = false;
  try {
    KitchenItem.fromJson({...customItem, 'state': 'a_state_from_a_newer_server'});
  } on Error {
    unknownStateRejected = true;
  }
  check(unknownStateRejected, 'KIT-02 an unknown item state never decodes as available');

  final toggle = roundTrip(KitchenItemUpdate(state: const Optional.present(KitchenItemState.out_)));
  check(jsonEncode(toggle) == '{"state":"out"}', 'KIT-02 a toggle sends only the state');

  final add = roundTrip(KitchenItemCreate(
    customName: const Optional.present('Daun fiktif'),
    category: const Optional.present(KitchenCategory.spicesAromatics),
  ));
  check(!add.containsKey('ingredientId') && add['category'] == 'spices_aromatics',
      'KIT-05 a custom add leaves the reference ID out');

  final search = IngredientSearchResult.fromJson({
    'referenceVersion': 'TEST-FIXTURE-1@sha256:${'0' * 64}',
    'items': [
      {
        'ingredient': {
          'ingredientId': 'fx_smoke_kemangi',
          'displayName': {'id': 'Kemangi fiksi', 'en': 'Fictional lemon basil'},
          'localNames': ['Selasih fiksi'],
          'category': null,
          'brandVaries': false,
          'brands': <Object>[],
        },
        'matchedName': 'Selasih fiksi',
      },
    ],
  });
  check(search?.items.single.matchedName == 'Selasih fiksi', 'KIT-04 search hit decodes');
  check(search?.items.single.ingredient.category == null,
      'KIT-04 a catalog entry without a kitchen category decodes as null');

  final change = roundTrip(KitchenChange(
    changeId: '00000000-0000-4000-8000-000000000001',
    ingredient: KitchenIngredientKey(ingredientId: const Optional.present('fx_smoke_kemangi')),
    operation: KitchenChangeOperation.upsert,
    ageMs: 1500,
    state: const Optional.present(KitchenItemState.out_),
  ));
  check(change['ageMs'] == 1500 && !change.containsKey('quantity'),
      'KIT-16 a queued change encodes its age and only the fields it changes');

  final recognized = RecognizedItem.fromJson({
    'id': 'rec-test-1',
    'label': 'tempe atau tahu',
    'ingredientId': null,
    'displayName': null,
    'confidence': 'low',
    'options': <Object>[],
    'kitchenItemId': null,
  });
  check(recognized?.confidence == RecognitionConfidence.low, 'REC-03 low confidence decodes');
  check(RecognitionConfidence.fromJson('a_level_from_a_newer_server') == null,
      'REC-02 an unknown confidence is never read as a known level');

  if (failures > 0) {
    stderr.writeln('$failures check(s) failed');
    exit(1);
  }
}
