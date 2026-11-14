// TEST FIXTURE: not real safety or nutrition data.
//
// Keluarga Saya endpoints of the fake API (contract v0.1.2): profiles,
// preferences, likes, hard rules, consent texts and decisions, and the
// standard allergen list. The allergen codes are the contract's enum, used
// here only as test fixtures; consent texts and portion defaults are
// invented. Behaviour mirrors the contract's rules that the app relies on:
// guardian confirmation for child groups, the manager is always an adult,
// consent preconditions (`consent_changed`), the audience of the consent
// text (renewal, QUESTIONS #62), and `rules_unavailable`.

part of 'fake_server.dart';

/// The contract's allergen codes in the order the fake list returns them.
const fixtureAllergens = [
  'peanut',
  'tree_nut',
  'shellfish',
  'shrimp',
  'fish',
  'egg',
  'milk',
  'soy',
  'wheat',
  'gluten',
  'sesame',
];

const _childGroups = {'infant', 'child', 'teen'};

extension FakeFamilyControls on FakeServer {
  /// All profiles of [account], seeded with the manager when first read.
  List<Map<String, Object?>> profilesOf(String account) =>
      profilesByAccount[account] ??= [
        profileJson(
          id: 'p-$account',
          name: _householdNameByAccount[account] ?? 'Ibu',
        ),
      ];

  /// The profile with [id] in any account.
  Map<String, Object?>? profileById(String id) {
    for (final list in profilesByAccount.values) {
      for (final p in list) {
        if (p['id'] == id) return p;
      }
    }
    return null;
  }

  /// Another phone changed the member's consent: [status] with a new
  /// record, rules dropped unless given.
  void changeConsentElsewhere(String profileId, String status) {
    final p = profileById(profileId)!;
    final rules = p['rules']! as Map<String, Object?>;
    rules['consent'] = _consentState(status, 'consent-x${++_ids}');
    if (status != 'given') rules['items'] = <Object?>[];
  }

  /// Signs [destination] in with a household, as if done earlier on this
  /// phone. Returns the tokens to put in the phone's token store.
  SessionTokens seedSignedIn(String destination, {String managerName = 'Ibu'}) {
    final account = 'acc-${++_ids}';
    _accountByDestination[destination] = account;
    _destinationByAccount[account] = destination;
    _householdNameByAccount[account] = managerName;
    final token = 'access-${++_ids}';
    _accountByToken[token] = account;
    return SessionTokens(
      accountId: account,
      accessToken: token,
      accessTokenExpiresAt: _now.add(const Duration(days: 1)),
      refreshToken: 'refresh-$_ids',
      refreshTokenExpiresAt: _now.add(const Duration(days: 30)),
    );
  }
}

Map<String, Object?> _consentState(
  String status,
  String? recordId, {
  bool renewal = false,
  String version = 'health-adult-1',
  DateTime? decidedAt,
  DateTime? deletionDueBy,
}) => {
  'renewalRequired': renewal,
  'status': status,
  'consentRecordId': status == 'none' ? null : recordId,
  'decidedAt': status == 'none'
      ? null
      : (decidedAt ?? DateTime.utc(2026, 11, 10, 3)).toIso8601String(),
  'textVersion': status == 'none' ? null : version,
  'deletionDueBy': deletionDueBy?.toIso8601String(),
};

Map<String, Object?> _consentText(String purpose, String language, String v) =>
    {
      'purpose': purpose,
      'version': v,
      'language': language,
      'title': 'Judul uji $v',
      'sections': [
        {'heading': 'Bagian uji', 'body': 'Teks uji untuk $v.'},
      ],
      'effectiveDate': '2026-11-01',
      'isDraft': true,
    };

String _healthVersion(String audience) => 'health-$audience-1';

String _audienceOf(Map<String, Object?> profile) =>
    profile['isChild'] == true ? 'child' : 'adult';

http.Response? _handleFamily(
  FakeServer server,
  http.Request request,
  String? account,
) {
  final segments = request.url.pathSegments;
  final method = request.method;
  final json = FakeServer.json;
  final problem = FakeServer.problem;

  if (segments.length >= 2 && segments[1] == 'consent-texts') {
    final purpose = segments[2];
    final language = request.url.queryParameters['language'] ?? 'id';
    final audience = request.url.queryParameters['audience'] ?? 'adult';
    return json(
      _consentText(
        purpose,
        language,
        purpose == 'guardian_confirmation'
            ? 'guardian-1'
            : _healthVersion(audience),
      ),
    );
  }
  if (segments.join('/') == 'v1/reference/allergens') {
    if (server.allergensFail) return problem('internal_error', 500);
    return json({'ruleSetVersion': '1.1.0', 'items': fixtureAllergens});
  }
  if (segments.length < 3 || segments[1] != 'household') return null;
  if (segments[2] != 'profiles') return null;
  if (account == null) return problem('unauthenticated', 401);
  final profiles = server.profilesOf(account);
  final key = request.headers['idempotency-key'];
  Map<String, Object?> body() => request.body.isEmpty
      ? const {}
      : jsonDecode(request.body) as Map<String, Object?>;

  // ---------------------------------------------- /profiles
  if (segments.length == 3) {
    if (method == 'GET') {
      if (server.rulesUnavailable) return problem('rules_unavailable', 503);
      return json({'items': profiles, 'maxProfiles': server.maxProfiles});
    }
    if (method == 'POST') {
      if (key != null && server._replays.containsKey(key)) {
        return json(server._replays[key], 201);
      }
      final b = body();
      if (profiles.length >= server.maxProfiles) {
        return problem('profile_limit_reached', 409);
      }
      final age = b['ageGroup']! as String;
      final guardian = b['guardianConfirmation'] as Map<String, Object?>?;
      if (_childGroups.contains(age) && guardian == null) {
        return problem('guardian_confirmation_required', 409);
      }
      if (guardian != null && guardian['textVersion'] != 'guardian-1') {
        return problem('consent_text_outdated', 409);
      }
      final id = 'p-${++server._ids}';
      final created = profileJson(
        id: id,
        name: b['name']! as String,
        ageGroup: age,
        isManager: false,
        rules: {'consent': _consentState('none', null), 'items': <Object?>[]},
      );
      if (b['avatar'] case final Map<String, Object?> avatar) {
        created['avatar'] = {
          'style': avatar['style'],
          'colorToken': avatar['colorToken'],
          'illustrationId': null,
        };
      }
      final small = age == 'infant' || age == 'child';
      created['portions'] = {
        'portionSize': small ? 'small' : 'normal',
        'portionSizeIsDefault': true,
        'ricePortion': small ? 'small' : 'normal',
        'ricePortionIsDefault': true,
      };
      profiles.add(created);
      if (key != null) server._replays[key] = created;
      return json(created, 201);
    }
    return null;
  }

  final id = segments[3];
  final profile = profiles.where((p) => p['id'] == id).firstOrNull;
  if (profile == null) return problem('not_found', 404);
  final rules = profile['rules']! as Map<String, Object?>;
  final consent = rules['consent']! as Map<String, Object?>;
  final rest = segments.skip(4).join('/');

  switch ((method, rest)) {
    case ('GET', ''):
      if (server.rulesUnavailable) return problem('rules_unavailable', 503);
      return json(profile);
    case ('PATCH', ''):
      final b = body();
      if (b['name'] case final String name) profile['name'] = name;
      if (b['avatar'] case final Map<String, Object?> avatar) {
        profile['avatar'] = {
          'style': avatar['style'],
          'colorToken': avatar['colorToken'],
          'illustrationId': null,
        };
      }
      final portions = profile['portions']! as Map<String, Object?>;
      if (b.containsKey('portionSize')) {
        final v = b['portionSize'] as String?;
        portions['portionSize'] = v ?? 'normal';
        portions['portionSizeIsDefault'] = v == null;
      }
      if (b.containsKey('ricePortion')) {
        final v = b['ricePortion'] as String?;
        portions['ricePortion'] = v ?? 'normal';
        portions['ricePortionIsDefault'] = v == null;
      }
      if (b['ageGroup'] case final String age) {
        final wasChild = profile['isChild'] == true;
        final toChild = _childGroups.contains(age);
        if (toChild && profile['isManager'] == true) {
          return problem('manager_profile_must_be_adult', 409);
        }
        if (toChild && !wasChild && b['guardianConfirmation'] == null) {
          return problem('guardian_confirmation_required', 409);
        }
        profile['ageGroup'] = age;
        profile['isChild'] = toChild;
        if (toChild && !wasChild) {
          profile['guardianConfirmation'] = {
            'consentRecordId': 'guardian-${++server._ids}',
            'confirmedAt': '2026-11-12T03:00:00Z',
            'textVersion': 'guardian-1',
          };
        }
        if (!toChild) profile['guardianConfirmation'] = null;
        // QUESTIONS #62: consent given on the other audience's text.
        if (toChild != wasChild && consent['status'] == 'given') {
          consent['renewalRequired'] = true;
        }
      }
      profile['updatedAt'] = '2026-11-13T03:00:00Z';
      return json(profile);
    case ('DELETE', ''):
      if (profile['isManager'] == true) {
        return problem('manager_profile_not_deletable', 409);
      }
      profiles.remove(profile);
      return http.Response('', 204);
    case ('PUT', 'preferences'):
      final b = body();
      profile['preferences'] = {...b, 'updatedAt': '2026-11-13T03:00:00Z'};
      return json(profile['preferences']);
    case ('PUT', 'likes-dislikes'):
      final b = body();
      final old = profile['likesDislikes']! as Map<String, Object?>;
      List<Object?> keep(String field) {
        final ids = {
          for (final i in b[field]! as List<Object?>)
            (i! as Map<String, Object?>)['refId'],
        };
        return [
          for (final r in old[field]! as List<Object?>)
            if (ids.contains((r! as Map<String, Object?>)['refId'])) r,
        ];
      }
      profile['likesDislikes'] = {
        'likes': keep('likes'),
        'dislikes': keep('dislikes'),
        'updatedAt': '2026-11-13T03:00:00Z',
      };
      return json(profile['likesDislikes']);
    case ('GET', 'hard-rules'):
      if (server.rulesUnavailable) return problem('rules_unavailable', 503);
      return json(rules);
    case ('POST', 'hard-rules'):
      if (key != null && server._replays.containsKey(key)) {
        return json(server._replays[key], 201);
      }
      if (consent['status'] != 'given' || consent['renewalRequired'] == true) {
        return problem('consent_required', 409);
      }
      final b = body();
      final items = [...rules['items']! as List<Object?>];
      String? fold(Object? s) => (s as String?)?.trim().toLowerCase();
      final duplicate = items.any((r) {
        final m = r! as Map<String, Object?>;
        return m['type'] == b['type'] &&
            m['allergen'] == b['allergen'] &&
            fold(m['freeText']) == fold(b['freeText']);
      });
      if (duplicate) return problem('hard_rule_duplicate', 409);
      final type = b['type']! as String;
      final written = type == 'free_text' || type == 'medical_exclusion';
      final rule = {
        'id': 'rule-${++server._ids}',
        'type': type,
        'allergen': b['allergen'],
        'freeText': b['freeText'],
        'mapping': written
            ? {
                'status': 'unmapped',
                'ingredients': <Object?>[],
                'confirmedBy': null,
                'updatedAt': '2026-11-13T03:00:00Z',
              }
            : null,
        'createdAt': '2026-11-13T03:00:00Z',
      };
      items.add(rule);
      rules['items'] = items;
      if (key != null) server._replays[key] = rule;
      return json(rule, 201);
    case ('POST', 'consents/health-data'):
      if (key != null && server._replays.containsKey(key)) {
        return json(server._replays[key], 201);
      }
      final b = body();
      final expected = b['expectedConsent']! as Map<String, Object?>;
      if (expected['status'] != consent['status'] ||
          expected['consentRecordId'] != consent['consentRecordId']) {
        return problem('consent_changed', 409);
      }
      if (b['textVersion'] != _healthVersion(_audienceOf(profile))) {
        return problem('consent_text_outdated', 409);
      }
      if (profile['isChild'] == true &&
          profile['guardianConfirmation'] == null) {
        return problem('guardian_confirmation_required', 409);
      }
      final decision = b['decision']! as String;
      final recordId = 'consent-${++server._ids}';
      rules['consent'] = _consentState(
        decision,
        recordId,
        version: b['textVersion']! as String,
      );
      if (decision != 'given') rules['items'] = <Object?>[];
      final record = _record(recordId, id, decision, b['textVersion']);
      if (key != null) server._replays[key] = record;
      return json(record, 201);
    case ('POST', 'consents/health-data/withdraw'):
      final b = body();
      final expected = b['expectedConsent']! as Map<String, Object?>;
      if (expected['status'] != consent['status'] ||
          expected['consentRecordId'] != consent['consentRecordId']) {
        return problem('consent_changed', 409);
      }
      if (consent['status'] != 'given') {
        return problem('consent_not_active', 409);
      }
      final due = DateTime.utc(2026, 12, 13);
      rules['consent'] = _consentState(
        'withdrawn',
        consent['consentRecordId'] as String?,
        version: consent['textVersion']! as String,
        deletionDueBy: due,
      );
      rules['items'] = <Object?>[];
      return json({
        ..._record(
          consent['consentRecordId']! as String,
          id,
          'given',
          consent['textVersion'],
        ),
        'withdrawnAt': '2026-11-13T03:00:00Z',
        'deletionDueBy': due.toIso8601String(),
      });
  }
  if (method == 'DELETE' &&
      segments.length == 6 &&
      segments[4] == 'hard-rules') {
    final items = [...rules['items']! as List<Object?>];
    final before = items.length;
    items.removeWhere((r) => (r! as Map<String, Object?>)['id'] == segments[5]);
    if (items.length == before) return problem('not_found', 404);
    rules['items'] = items;
    return http.Response('', 204);
  }
  return null;
}

Map<String, Object?> _record(
  String id,
  String profileId,
  String decision,
  Object? version,
) => {
  'id': id,
  'profileId': profileId,
  'purpose': 'health_data',
  'decision': decision,
  'textVersion': version,
  'language': 'id',
  'decidedAt': '2026-11-13T03:00:00Z',
  'recordedByAccountId': 'acc-x',
  'withdrawnAt': null,
  'deletionDueBy': null,
};
