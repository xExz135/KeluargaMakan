// TEST FIXTURE: not real safety or nutrition data.
//
// Dapur Saya endpoints of the fake API (contract 0.2.3): kitchen items,
// the kitchen sync (KIT-16), ingredient sets (KIT-08), the reference
// ingredient catalog with ETag / If-None-Match, and search.
// The catalog holds names and kitchen categories only (the contract
// carries no safety data); IDs use the `fx_kit_` prefix of the server's
// fixtures. Behaviour mirrors the contract rules the app relies on: one
// item per ingredient (a repeat add answers 200 with the requested state),
// the item limit (409 `kitchen_item_limit_reached`), 503
// `reference_data_unavailable` for the catalog, search and reference adds
// (custom adds still work) and Idempotency-Key replays. The sync follows
// services/api/src/kitchen/kitchen-service.ts: each change is dated at the
// server's time minus `ageMs`; per ingredient the latest change wins and an
// older one is `superseded`; removals are kept; a repeated change ID
// returns its first result; temporary rejections are not remembered; ages
// out of range are rejected one by one; a cursor is bound to the account,
// and an unknown one gives the whole kitchen with `full: true`. Brand names
// are invented (`Merek Contoh`).

part of 'fake_server.dart';

Map<String, Object?> _catalogItem(
  String id,
  String nameId,
  String nameEn, {
  String? category,
  List<String> localNames = const [],
  bool brandVaries = false,
  List<Map<String, Object?>> brands = const [],
}) => {
  'ingredientId': id,
  'displayName': {'id': nameId, 'en': nameEn},
  'localNames': localNames,
  'category': category,
  'brandVaries': brandVaries,
  'brands': brands,
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
    brands: [
      {'brandId': 'fx_brand_contoh_a', 'name': 'Merek Contoh A'},
      {'brandId': 'fx_brand_contoh_b', 'name': 'Merek Contoh B'},
    ],
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

  // ---------------------------------------------------------- sync

  /// Every sync request body, in order.
  final List<Map<String, Object?>> syncBodies = [];

  /// Changes for these ingredient keys (`r:<id>`, `c:<folded name>`) are
  /// rejected with the code while it is set.
  final Map<String, String> syncRejections = {};

  /// False: every cursor counts as unknown (a full sync is answered).
  bool acceptCursors = true;

  /// The oldest `ageMs` accepted (contract: at most 30 days).
  Duration maxChangeAge = const Duration(days: 30);

  /// `KitchenSyncResponse` decoding test hooks: answers the next syncs with
  /// this status and problem code instead.
  String? failSyncWith;
  int failSyncStatus = 503;

  /// The next sync is applied, but its answer is lost on the way back.
  bool loseNextSyncAnswer = false;

  int _seq = 0;
  final Map<String, int> _itemSeq = {};
  final Map<String, DateTime> _editedAt = {};
  final Map<String, Map<String, DateTime>> _removedAt = {};
  final List<(String, String, int)> _removals = [];
  final Map<String, Map<String, (String, Map<String, Object?>)>> _memory = {};

  // ---------------------------------------------------------- sets

  final Map<String, List<Map<String, Object?>>> setsByAccount = {};
  int maxSets = 10;
}

const _temporarySyncCodes = {
  'reference_data_unavailable',
  'kitchen_item_limit_reached',
  'ingredient_set_limit_reached',
  'service_unavailable',
};

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
    _touch(this, item, _now);
    return item;
  }

  /// Changes an item as another phone would, at [at] (server time; now by
  /// default). Later syncs list it.
  void editKitchenItemElsewhere(
    String account,
    String itemId, {
    String? state,
    Object? quantity = _keep,
    DateTime? at,
  }) {
    final item = kitchenOf(account).firstWhere((i) => i['id'] == itemId);
    if (state != null) item['state'] = state;
    if (quantity != _keep) item['quantity'] = quantity;
    _touch(this, item, at ?? _now);
  }

  /// Removes an item as another phone would.
  void removeKitchenItemElsewhere(String account, String itemId) {
    final items = kitchenOf(account);
    final item = items.firstWhere((i) => i['id'] == itemId);
    _removeItem(this, account, item, _now);
  }

  /// Seeds a set, as if made earlier on another phone.
  Map<String, Object?> seedSet(
    String account,
    String name,
    List<String> itemIds,
  ) {
    final set = {
      'id': 's-${++_ids}',
      'name': name,
      'itemIds': itemIds,
      'createdAt': _now.toIso8601String(),
      'updatedAt': _now.toIso8601String(),
    };
    (kitchen.setsByAccount[account] ??= []).add(set);
    return set;
  }
}

const _keep = Object();

void _touch(FakeServer server, Map<String, Object?> item, DateTime at) {
  final k = server.kitchen;
  final id = item['id']! as String;
  k._editedAt[id] = at;
  k._itemSeq[id] = ++k._seq;
  item['changedAt'] = server._now.toIso8601String();
}

void _removeItem(
  FakeServer server,
  String account,
  Map<String, Object?> item,
  DateTime at,
) {
  final k = server.kitchen;
  server.kitchenOf(account).remove(item);
  (k._removedAt[account] ??= {})[_keyOfItem(item)] = at;
  k._removals.add((account, item['id']! as String, ++k._seq));
  for (final set
      in k.setsByAccount[account] ?? const <Map<String, Object?>>[]) {
    set['itemIds'] = [
      for (final id in set['itemIds']! as List)
        if (id != item['id']) id,
    ];
  }
}

String _keyOfItem(Map<String, Object?> item) => switch (item['ingredientId']) {
  final String id => 'r:$id',
  _ => 'c:${_fold(item['customName']! as String)}',
};

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

  if (path == '/v1/household/kitchen/sync' && request.method == 'POST') {
    return _sync(server, request, account);
  }
  if (path.startsWith('/v1/household/kitchen/sets')) {
    return _sets(server, request, account);
  }
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
      _removeItem(server, account, item, server._now);
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

http.Response _bad(String pointer) => FakeServer.problem(
  'validation_failed',
  400,
  extra: {
    'errors': [
      {'pointer': pointer, 'code': 'invalid_value'},
    ],
  },
);

http.Response _sync(FakeServer server, http.Request request, String account) {
  final k = server.kitchen;
  final body = jsonDecode(request.body) as Map<String, Object?>;
  k.syncBodies.add(body);
  if (k.failSyncWith case final code?) {
    return FakeServer.problem(code, k.failSyncStatus);
  }
  final changes = body['changes'];
  final cursor = body['cursor'];
  if (changes is! List || changes.length > 100) return _bad('/changes');
  if (cursor != null && (cursor is! String || cursor.length > 512)) {
    return _bad('/cursor');
  }
  // The schema: a change the server cannot read refuses the whole request.
  for (final (i, raw) in changes.indexed) {
    if (raw is! Map<String, Object?>) return _bad('/changes/$i');
    final ingredient = raw['ingredient'];
    if (raw['changeId'] is! String ||
        raw['ageMs'] is! int ||
        !const ['upsert', 'remove'].contains(raw['operation']) ||
        ingredient is! Map<String, Object?> ||
        (ingredient.containsKey('ingredientId') ==
            ingredient.containsKey('customName'))) {
      return _bad('/changes/$i');
    }
    final name = ingredient['customName'];
    if (name != null && (name is! String || name.isEmpty || name.length > 60)) {
      return _bad('/changes/$i/ingredient/customName');
    }
  }
  final results = [
    for (final raw in changes.cast<Map<String, Object?>>())
      _syncChange(server, account, raw),
  ];
  if (k.loseNextSyncAnswer) {
    k.loseNextSyncAnswer = false;
    throw http.ClientException('connection reset');
  }
  int? after;
  if (k.acceptCursors && cursor is String) {
    final parts = cursor.split('.');
    if (parts.length == 3 && parts[0] == 'fx' && parts[1] == account) {
      after = int.tryParse(parts[2]);
    }
  }
  final all = server.kitchenOf(account);
  final present = {for (final i in all) i['id']};
  final items = [
    for (final i in all)
      if (after == null || (k._itemSeq[i['id']] ?? 0) > after)
        _shown(server, i),
  ];
  final removed = after == null
      ? <String>[]
      : [
          for (final (a, id, seq) in k._removals)
            if (a == account && seq > after && !present.contains(id)) id,
        ];
  return FakeServer.json({
    'cursor': 'fx.$account.${k._seq}',
    'full': after == null,
    'items': items,
    'removedItemIds': removed,
    'results': results,
    'maxItems': k.maxItems,
    'referenceVersion': k.referenceAvailable ? k.catalogVersion : null,
  });
}

Map<String, Object?> _syncChange(
  FakeServer server,
  String account,
  Map<String, Object?> change,
) {
  final k = server.kitchen;
  final changeId = (change['changeId']! as String).toLowerCase();
  final ingredient = change['ingredient']! as Map<String, Object?>;
  final op = change['operation']! as String;
  final patch = {
    for (final e in change.entries)
      if (!const ['changeId', 'ageMs'].contains(e.key)) e.key: e.value,
  };
  final hash = jsonEncode(patch);
  final memory = k._memory[account] ??= {};
  if (memory[changeId] case (final stored, final result)) {
    return stored == hash
        ? result
        : {
            'changeId': change['changeId'],
            'outcome': 'rejected',
            'itemId': null,
            'errorCode': 'idempotency_key_reused',
          };
  }
  final ingredientId = ingredient['ingredientId'] as String?;
  final customName = (ingredient['customName'] as String?)?.trim();
  final key = ingredientId != null
      ? 'r:$ingredientId'
      : 'c:${_fold(customName!)}';
  final items = server.kitchenOf(account);
  final existing = items.where((i) => _keyOfItem(i) == key).firstOrNull;

  Map<String, Object?> answer(String outcome, {String? itemId, String? code}) {
    final result = {
      'changeId': change['changeId'],
      'outcome': outcome,
      'itemId': itemId,
      'errorCode': code,
    };
    if (!(outcome == 'rejected' && _temporarySyncCodes.contains(code))) {
      memory[changeId] = (hash, result);
    }
    return result;
  }

  if (k.syncRejections[key] case final code?) {
    return answer('rejected', code: code);
  }
  final ageMs = change['ageMs']! as int;
  if (ageMs < 0 || ageMs > k.maxChangeAge.inMilliseconds) {
    return answer('rejected', code: 'validation_failed');
  }
  final editedAt = server._now.subtract(Duration(milliseconds: ageMs));
  final stored = existing == null ? null : k._editedAt[existing['id']];
  final removedAt = k._removedAt[account]?[key];
  DateTime? latest = stored;
  if (removedAt != null && (latest == null || removedAt.isAfter(latest))) {
    latest = removedAt;
  }
  if (latest != null && editedAt.isBefore(latest)) {
    return answer('superseded', itemId: existing?['id'] as String?);
  }
  if (op == 'remove') {
    if (existing != null) _removeItem(server, account, existing, editedAt);
    return answer('applied');
  }

  // Brand (KIT-09, SAF-07): a listed brand of this reference ingredient, or
  // typed text (never a listed brand).
  Object? brand = _keep;
  if (change.containsKey('brand')) {
    final raw = change['brand'];
    if (raw == null) {
      brand = null;
    } else {
      raw as Map<String, Object?>;
      if (raw['brandId'] case final String brandId) {
        if (ingredientId == null) {
          return answer('rejected', code: 'validation_failed');
        }
        if (!k.referenceAvailable) {
          return answer('rejected', code: 'reference_data_unavailable');
        }
        final listed = (_catalogById(ingredientId)?['brands'] as List? ?? [])
            .cast<Map<String, Object?>>()
            .where((b) => b['brandId'] == brandId)
            .firstOrNull;
        if (listed == null) {
          return answer('rejected', code: 'validation_failed');
        }
        brand = {'brandId': brandId, 'name': listed['name']};
      } else {
        brand = {
          'brandId': null,
          'name': (raw['customName']! as String).trim(),
        };
      }
    }
  }

  void write(Map<String, Object?> item) {
    if (change['state'] case final String state) item['state'] = state;
    if (change['category'] case final String category) {
      item['category'] = category;
    }
    if (change.containsKey('quantity')) item['quantity'] = change['quantity'];
    if (brand != _keep) item['brand'] = brand;
    _touch(server, item, editedAt);
  }

  if (existing != null) {
    write(existing);
    return answer('applied', itemId: existing['id'] as String?);
  }
  if (items.length >= k.maxItems) {
    return answer('rejected', code: 'kitchen_item_limit_reached');
  }
  String? category = change['category'] as String?;
  if (ingredientId != null) {
    if (!k.referenceAvailable) {
      return answer('rejected', code: 'reference_data_unavailable');
    }
    final catalog = _catalogById(ingredientId);
    if (catalog == null) return answer('rejected', code: 'validation_failed');
    category ??= catalog['category'] as String?;
  } else if (k.refusedCustomNames.contains(customName)) {
    return answer('rejected', code: 'validation_failed');
  }
  if (category == null) return answer('rejected', code: 'validation_failed');
  final item = _kitchenItem(
    server,
    ingredientId: ingredientId,
    customName: customName,
    category: category,
  );
  items.add(item);
  write(item);
  return answer('applied', itemId: item['id'] as String?);
}

http.Response _sets(FakeServer server, http.Request request, String account) {
  final k = server.kitchen;
  final json = FakeServer.json;
  final problem = FakeServer.problem;
  final sets = k.setsByAccount[account] ??= [];
  final segments = request.url.pathSegments;
  final known = {for (final i in server.kitchenOf(account)) i['id']};
  final now = server._now.toIso8601String();
  http.Response? checkItems(Map<String, Object?> body) {
    final name = body['name'];
    if (name is! String || name.trim().isEmpty || name.length > 40) {
      return _bad('/name');
    }
    final ids = body['itemIds'];
    if (ids is! List) return _bad('/itemIds');
    if (ids.any((id) => !known.contains(id))) return problem('not_found', 404);
    return null;
  }

  if (segments.length == 4) {
    if (request.method == 'GET') {
      return json({'items': sets, 'maxSets': k.maxSets});
    }
    if (request.method == 'POST') {
      final key = request.headers['idempotency-key'];
      final replayKey = '$account|set|$key';
      if (key != null && k._replays.containsKey(replayKey)) {
        return k._replays[replayKey]!;
      }
      final body = jsonDecode(request.body) as Map<String, Object?>;
      if (checkItems(body) case final error?) return error;
      if (sets.length >= k.maxSets) {
        return problem('ingredient_set_limit_reached', 409);
      }
      final set = {
        'id': 's-${++server._ids}',
        'name': (body['name']! as String).trim(),
        'itemIds': body['itemIds'],
        'createdAt': now,
        'updatedAt': now,
      };
      sets.add(set);
      final answer = json(set, 201);
      if (key != null) k._replays[replayKey] = answer;
      return answer;
    }
  }
  if (segments.length >= 5) {
    final set = sets.where((s) => s['id'] == segments[4]).firstOrNull;
    if (set == null) return problem('not_found', 404);
    if (segments.length == 5 && request.method == 'PUT') {
      final body = jsonDecode(request.body) as Map<String, Object?>;
      if (checkItems(body) case final error?) return error;
      set['name'] = (body['name']! as String).trim();
      set['itemIds'] = body['itemIds'];
      set['updatedAt'] = now;
      return json(set);
    }
    if (segments.length == 5 && request.method == 'DELETE') {
      sets.remove(set);
      return http.Response('', 204);
    }
  }
  return problem('not_found', 404);
}
