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

/// One saved kitchen item (contract `KitchenItem`). Quantity and brand
/// (KIT-09) arrive with T-034.
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
  });

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

  /// KIT-05: Cek Aman does not know it, so it gives "Cek label" (SAF-09).
  bool get isCustom => ingredientId == null;

  bool get isAvailable => state == KitchenItemState.available;

  IngredientKey get key => switch (ingredientId) {
    final id? => ReferenceIngredient(id),
    null => CustomIngredient(customName ?? ''),
  };

  KitchenEntry withState(KitchenItemState next) => KitchenEntry(
    id: id,
    ingredientId: ingredientId,
    displayName: displayName,
    customName: customName,
    category: category,
    state: next,
    isDefaultStaple: isDefaultStaple,
    usageRank: usageRank,
    changedAt: changedAt,
    createdAt: createdAt,
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
  });

  final String ingredientId;
  final BilingualName displayName;

  /// Local, regional and alternative names (KIT-04).
  final List<String> localNames;

  /// Null when the reference data gives none (or this app version does not
  /// know the code): the app asks for one when it is added.
  final api.KitchenCategory? category;

  /// SAF-07 hint for recording a brand (T-034). Not a safety result.
  final bool brandVaries;

  @override
  String toString() => 'CatalogEntry($ingredientId)';
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
