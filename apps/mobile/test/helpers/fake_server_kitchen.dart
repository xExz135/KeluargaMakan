// TEST FIXTURE: not real safety or nutrition data.
//
// Dapur Saya endpoints of the fake API (contract 0.2.1): kitchen items,
// the reference ingredient catalog with ETag / If-None-Match, and search.
// The catalog holds names and kitchen categories only (the contract
// carries no safety data); IDs use the `fx_kit_` prefix of the server's
// fixtures. Behaviour mirrors the contract rules the app relies on: one
// item per ingredient (a repeat add answers 200 with the requested state),
// the item limit (409 `kitchen_item_limit_reached`), 503
// `reference_data_unavailable` for the catalog, search and reference adds
// (custom adds still work), Idempotency-Key replays, and quantity or brand
// in PATCH answering 400 `not_allowed` until T-032.

part of 'fake_server.dart';

Map<String, Object?> _catalogItem(
  String id,
  String nameId,
  String nameEn, {
  String? category,
  List<String> localNames = const [],
  bool brandVaries = false,
}) => {
  'ingredientId': id,
  'displayName': {'id': nameId, 'en': nameEn},
  'localNames': localNames,
  'category': category,
  'brandVaries': brandVaries,
  'brands': <Object?>[],
};

/// The fake reference catalog, sorted by Indonesian name.
final fixtureCatalog = <Map<String, Object?>>[
  _catalogItem(
    'fx_kit_bawang_merah',
    'Bawang merah',
    'Shallot',
    category: 'spices_aromatics',
    localNames: ['brambang'],
  ),
  _catalogItem('fx_kit_bayam', 'Bayam', 'Spinach', category: 'vegetables'),
  _catalogItem('fx_kit_beras', 'Beras', 'Rice', category: 'staples'),
  _catalogItem(
    'fx_kit_daun_salam',
    'Daun salam',
    'Indonesian bay leaf',
    category: 'spices_aromatics',
  ),
  _catalogItem(
    'fx_kit_kecap_manis',
    'Kecap manis',
    'Sweet soy sauce',
    category: 'sauces_condiments',
    brandVaries: true,
  ),
  _catalogItem(
    'fx_kit_kemangi',
    'Kemangi',
    'Lemon basil',
    category: 'spices_aromatics',
    localNames: ['selasih'],
  ),
  // No category in the reference data: the app asks for one.
  _catalogItem('fx_kit_kluwek', 'Kluwek', 'Kluwak nut'),
  _catalogItem('fx_kit_tahu', 'Tahu', 'Tofu', category: 'protein'),
  _catalogItem('fx_kit_tempe', 'Tempe', 'Tempeh', category: 'protein'),
];

const _categoryOrder = [
  'protein',
  'vegetables',
  'fruit',
  'spices_aromatics',
  'staples',
  'sauces_condiments',
  'dairy',
  'frozen',
  'leftovers',
];

String _fold(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

/// Kitchen state of the fake server, per account.
final class FakeKitchen {
  /// Items per account, contract-shaped.
  final Map<String, List<Map<String, Object?>>> itemsByAccount = {};

  /// Ingredient IDs every new household starts with (KIT-07), available.
  List<String> defaultStaples = const [];

  /// `KitchenItemList.maxItems`.
  int maxItems = 300;

  /// False: catalog, search and reference adds answer 503
  /// `reference_data_unavailable`, and names in the list are null.
  bool referenceAvailable = true;

  /// The catalog's `referenceVersion`; its ETag is derived from it.
  String catalogVersion = 'fx-1';

  /// Custom names the server refuses with 400 `invalid_format`.
  Set<String> refusedCustomNames = {};

  String get etag => '"fx-catalog-$catalogVersion"';

  final Map<String, http.Response> _replays = {};
}

extension FakeKitchenControls on FakeServer {
  /// The kitchen items of [account], with the default staples at first.
  List<Map<String, Object?>> kitchenOf(String account) =>
      kitchen.itemsByAccount[account] ??= [
        for (final id in kitchen.defaultStaples)
          _kitchenItem(this, ingredientId: id, staple: true),
      ];

  /// Adds an item directly, as if done earlier on another phone.
  Map<String, Object?> seedKitchenItem(
    String account, {
    String? ingredientId,
    String? customName,
    String? category,
    String state = 'available',
    int? usageRank,
    bool staple = false,
  }) {
    final item = _kitchenItem(
      this,
      ingredientId: ingredientId,
      customName: customName,
      category: category,
      state: state,
      usageRank: usageRank,
      staple: staple,
    );
    kitchenOf(account).add(item);
    return item;
  }
}

Map<String, Object?>? _catalogById(String id) =>
    fixtureCatalog.where((c) => c['ingredientId'] == id).firstOrNull;

Map<String, Object?> _kitchenItem(
  FakeServer server, {
  String? ingredientId,
  String? customName,
  String? category,
  String state = 'available',
  int? usageRank,
  bool staple = false,
}) {
  final now = server._now.toIso8601String();
  final catalog = ingredientId == null ? null : _catalogById(ingredientId);
  return {
    'id': 'k-${++server._ids}',
    'ingredientId': ingredientId,
    'isCustom': ingredientId == null,
    'displayName': catalog?['displayName'],
    'customName': customName,
    'category': category ?? catalog?['category'] ?? 'leftovers',
    'state': state,
    'quantity': null,
    'brand': null,
    'isDefaultStaple': staple,
    'usageRank': usageRank,
    'changedAt': now,
    'createdAt': now,
  };
}

Map<String, Object?> _shown(FakeServer server, Map<String, Object?> item) => {
  ...item,
  // Without verified reference data the server has no names (contract).
  if (!server.kitchen.referenceAvailable) 'displayName': null,
};

http.Response? _handleKitchen(
  FakeServer server,
  http.Request request,
  String? account,
) {
  final path = request.url.path;
  final json = FakeServer.json;
  final problem = FakeServer.problem;
  final k = server.kitchen;

  if (path == '/v1/reference/ingredients' && request.method == 'GET') {
    if (account == null) return problem('unauthenticated', 401);
    if (!k.referenceAvailable) {
      return problem('reference_data_unavailable', 503);
    }
    final headers = {'etag': k.etag, 'cache-control': 'private, max-age=0'};
    if (request.headers['if-none-match'] == k.etag) {
      return http.Response('', 304, headers: headers);
    }
    return http.Response(
      jsonEncode({
        'referenceVersion': k.catalogVersion,
        'items': fixtureCatalog,
      }),
      200,
      headers: {'content-type': 'application/json; charset=utf-8', ...headers},
    );
  }
  if (path == '/v1/reference/ingredients/search' && request.method == 'POST') {
    if (account == null) return problem('unauthenticated', 401);
    if (!k.referenceAvailable) {
      return problem('reference_data_unavailable', 503);
    }
    final body = jsonDecode(request.body) as Map<String, Object?>;
    final query = _fold(body['query']! as String);
    final hits = <Map<String, Object?>>[];
    for (final c in fixtureCatalog) {
      final names = c['displayName']! as Map<String, Object?>;
      final local = (c['localNames']! as List).cast<String>();
      if (_fold(names['id']! as String).contains(query) ||
          _fold(names['en']! as String).contains(query)) {
        hits.add({'ingredient': c, 'matchedName': null});
      } else if (local.any((n) => _fold(n).contains(query))) {
        hits.add({
          'ingredient': c,
          'matchedName': local.firstWhere((n) => _fold(n).contains(query)),
        });
      }
    }
    return json({'referenceVersion': k.catalogVersion, 'items': hits});
  }

  if (!path.startsWith('/v1/household/kitchen/')) return null;
  if (account == null) return problem('unauthenticated', 401);
  final items = server.kitchenOf(account);
  final segments = request.url.pathSegments;

  if (path == '/v1/household/kitchen/items' && request.method == 'GET') {
    final sorted = [...items]
      ..sort(
        (a, b) => _categoryOrder
            .indexOf(a['category']! as String)
            .compareTo(_categoryOrder.indexOf(b['category']! as String)),
      );
    return json({
      'items': [for (final i in sorted) _shown(server, i)],
      'maxItems': k.maxItems,
      'referenceVersion': k.referenceAvailable ? k.catalogVersion : null,
    });
  }
  if (path == '/v1/household/kitchen/items' && request.method == 'POST') {
    final key = request.headers['idempotency-key'];
    final replayKey = '$account|$key';
    if (key != null && k._replays.containsKey(replayKey)) {
      return k._replays[replayKey];
    }
    final body = jsonDecode(request.body) as Map<String, Object?>;
    final ingredientId = body['ingredientId'] as String?;
    final customName = (body['customName'] as String?)?.trim();
    final state = body['state'] as String? ?? 'available';
    http.Response answer;
    if (ingredientId != null) {
      final catalog = _catalogById(ingredientId);
      if (!k.referenceAvailable) {
        return problem('reference_data_unavailable', 503);
      }
      if (catalog == null) {
        return problem(
          'validation_failed',
          400,
          extra: {
            'errors': [
              {'pointer': '/ingredientId', 'code': 'invalid_value'},
            ],
          },
        );
      }
      if (catalog['category'] == null && body['category'] == null) {
        return problem(
          'validation_failed',
          400,
          extra: {
            'errors': [
              {'pointer': '/category', 'code': 'required'},
            ],
          },
        );
      }
    } else if (customName == null ||
        customName.isEmpty ||
        customName.length > 60 ||
        k.refusedCustomNames.contains(customName)) {
      return problem(
        'validation_failed',
        400,
        extra: {
          'errors': [
            {'pointer': '/customName', 'code': 'invalid_format'},
          ],
        },
      );
    }
    final existing = items.where((i) {
      if (ingredientId != null) return i['ingredientId'] == ingredientId;
      final name = i['customName'] as String?;
      return name != null && _fold(name) == _fold(customName!);
    }).firstOrNull;
    if (existing != null) {
      existing['state'] = state;
      existing['changedAt'] = server._now.toIso8601String();
      answer = json(_shown(server, existing));
    } else if (items.length >= k.maxItems) {
      return problem('kitchen_item_limit_reached', 409);
    } else {
      final item = _kitchenItem(
        server,
        ingredientId: ingredientId,
        customName: customName,
        category: body['category'] as String?,
        state: state,
      );
      items.add(item);
      answer = json(_shown(server, item), 201);
    }
    if (key != null) k._replays[replayKey] = answer;
    return answer;
  }
  if (segments.length == 5 && segments[3] == 'items') {
    final item = items.where((i) => i['id'] == segments[4]).firstOrNull;
    if (item == null) return problem('not_found', 404);
    if (request.method == 'DELETE') {
      items.remove(item);
      return http.Response('', 204);
    }
    if (request.method == 'PATCH') {
      final body = jsonDecode(request.body) as Map<String, Object?>;
      if (body.containsKey('quantity') || body.containsKey('brand')) {
        return problem(
          'validation_failed',
          400,
          extra: {
            'errors': [
              {'pointer': '/quantity', 'code': 'not_allowed'},
            ],
          },
        );
      }
      if (body['state'] case final String state) item['state'] = state;
      if (body['category'] case final String category) {
        item['category'] = category;
      }
      item['changedAt'] = server._now.toIso8601String();
      return json(_shown(server, item));
    }
  }
  return null;
}
