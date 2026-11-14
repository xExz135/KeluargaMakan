// Strict decoding of the Dapur Saya payloads (contract 0.2.1).
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
  );
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
  return KitchenList(
    items: [for (final item in items) decodeKitchenItem(item)],
    maxItems: maxItems,
    referenceVersion: version as String?,
    source: const FromNetwork(),
  );
}

/// Contract `CatalogIngredient`.
CatalogEntry decodeCatalogIngredient(Object? json) {
  final raw = _object(json, 'catalog ingredient');
  final localNames = _list(raw['localNames'], 'catalog localNames');
  _list(raw['brands'], 'catalog brands');
  return CatalogEntry(
    ingredientId: _string(raw['ingredientId'], 'catalog ingredientId'),
    displayName: _name(raw['displayName'], 'catalog displayName'),
    localNames: [for (final n in localNames) _string(n, 'catalog local name')],
    // Null (or a code this app does not know): the app asks for one.
    category: kitchenCategoryFromWire(raw['category']),
    brandVaries: _bool(raw['brandVaries'], 'catalog brandVaries'),
  );
}

/// Contract `ReferenceIngredientCatalog`, with the response's ETag.
IngredientCatalog decodeCatalog(Object? json, {required String? etag}) {
  final raw = _object(json, 'catalog');
  final items = _list(raw['items'], 'catalog items');
  return IngredientCatalog(
    referenceVersion: _string(raw['referenceVersion'], 'catalog version'),
    etag: etag,
    items: [for (final item in items) decodeCatalogIngredient(item)],
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
