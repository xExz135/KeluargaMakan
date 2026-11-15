// Strict decoding of the Dapur Saya payloads (contract 0.2.3).
//
// Hand-written like ApiProblem: the generated `KitchenItem.fromJson` throws
// on a state this app version does not know, but the contract says such a
// state shows as "Habis", never as "Ada". Everything else is checked
// against the contract, and any mismatch throws so [ApiCaller] turns it into
// a DecodeFailure: one bad row fails the whole list rather than silently
// dropping an item.

import 'package:keluargamakan_api/api.dart' as api;

import 'models/kitchen.dart';
import 'models/sourced.dart';

Never _bad(String what) => throw FormatException('Invalid $what');

Map<String, Object?> _object(Object? json, String what) =>
    json is Map<String, Object?> ? json : _bad(what);

List<Object?> _list(Object? json, String what) =>
    json is List<Object?> ? json : _bad(what);

String _string(Object? json, String what) =>
    json is String && json.isNotEmpty ? json : _bad(what);

String? _optionalString(Object? json, String what) =>
    json == null ? null : _string(json, what);

bool _bool(Object? json, String what) => json is bool ? json : _bad(what);

DateTime _dateTime(Object? json, String what) {
  final parsed = json is String ? DateTime.tryParse(json) : null;
  return parsed ?? _bad(what);
}

BilingualName _name(Object? json, String what) {
  final raw = _object(json, what);
  return BilingualName(
    id: _string(raw['id'], '$what.id'),
    en: _string(raw['en'], '$what.en'),
  );
}

void _unique(Iterable<String> ids, String what) {
  final seen = <String>{};
  for (final id in ids) {
    if (!seen.add(id)) _bad('repeated $what');
  }
}

/// A category code, or null when this app version does not know it.
api.KitchenCategory? kitchenCategoryFromWire(Object? value) =>
    api.KitchenCategory.fromJson(value);

/// Contract `KitchenItem`.
KitchenEntry decodeKitchenItem(Object? json) {
  final raw = _object(json, 'kitchen item');
  final ingredientId = _optionalString(
    raw['ingredientId'],
    'kitchen item ingredientId',
  );
  final isCustom = _bool(raw['isCustom'], 'kitchen item isCustom');
  if (isCustom != (ingredientId == null)) _bad('kitchen item custom flag');
  final customName = _optionalString(
    raw['customName'],
    'kitchen item customName',
  );
  if (isCustom && customName == null) _bad('custom item without a name');
  final rawDisplay = raw['displayName'];
  final rank = raw['usageRank'];
  if (rank != null && rank is! int) _bad('kitchen item usageRank');
  if (!raw.containsKey('state')) _bad('kitchen item state');
  final brand = _brand(raw['brand']);
  if (brand is ReferenceBrand && isCustom) _bad('reference brand on custom');
  return KitchenEntry(
    id: _string(raw['id'], 'kitchen item id'),
    ingredientId: ingredientId,
    displayName: rawDisplay == null
        ? null
        : _name(rawDisplay, 'kitchen item displayName'),
    customName: isCustom ? customName : null,
    // A category is a response enum: a new value is a breaking change
    // (contract info), so an unknown one fails closed.
    category:
        kitchenCategoryFromWire(raw['category']) ??
        _bad('kitchen item category'),
    state: KitchenItemState.fromWire(raw['state']),
    isDefaultStaple: _bool(
      raw['isDefaultStaple'],
      'kitchen item isDefaultStaple',
    ),
    usageRank: rank is int && rank >= 1 ? rank : null,
    changedAt: _dateTime(raw['changedAt'], 'kitchen item changedAt'),
    createdAt: _dateTime(raw['createdAt'], 'kitchen item createdAt'),
    // An amount this app version does not know is not shown; it says
    // nothing about safety.
    quantity: KitchenAmount.fromWire(raw['quantity']),
    brand: brand,
  );
}

/// Contract `KitchenBrand`, or null.
KitchenBrand? _brand(Object? json) {
  if (json == null) return null;
  final raw = _object(json, 'kitchen brand');
  final name = _string(raw['name'], 'kitchen brand name');
  return switch (_optionalString(raw['brandId'], 'kitchen brand id')) {
    final id? => ReferenceBrand(id, name),
    // A typed brand is text only: never a recorded brand (SAF-07).
    null => TypedBrand(name),
  };
}

/// Contract `KitchenItemList`.
KitchenList decodeKitchenList(Object? json) {
  final raw = _object(json, 'kitchen list');
  final items = _list(raw['items'], 'kitchen list items');
  final maxItems = raw['maxItems'];
  if (maxItems is! int || maxItems < 1) _bad('kitchen list maxItems');
  final version = raw['referenceVersion'];
  if (version != null && version is! String) {
    _bad('kitchen list referenceVersion');
  }
  final decoded = [for (final item in items) decodeKitchenItem(item)];
  // One item per ID: a repeated ID would show twice and fail the phone's
  // copy (security review T-033 L1).
  _unique(decoded.map((i) => i.id), 'kitchen item id');
  return KitchenList(
    items: decoded,
    maxItems: maxItems,
    referenceVersion: version as String?,
    source: const FromNetwork(),
  );
}

/// Contract `CatalogIngredient`.
CatalogEntry decodeCatalogIngredient(Object? json) {
  final raw = _object(json, 'catalog ingredient');
  final localNames = _list(raw['localNames'], 'catalog localNames');
  final brands = [
    for (final b in _list(raw['brands'], 'catalog brands'))
      () {
        final brand = _object(b, 'catalog brand');
        return CatalogBrand(
          brandId: _string(brand['brandId'], 'catalog brandId'),
          name: _string(brand['name'], 'catalog brand name'),
        );
      }(),
  ];
  _unique(brands.map((b) => b.brandId), 'catalog brandId');
  return CatalogEntry(
    ingredientId: _string(raw['ingredientId'], 'catalog ingredientId'),
    displayName: _name(raw['displayName'], 'catalog displayName'),
    localNames: [for (final n in localNames) _string(n, 'catalog local name')],
    // Null (or a code this app does not know): the app asks for one.
    category: kitchenCategoryFromWire(raw['category']),
    brandVaries: _bool(raw['brandVaries'], 'catalog brandVaries'),
    brands: brands,
  );
}

/// Contract `ReferenceIngredientCatalog`, with the response's ETag.
IngredientCatalog decodeCatalog(Object? json, {required String? etag}) {
  final raw = _object(json, 'catalog');
  final items = _list(raw['items'], 'catalog items');
  final decoded = [for (final item in items) decodeCatalogIngredient(item)];
  _unique(decoded.map((i) => i.ingredientId), 'catalog ingredientId');
  return IngredientCatalog(
    referenceVersion: _string(raw['referenceVersion'], 'catalog version'),
    etag: etag,
    items: decoded,
    source: const FromNetwork(),
  );
}

/// Contract `IngredientSearchResult`.
List<IngredientHit> decodeSearchResult(Object? json) {
  final raw = _object(json, 'search result');
  _string(raw['referenceVersion'], 'search referenceVersion');
  final items = _list(raw['items'], 'search items');
  return [
    for (final item in items)
      () {
        final hit = _object(item, 'search hit');
        return IngredientHit(
          decodeCatalogIngredient(hit['ingredient']),
          matchedName: _optionalString(hit['matchedName'], 'matchedName'),
        );
      }(),
  ];
}

/// An `ETag` value safe to keep and send back: an entity tag of printable
/// ASCII without quotes inside (RFC 9110 8.8.3), within the contract's
/// 200-character `If-None-Match` limit. Anything else is not kept, so the
/// next download is a full one.
String? acceptableEtag(String? value) {
  if (value == null || value.length > 200) return null;
  return RegExp(r'^(W/)?"[\x21\x23-\x7E]*"$').hasMatch(value) ? value : null;
}

/// Contract `IngredientSet`.
IngredientSetInfo decodeIngredientSet(Object? json) {
  final raw = _object(json, 'ingredient set');
  final ids = [
    for (final id in _list(raw['itemIds'], 'set itemIds'))
      _string(id, 'set item id'),
  ];
  _unique(ids, 'set item id');
  return IngredientSetInfo(
    id: _string(raw['id'], 'set id'),
    name: _string(raw['name'], 'set name'),
    itemIds: ids,
    updatedAt: _dateTime(raw['updatedAt'], 'set updatedAt'),
  );
}

/// Contract `IngredientSetList`.
IngredientSets decodeIngredientSets(Object? json) {
  final raw = _object(json, 'ingredient set list');
  final maxSets = raw['maxSets'];
  if (maxSets is! int || maxSets < 1) _bad('set list maxSets');
  final items = [
    for (final s in _list(raw['items'], 'set list items'))
      decodeIngredientSet(s),
  ];
  _unique(items.map((s) => s.id), 'set id');
  return IngredientSets(
    items: items,
    maxSets: maxSets,
    source: const FromNetwork(),
  );
}

/// Contract `KitchenSyncResponse`. [sent] are the change IDs in the order
/// they were sent: the answer must have one result per change in the same
/// order, or it is not trusted at all.
KitchenSyncAnswer decodeSyncAnswer(Object? json, {required List<String> sent}) {
  final raw = _object(json, 'sync answer');
  final cursor = _string(raw['cursor'], 'sync cursor');
  if (cursor.length > 512) _bad('sync cursor');
  final full = _bool(raw['full'], 'sync full');
  final items = [
    for (final item in _list(raw['items'], 'sync items'))
      decodeKitchenItem(item),
  ];
  _unique(items.map((i) => i.id), 'sync item id');
  final removed = [
    for (final id in _list(raw['removedItemIds'], 'sync removedItemIds'))
      _string(id, 'sync removed id'),
  ];
  final results = [
    for (final r in _list(raw['results'], 'sync results'))
      () {
        final result = _object(r, 'sync result');
        // A response enum: a value this app version does not know fails
        // the whole answer closed (contract versioning, QUESTIONS #58).
        final outcome = switch (result['outcome']) {
          'applied' => KitchenSyncOutcome.applied,
          'superseded' => KitchenSyncOutcome.superseded,
          'rejected' => KitchenSyncOutcome.rejected,
          _ => _bad('sync outcome'),
        };
        final errorCode = _optionalString(result['errorCode'], 'errorCode');
        if (outcome == KitchenSyncOutcome.rejected && errorCode == null) {
          _bad('rejection without a code');
        }
        return KitchenChangeAnswer(
          changeId: _string(result['changeId'], 'sync changeId'),
          outcome: outcome,
          itemId: _optionalString(result['itemId'], 'sync itemId'),
          errorCode: errorCode,
        );
      }(),
  ];
  if (results.length != sent.length) _bad('sync result count');
  for (final (i, result) in results.indexed) {
    if (result.changeId.toLowerCase() != sent[i].toLowerCase()) {
      _bad('sync result order');
    }
  }
  final maxItems = raw['maxItems'];
  if (maxItems is! int || maxItems < 1) _bad('sync maxItems');
  final version = raw['referenceVersion'];
  if (version != null && version is! String) _bad('sync referenceVersion');
  return KitchenSyncAnswer(
    cursor: cursor,
    full: full,
    items: items,
    removedItemIds: removed,
    results: results,
    maxItems: maxItems,
    referenceVersion: version as String?,
  );
}
