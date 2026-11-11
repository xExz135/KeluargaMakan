// TEST FIXTURE: not real safety or nutrition data.
//
// Contract-shaped JSON (packages/contracts/openapi.yaml v0.1) and a test
// container wired to a MockClient. Names, IDs and rules are invented for
// tests only.

import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:keluargamakan_api/api.dart' as api;
import 'package:keluargamakan/core/api/api_client.dart';
import 'package:keluargamakan/core/api/api_result.dart';
import 'package:keluargamakan/core/api/token_store.dart';
import 'package:keluargamakan/core/config/app_config.dart';
import 'package:keluargamakan/core/storage/app_database.dart';
import 'package:keluargamakan/core/storage/key_value_store.dart';

const testBaseUrl = 'https://api.test';

/// The failure of a result that must have failed.
ApiFailure failureOf<T>(ApiResult<T> result) => switch (result) {
  Err(:final failure) => failure,
  Ok(:final value) => throw StateError('Expected a failure, got $value'),
};

/// The value of a result that must have succeeded.
T valueOf<T>(ApiResult<T> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final failure) => throw StateError('Expected a value, got $failure'),
};

AppDatabase memoryDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

final testTokens = SessionTokens(
  accountId: 'acc-1',
  accessToken: 'access-1',
  accessTokenExpiresAt: DateTime.utc(2026, 11, 11, 12),
  refreshToken: 'refresh-1',
  refreshTokenExpiresAt: DateTime.utc(2026, 12, 11),
);

/// A container with a MockClient, an in-memory token store and database.
/// Call `container.read(sessionManagerProvider).load()` to start signed in.
ProviderContainer testContainer({
  required MockClientHandler handler,
  TokenStore? tokens,
  AppDatabase? db,
  String baseUrl = testBaseUrl,
  Map<String, Object?> config = const {},
}) {
  final database = db ?? memoryDatabase();
  final container = ProviderContainer(
    overrides: [
      apiEnvironmentProvider.overrideWithValue(
        ApiEnvironment(Uri.parse(baseUrl)),
      ),
      httpClientProvider.overrideWithValue(MockClient(handler)),
      tokenStoreProvider.overrideWithValue(tokens ?? InMemoryTokenStore()),
      appDatabaseProvider.overrideWithValue(database),
      keyValueStoreProvider.overrideWithValue(InMemoryKeyValueStore()),
      appConfigProvider.overrideWithValue(
        AppConfig([MapConfigSource(config), const LocalDefaultsConfigSource()]),
      ),
    ],
  );
  return container;
}

http.Response jsonResponse(Object? body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

http.Response problemResponse(
  String code,
  int status, {
  String title = 'Server title',
  String detail = 'Server detail text',
  Map<String, String> headers = const {},
  Map<String, Object?> extra = const {},
}) => http.Response(
  jsonEncode({
    'type': 'urn:keluargamakan:problem:$code',
    'title': title,
    'status': status,
    'code': code,
    'detail': detail,
    'requestId': 'req-1',
    ...extra,
  }),
  status,
  headers: {'content-type': 'application/problem+json', ...headers},
);

Map<String, Object?> consentJson(String status) => {
  'status': status,
  'consentRecordId': status == 'none' ? null : 'consent-1',
  'decidedAt': status == 'none' ? null : '2026-11-01T03:00:00Z',
  'textVersion': status == 'none' ? null : 'v1',
  'deletionDueBy': status == 'withdrawn' ? '2026-12-01T00:00:00Z' : null,
};

Map<String, Object?> allergyRuleJson({
  String id = 'rule-1',
  String allergen = 'peanut',
}) => {
  'id': id,
  'type': 'allergy',
  'allergen': allergen,
  'freeText': null,
  'mapping': null,
  'createdAt': '2026-11-01T03:00:00Z',
};

Map<String, Object?> freeTextRuleJson(String text) => {
  'id': 'rule-ft',
  'type': 'free_text',
  'allergen': null,
  'freeText': text,
  'mapping': {
    'status': 'unmapped',
    'ingredients': <Object?>[],
    'confirmedBy': null,
    'updatedAt': '2026-11-01T03:00:00Z',
  },
  'createdAt': '2026-11-01T03:00:00Z',
};

Map<String, Object?> rulesJson({
  String consent = 'given',
  List<Object?> items = const [],
}) => {'consent': consentJson(consent), 'items': items};

Map<String, Object?> profileJson({
  String id = 'p-ibu',
  String name = 'Ibu',
  String ageGroup = 'adult',
  bool isManager = true,
  Map<String, Object?>? rules,
}) {
  final isChild = const {'infant', 'child', 'teen'}.contains(ageGroup);
  return {
    'id': id,
    'name': name,
    'avatar': {
      'style': 'initials',
      'colorToken': 'avatar_1',
      'illustrationId': null,
    },
    'ageGroup': ageGroup,
    'isChild': isChild,
    'isManager': isManager,
    'guardianConfirmation': isChild
        ? {
            'consentRecordId': 'guardian-1',
            'confirmedAt': '2026-11-01T03:00:00Z',
            'textVersion': 'g1',
          }
        : null,
    'portions': {
      'portionSize': 'normal',
      'portionSizeIsDefault': true,
      'ricePortion': 'normal',
      'ricePortionIsDefault': true,
    },
    'rules': rules ?? rulesJson(),
    'preferences': {
      'spiceLevel': null,
      'lessOf': <Object?>[],
      'textures': <Object?>[],
      'updatedAt': null,
    },
    'likesDislikes': {
      'likes': <Object?>[],
      'dislikes': <Object?>[],
      'updatedAt': null,
    },
    'createdAt': '2026-11-01T03:00:00Z',
    'updatedAt': '2026-11-02T03:00:00Z',
  };
}

Map<String, Object?> profileListJson(List<Map<String, Object?>> items) => {
  'items': items,
  'maxProfiles': 12,
};

Map<String, Object?> householdJson({String timeZone = 'Asia/Makassar'}) => {
  'id': 'hh-1',
  'name': 'Keluarga Contoh',
  'city': null,
  'timeZone': timeZone,
  'language': 'id',
  'managerAccountId': 'acc-1',
  'managerProfileId': 'p-ibu',
  'createdAt': '2026-11-01T03:00:00Z',
  'updatedAt': '2026-11-02T03:00:00Z',
};

Map<String, Object?> tokensJson(String suffix) => {
  'tokenType': 'Bearer',
  'accessToken': 'access-$suffix',
  'accessTokenExpiresAt': '2026-11-11T13:00:00Z',
  'refreshToken': 'refresh-$suffix',
  'refreshTokenExpiresAt': '2026-12-11T00:00:00Z',
};

api.ProfileCreate apiProfileCreate(String name) =>
    api.ProfileCreate(name: name, ageGroup: api.AgeGroup.adult);

api.HardRuleCreate apiAllergyRule() => api.HardRuleCreate(
  type: api.HardRuleType.allergy,
  allergen: const api.Optional.present(api.StandardAllergen.peanut),
);

Map<String, Object?> accountJson() => {
  'id': 'acc-1',
  'role': 'manager',
  'householdId': 'hh-1',
  'signInMethods': ['phone'],
  'phone': '+6281200000000',
  'email': null,
  'createdAt': '2026-11-01T03:00:00Z',
};
