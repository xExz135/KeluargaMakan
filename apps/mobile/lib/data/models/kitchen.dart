// Dapur Saya models (KIT-01 to KIT-07): the saved kitchen and the reference
// ingredient catalog the phone keeps for search.
//
// Nothing here is a safety result. A custom item (KIT-05) only carries the
// flag that Cek Aman turns into "Cek label" (SAF-09); the app never derives
// a safety state from it. The catalog carries no allergen, component or
// halal data (contract `CatalogIngredient`).
//
// toString() never prints names: custom names are the user's own text.

import 'package:flutter/foundation.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../ingredient_search.dart' show foldIngredientName;
import 'sourced.dart';

/// KIT-03 categories in display order (contract `KitchenCategory`).
const kitchenCategoryOrder = <api.KitchenCategory>[
  api.KitchenCategory.protein,
  api.KitchenCategory.vegetables,
  api.KitchenCategory.fruit,
  api.KitchenCategory.spicesAromatics,
  api.KitchenCategory.staples,
  api.KitchenCategory.saucesCondiments,
  api.KitchenCategory.dairy,
  api.KitchenCategory.frozen,
  api.KitchenCategory.leftovers,
];

/// KIT-02 item state. Unknown wire values decode as [out], never as
/// [available] (contract `KitchenItemState`).
enum KitchenItemState {
  available,
  out;

  static KitchenItemState fromWire(Object? value) =>
      value == 'available' ? available : out;

  api.KitchenItemState toApi() => switch (this) {
    available => api.KitchenItemState.available,
    out => api.KitchenItemState.out_,
  };

  String get wire => switch (this) {
    available => 'available',
    out => 'out',
  };

  KitchenItemState get flipped => this == available ? out : available;
}

/// KIT-09 optional amount (contract `KitchenQuantity`).
enum KitchenAmount {
  little('a_little'),
  some('some'),
  plenty('plenty');

  const KitchenAmount(this.wire);

  final String wire;

  /// Null for a value this app version does not know: the amount is then
  /// not shown (it says nothing about safety).
  static KitchenAmount? fromWire(Object? value) =>
      values.where((a) => a.wire == value).firstOrNull;

  api.KitchenQuantity toApi() => switch (this) {
    little => api.KitchenQuantity.aLittle,
    some => api.KitchenQuantity.some,
    plenty => api.KitchenQuantity.plenty,
  };
}

/// The brand recorded for an item (KIT-09, SAF-07; contract `KitchenBrand`).
/// Never a safety result: only Cek Aman reads it, and a typed brand always
/// leaves "Cek label" in place for brand-varying components.
@immutable
sealed class KitchenBrand {
  const KitchenBrand(this.name);

  /// The reference brand's name, or the text as typed.
  final String name;
}

/// One of the ingredient's brands in the verified reference data.
final class ReferenceBrand extends KitchenBrand {
  const ReferenceBrand(this.brandId, super.name);

  final String brandId;

  @override
  bool operator ==(Object other) =>
      other is ReferenceBrand && other.brandId == brandId;

  @override
  int get hashCode => brandId.hashCode;

  @override
  String toString() => 'ReferenceBrand($brandId)';
}

/// A brand typed by the user, not in the list. Cek Aman keeps "Cek label"
/// for brand-varying components (SAF-07).
final class TypedBrand extends KitchenBrand {
  const TypedBrand(super.name);

  @override
  bool operator ==(Object other) => other is TypedBrand && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'TypedBrand(...)';
}

/// Text in both app languages (contract `LocalizedText`).
@immutable
final class BilingualName {
  const BilingualName({required this.id, required this.en});

  final String id;
  final String en;

  /// The name for [languageCode]; Bahasa Indonesia unless English.
  String forLanguage(String languageCode) => languageCode == 'en' ? en : id;

  @override
  bool operator ==(Object other) =>
      other is BilingualName && other.id == id && other.en == en;

  @override
  int get hashCode => Object.hash(id, en);

  @override
  String toString() => 'BilingualName(…)';
}

/// What identifies an ingredient in the kitchen: a reference ID (KIT-04) or
/// a custom name (KIT-05).
@immutable
sealed class IngredientKey {
  const IngredientKey();
}

final class ReferenceIngredient extends IngredientKey {
  const ReferenceIngredient(this.ingredientId);

  final String ingredientId;

  @override
  bool operator ==(Object other) =>
      other is ReferenceIngredient && other.ingredientId == ingredientId;

  @override
  int get hashCode => ingredientId.hashCode;

  @override
  String toString() => 'ReferenceIngredient($ingredientId)';
}

/// The key the latest change wins on (KIT-16): `r:<id>` for a reference
/// ingredient, `c:<folded name>` for a custom one. The server folds custom
/// names a little more (NFKC); a name it folds together that this phone
/// does not is only queued twice, which the server orders correctly.
String ingredientKeyOf(IngredientKey key) => switch (key) {
  ReferenceIngredient(:final ingredientId) => 'r:$ingredientId',
  CustomIngredient(:final name) => 'c:${foldIngredientName(name)}',
};

final class CustomIngredient extends IngredientKey {
  const CustomIngredient(this.name);

  /// As the user typed it (the server stores it in NFC, trimmed).
  final String name;

  @override
  bool operator ==(Object other) =>
      other is CustomIngredient && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'CustomIngredient(…)';
}

/// One saved kitchen item (contract `KitchenItem`).
@immutable
final class KitchenEntry {
  const KitchenEntry({
    required this.id,
    required this.ingredientId,
    required this.displayName,
    required this.customName,
    required this.category,
    required this.state,
    required this.isDefaultStaple,
    required this.usageRank,
    required this.changedAt,
    required this.createdAt,
    this.quantity,
    this.brand,
  });

  /// Prefix of [id] for an item added on this phone that the server has not
  /// confirmed yet (KIT-16). Such an item has no server ID, so it cannot be
  /// put in a set yet.
  static const localIdPrefix = 'local:';

  final String id;

  /// Null exactly for a custom item.
  final String? ingredientId;

  /// The reference name; null for custom items and while the reference
  /// data is not available on the server.
  final BilingualName? displayName;
  final String? customName;
  final api.KitchenCategory category;
  final KitchenItemState state;
  final bool isDefaultStaple;

  /// KIT-06: 1 is the most used in its category; null until recorded
  /// (T-032).
  final int? usageRank;
  final DateTime changedAt;
  final DateTime createdAt;

  /// KIT-09 optional amount.
  final KitchenAmount? quantity;

  /// KIT-09 optional brand (SAF-07).
  final KitchenBrand? brand;

  /// Added on this phone and not on the server yet ([localIdPrefix]).
  bool get isLocalOnly => id.startsWith(localIdPrefix);

  /// KIT-05: Cek Aman does not know it, so it gives "Cek label" (SAF-09).
  bool get isCustom => ingredientId == null;

  bool get isAvailable => state == KitchenItemState.available;

  IngredientKey get key => switch (ingredientId) {
    final id? => ReferenceIngredient(id),
    null => CustomIngredient(customName ?? ''),
  };

  /// The key the latest change wins on ([ingredientKeyOf]).
  String get ingredientKey => ingredientKeyOf(key);

  KitchenEntry withState(KitchenItemState next) => copyWith(state: next);

  /// A copy with the given fields. [quantity] and [brand] are functions so
  /// that null can be set.
  KitchenEntry copyWith({
    api.KitchenCategory? category,
    KitchenItemState? state,
    KitchenAmount? Function()? quantity,
    KitchenBrand? Function()? brand,
    DateTime? changedAt,
  }) => KitchenEntry(
    id: id,
    ingredientId: ingredientId,
    displayName: displayName,
    customName: customName,
    category: category ?? this.category,
    state: state ?? this.state,
    isDefaultStaple: isDefaultStaple,
    usageRank: usageRank,
    changedAt: changedAt ?? this.changedAt,
    createdAt: createdAt,
    quantity: quantity == null ? this.quantity : quantity(),
    brand: brand == null ? this.brand : brand(),
  );

  @override
  String toString() => 'KitchenEntry($id, ${state.wire})';
}

/// The saved kitchen (contract `KitchenItemList`).
@immutable
final class KitchenList {
  const KitchenList({
    required this.items,
    required this.maxItems,
    required this.referenceVersion,
    required this.source,
  });

  /// In the API's order (KIT-03 category order).
  final List<KitchenEntry> items;

  /// The configured limit of items per household.
  final int maxItems;
  final String? referenceVersion;
  final DataSource source;

  bool get atLimit => items.length >= maxItems;

  KitchenEntry? byId(String id) => items.where((i) => i.id == id).firstOrNull;

  KitchenEntry? byIngredientId(String ingredientId) =>
      items.where((i) => i.ingredientId == ingredientId).firstOrNull;

  KitchenList copyWith({List<KitchenEntry>? items, DataSource? source}) =>
      KitchenList(
        items: items ?? this.items,
        maxItems: maxItems,
        referenceVersion: referenceVersion,
        source: source ?? this.source,
      );

  @override
  String toString() => 'KitchenList(${items.length} items)';
}

/// A reference ingredient for search and adding (contract
/// `CatalogIngredient`). Not a safety result.
@immutable
final class CatalogEntry {
  const CatalogEntry({
    required this.ingredientId,
    required this.displayName,
    required this.localNames,
    required this.category,
    required this.brandVaries,
    this.brands = const [],
  });

  final String ingredientId;
  final BilingualName displayName;

  /// Local, regional and alternative names (KIT-04).
  final List<String> localNames;

  /// Null when the reference data gives none (or this app version does not
  /// know the code): the app asks for one when it is added.
  final api.KitchenCategory? category;

  /// SAF-07 hint for offering to record a brand (KIT-09). Not a safety
  /// result.
  final bool brandVaries;

  /// The ingredient's brands in the verified reference data, the only ones
  /// the brand picker offers.
  final List<CatalogBrand> brands;

  @override
  String toString() => 'CatalogEntry($ingredientId)';
}

/// A reference brand of an ingredient (contract `CatalogBrand`). Not a
/// safety result.
@immutable
final class CatalogBrand {
  const CatalogBrand({required this.brandId, required this.name});

  final String brandId;
  final String name;

  @override
  String toString() => 'CatalogBrand($brandId)';
}

/// The whole reference catalog as kept on the phone (KIT-04).
@immutable
final class IngredientCatalog {
  IngredientCatalog({
    required this.referenceVersion,
    required this.etag,
    required this.items,
    required this.source,
  }) : _byId = {for (final i in items) i.ingredientId: i};

  final String referenceVersion;

  /// The server's ETag, sent back as `If-None-Match`; null if none was sent.
  final String? etag;
  final List<CatalogEntry> items;
  final DataSource source;
  final Map<String, CatalogEntry> _byId;

  CatalogEntry? byId(String ingredientId) => _byId[ingredientId];

  IngredientCatalog withSource(DataSource next) => IngredientCatalog(
    referenceVersion: referenceVersion,
    etag: etag,
    items: items,
    source: next,
  );

  @override
  String toString() => 'IngredientCatalog(${items.length} items)';
}

/// One search result (contract `IngredientSearchHit`).
@immutable
final class IngredientHit {
  const IngredientHit(this.ingredient, {required this.matchedName});

  final CatalogEntry ingredient;

  /// The local or regional name that matched; null when a display name
  /// matched.
  final String? matchedName;

  @override
  String toString() => 'IngredientHit(${ingredient.ingredientId})';
}

/// KIT-08 ingredient set (contract `IngredientSet`). Its name is the user's
/// own text and is never printed.
@immutable
final class IngredientSetInfo {
  const IngredientSetInfo({
    required this.id,
    required this.name,
    required this.itemIds,
    required this.updatedAt,
  });

  final String id;
  final String name;

  /// Server item IDs.
  final List<String> itemIds;
  final DateTime updatedAt;

  @override
  String toString() => 'IngredientSetInfo($id, ${itemIds.length} items)';
}

/// The household's sets (contract `IngredientSetList`).
@immutable
final class IngredientSets {
  const IngredientSets({
    required this.items,
    required this.maxSets,
    required this.source,
  });

  final List<IngredientSetInfo> items;
  final int maxSets;
  final DataSource source;

  bool get atLimit => items.length >= maxSets;

  IngredientSetInfo? byId(String id) =>
      items.where((s) => s.id == id).firstOrNull;

  IngredientSets copyWith({
    List<IngredientSetInfo>? items,
    DataSource? source,
  }) => IngredientSets(
    items: items ?? this.items,
    maxSets: maxSets,
    source: source ?? this.source,
  );

  @override
  String toString() => 'IngredientSets(${items.length})';
}

/// Contract `KitchenChangeOutcome`.
enum KitchenSyncOutcome { applied, superseded, rejected }

/// The server's answer to one queued change (contract
/// `KitchenChangeResult`).
@immutable
final class KitchenChangeAnswer {
  const KitchenChangeAnswer({
    required this.changeId,
    required this.outcome,
    required this.itemId,
    required this.errorCode,
  });

  final String changeId;
  final KitchenSyncOutcome outcome;
  final String? itemId;

  /// The wire code of a rejection; null otherwise.
  final String? errorCode;

  @override
  String toString() => 'KitchenChangeAnswer(${outcome.name}, $errorCode)';
}

/// The answer to a kitchen sync (contract `KitchenSyncResponse`).
@immutable
final class KitchenSyncAnswer {
  const KitchenSyncAnswer({
    required this.cursor,
    required this.full,
    required this.items,
    required this.removedItemIds,
    required this.results,
    required this.maxItems,
    required this.referenceVersion,
  });

  final String cursor;

  /// [items] is the whole kitchen.
  final bool full;
  final List<KitchenEntry> items;
  final List<String> removedItemIds;
  final List<KitchenChangeAnswer> results;
  final int maxItems;
  final String? referenceVersion;

  @override
  String toString() =>
      'KitchenSyncAnswer(full: $full, ${items.length} items, '
      '${results.length} results)';
}
