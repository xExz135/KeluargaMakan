// Labels and order for Dapur Saya (screens.md K1).
//
// Category labels come from the app's own strings for the API codes
// (contract `KitchenCategory`); ingredient names come from the reference
// data or, for custom items, are the user's own text.

import 'package:flutter/widgets.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../../data/models/kitchen.dart';
import '../../l10n/generated/app_localizations.dart';

String kitchenCategoryLabel(AppLocalizations l10n, api.KitchenCategory c) =>
    switch (c) {
      api.KitchenCategory.protein => l10n.kitchenCategoryProtein,
      api.KitchenCategory.vegetables => l10n.kitchenCategoryVegetables,
      api.KitchenCategory.fruit => l10n.kitchenCategoryFruit,
      api.KitchenCategory.spicesAromatics => l10n.kitchenCategorySpices,
      api.KitchenCategory.staples => l10n.kitchenCategoryStaples,
      api.KitchenCategory.saucesCondiments => l10n.kitchenCategorySauces,
      api.KitchenCategory.dairy => l10n.kitchenCategoryDairy,
      api.KitchenCategory.frozen => l10n.kitchenCategoryFrozen,
      api.KitchenCategory.leftovers => l10n.kitchenCategoryLeftovers,
    };

/// The name shown for [item]: the custom name as typed, the reference name
/// in the app language, the catalog's name while the server has none
/// (reference data unavailable), or a placeholder.
String kitchenItemName(
  BuildContext context,
  KitchenEntry item, {
  IngredientCatalog? catalog,
}) {
  final language = Localizations.localeOf(context).languageCode;
  if (item.customName case final custom?) return custom;
  final name =
      item.displayName ??
      switch (item.ingredientId) {
        final id? => catalog?.byId(id)?.displayName,
        null => null,
      };
  return name?.forLanguage(language) ??
      AppLocalizations.of(context).kitchenItemNameUnavailable;
}

/// One category's items in display order (screens.md K1, KIT-06): the most
/// used first, ranked by the server (`usageRank`), up to [frequentCount];
/// then a "Lainnya" divider and the rest from A to Z. While no item has a
/// rank (until T-032 records use), everything is A to Z.
///
/// [rankOf] is the hook for a local fallback rank (for example from toggle
/// counts on this phone); by default only the server's rank is used.
({List<KitchenEntry> frequent, List<KitchenEntry> other}) orderCategoryItems(
  List<KitchenEntry> items, {
  required int frequentCount,
  required String Function(KitchenEntry) nameOf,
  int? Function(KitchenEntry)? rankOf,
}) {
  int? rank(KitchenEntry e) => rankOf?.call(e) ?? e.usageRank;
  int byName(KitchenEntry a, KitchenEntry b) {
    final c = nameOf(a).toLowerCase().compareTo(nameOf(b).toLowerCase());
    return c != 0 ? c : a.id.compareTo(b.id);
  }

  final ranked =
      [
        for (final e in items)
          if (rank(e) != null) e,
      ]..sort((a, b) {
        final c = rank(a)!.compareTo(rank(b)!);
        return c != 0 ? c : byName(a, b);
      });
  final frequent = ranked.take(frequentCount).toList();
  final frequentIds = {for (final e in frequent) e.id};
  final other = [
    for (final e in items)
      if (!frequentIds.contains(e.id)) e,
  ]..sort(byName);
  return (frequent: frequent, other: other);
}

/// KIT-09 amount label.
String kitchenAmountLabel(AppLocalizations l10n, KitchenAmount amount) =>
    switch (amount) {
      KitchenAmount.little => l10n.quantityLittle,
      KitchenAmount.some => l10n.quantitySome,
      KitchenAmount.plenty => l10n.quantityPlenty,
    };

/// The second line of an item (components.md 8.5): "Sedikit · {brand}", or
/// null when neither is recorded. A brand is only a name here, never a
/// safety mark.
String? kitchenItemDetails(AppLocalizations l10n, KitchenEntry item) {
  final parts = [
    if (item.quantity case final amount?) kitchenAmountLabel(l10n, amount),
    if (item.brand case final brand?) brand.name,
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

/// The name of [ingredient] when no item is left to name it (a refused or
/// overwritten change): the custom name, or the catalog's name.
String kitchenIngredientName(
  BuildContext context,
  IngredientKey ingredient, {
  KitchenEntry? item,
  IngredientCatalog? catalog,
}) {
  if (item != null) return kitchenItemName(context, item, catalog: catalog);
  final language = Localizations.localeOf(context).languageCode;
  return switch (ingredient) {
    CustomIngredient(:final name) => name,
    ReferenceIngredient(:final ingredientId) =>
      catalog?.byId(ingredientId)?.displayName.forLanguage(language) ??
          AppLocalizations.of(context).kitchenItemNameUnavailable,
  };
}
