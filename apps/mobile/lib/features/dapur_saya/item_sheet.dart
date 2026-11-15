// K4 item sheet (screens.md K4; KIT-02, KIT-05, KIT-08, KIT-09, KIT-16,
// SAF-07, SAF-09).
//
// - The ingredient's name and toggle, the custom-item note, the amount
//   (Sedikit, Cukup, Banyak, or cleared), the brand for sauces, bouillon
//   and packaged items, "Masukkan ke set", and "Hapus dari Dapur Saya" with
//   Undo on the list.
// - Every field works without internet: the change shows at once and is
//   queued (KIT-16); the sheet says it is saved on the phone until sent.
// - Brand notes never call a brand safe or verified. No brand:
//   `kitchen.brand.why`. A typed brand: `kitchen.brand.unknownNote` (Cek
//   Aman keeps "Cek label", SAF-07). A listed brand: no note.
// - The sheet follows the ingredient, not the item ID, so it stays open
//   when an item added without internet gets its server ID.
// - Amount chips wrap instead of a segmented button, so all three fit at
//   200% text on a small phone.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../../core/config/app_config.dart';
import '../../core/config/config_keys.dart';
import '../../core/theme/tokens.dart';
import '../../data/kitchen_state.dart';
import '../../data/models/kitchen.dart';
import '../../l10n/generated/app_localizations.dart';
import '../auth/widgets/onboarding_scaffold.dart'
    show InlineMessage, InlineMessageKind;
import 'brand_picker.dart';
import 'labels.dart';
import 'sets_screen.dart' show openAddToSet;
import 'widgets/kitchen_item_toggle.dart';
import 'widgets/kitchen_widgets.dart';

/// Opens K4 for [itemId]. After a removal, [onRemoved] runs with the item
/// as it was, so the list screen can offer Undo.
Future<void> openKitchenItemSheet(
  BuildContext context,
  String itemId, {
  required void Function(KitchenEntry removed) onRemoved,
}) {
  final container = ProviderScope.containerOf(context, listen: false);
  final state = container.read(kitchenProvider);
  final item = state is KitchenLoaded ? state.list.byId(itemId) : null;
  if (item == null) return Future.value();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => KitchenItemSheet(
      ingredientKey: item.ingredientKey,
      onRemoved: onRemoved,
    ),
  );
}

/// Whether K4 offers a brand for [item] (screens.md K4): brand-varying
/// reference ingredients (catalog `brandVaries`, SAF-07), sauces and
/// condiments, and any item that already has one.
bool offersBrand(KitchenEntry item, IngredientCatalog? catalog) {
  if (item.brand != null) return true;
  if (item.category == api.KitchenCategory.saucesCondiments) return true;
  final id = item.ingredientId;
  return id != null && (catalog?.byId(id)?.brandVaries ?? false);
}

class KitchenItemSheet extends ConsumerStatefulWidget {
  const KitchenItemSheet({
    super.key,
    required this.ingredientKey,
    required this.onRemoved,
  });

  /// The ingredient shown ([ingredientKeyOf]).
  final String ingredientKey;
  final void Function(KitchenEntry removed) onRemoved;

  @override
  ConsumerState<KitchenItemSheet> createState() => _KitchenItemSheetState();
}

class _KitchenItemSheetState extends ConsumerState<KitchenItemSheet> {
  bool _removed = false;
  String? _message;

  KitchenEntry? _find(KitchenState state) => switch (state) {
    KitchenLoaded(:final list) =>
      list.items
          .where((i) => i.ingredientKey == widget.ingredientKey)
          .firstOrNull,
    _ => null,
  };

  void _remove(KitchenEntry item) {
    final removed = ref.read(kitchenProvider.notifier).remove(item.id);
    if (removed == null) return;
    _removed = true;
    Navigator.of(context).pop();
    widget.onRemoved(removed);
  }

  Future<void> _pickBrand(KitchenEntry item, IngredientCatalog? catalog) async {
    final id = item.ingredientId;
    final ingredient = id == null ? null : catalog?.byId(id);
    final brand = await pickKitchenBrand(
      context,
      ingredientName: kitchenItemName(context, item, catalog: catalog),
      // Only the verified brands of this ingredient (KIT-09, SAF-07).
      brands: ingredient?.brands ?? const [],
      allowListed: !item.isCustom && ingredient != null,
    );
    if (brand == null || !mounted) return;
    final current = _find(ref.read(kitchenProvider));
    if (current == null) return;
    ref.read(kitchenProvider.notifier).setBrand(current.id, brand);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(kitchenProvider);
    final catalog = switch (ref.watch(catalogProvider)) {
      CatalogReady(:final catalog) => catalog,
      _ => null,
    };
    ref.listen<KitchenNotice?>(kitchenNoticesProvider, (_, notice) {
      final ingredient = switch (notice) {
        KitchenChangeRefused(:final ingredient) => ingredient,
        KitchenOverwritten(:final ingredient) => ingredient,
        _ => null,
      };
      if (notice == null ||
          ingredient == null ||
          ingredientKeyOf(ingredient) != widget.ingredientKey) {
        return;
      }
      setState(
        () => _message = kitchenNoticeText(
          l10n,
          notice,
          nameOf: (key, item) =>
              kitchenIngredientName(context, key, item: item, catalog: catalog),
        ),
      );
    });

    final item = _find(state);
    if (item == null) {
      // Removed (here or on another phone), or the session changed.
      if (!_removed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).maybePop();
        });
      }
      return const SizedBox(height: 48);
    }
    final pending = state is KitchenLoaded && state.pending.contains(item.id);
    final name = kitchenItemName(context, item, catalog: catalog);
    final config = ref.watch(appConfigProvider);
    final kitchen = ref.read(kitchenProvider.notifier);

    return SingleChildScrollView(
      key: const Key('kitchen.sheet'),
      padding: const EdgeInsets.fromLTRB(
        SpacingTokens.l,
        0,
        SpacingTokens.l,
        SpacingTokens.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(name, style: theme.textTheme.titleLarge),
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            kitchenCategoryLabel(l10n, item.category),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: SpacingTokens.m),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: KitchenItemToggle(
              key: const Key('kitchen.sheet.toggle'),
              name: name,
              available: item.isAvailable,
              isCustom: item.isCustom,
              pending: pending,
              minHeight: config
                  .get(ConfigKeys.kitchenToggleMinHeightDp)
                  .toDouble(),
              onTap: () {
                setState(() => _message = null);
                kitchen.toggle(item.id);
              },
            ),
          ),
          if (pending) ...[
            const SizedBox(height: SpacingTokens.s),
            Text(
              l10n.kitchenItemPendingNote,
              key: const Key('kitchen.sheet.pendingNote'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (item.isCustom) ...[
            const SizedBox(height: SpacingTokens.l),
            KitchenInfoNote(
              key: const Key('kitchen.sheet.customNote'),
              text: l10n.kitchenCustomNote,
            ),
          ],
          if (_message case final message?) ...[
            const SizedBox(height: SpacingTokens.l),
            InlineMessage(
              key: const Key('kitchen.sheet.message'),
              kind: InlineMessageKind.info,
              text: message,
            ),
          ],
          const SizedBox(height: SpacingTokens.xl),
          _Amount(
            selected: item.quantity,
            onSelected: (amount) => kitchen.setQuantity(item.id, amount),
          ),
          if (offersBrand(item, catalog)) ...[
            const SizedBox(height: SpacingTokens.xl),
            _Brand(
              brand: item.brand,
              onPick: () => _pickBrand(item, catalog),
              onClear: () => kitchen.setBrand(item.id, null),
            ),
          ],
          const SizedBox(height: SpacingTokens.xl),
          if (item.isLocalOnly)
            Text(
              l10n.kitchenSetsLocalItemNote,
              key: const Key('kitchen.sheet.setLater'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            OutlinedButton.icon(
              key: const Key('kitchen.sheet.addToSet'),
              onPressed: () => openAddToSet(context, item.id),
              icon: const Icon(Icons.playlist_add),
              label: Text(l10n.kitchenItemAddToSet),
            ),
          const SizedBox(height: SpacingTokens.m),
          OutlinedButton.icon(
            key: const Key('kitchen.sheet.remove'),
            onPressed: () => _remove(item),
            icon: const Icon(Icons.delete_outline),
            label: Text(l10n.kitchenItemRemove),
          ),
        ],
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount({required this.selected, required this.onSelected});

  final KitchenAmount? selected;
  final ValueChanged<KitchenAmount?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.kitchenItemQuantity,
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: SpacingTokens.s),
        Wrap(
          spacing: SpacingTokens.s,
          runSpacing: SpacingTokens.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final amount in KitchenAmount.values)
              ChoiceChip(
                key: Key('kitchen.sheet.amount.${amount.wire}'),
                label: Text(kitchenAmountLabel(l10n, amount)),
                selected: selected == amount,
                onSelected: (_) => onSelected(amount),
              ),
            TextButton(
              key: const Key('kitchen.sheet.amount.clear'),
              onPressed: selected == null ? null : () => onSelected(null),
              child: Text(l10n.kitchenItemQuantityClear),
            ),
          ],
        ),
      ],
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({
    required this.brand,
    required this.onPick,
    required this.onClear,
  });

  final KitchenBrand? brand;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final brand = this.brand;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.kitchenBrandTitle,
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: SpacingTokens.s),
        if (brand != null) ...[
          Text(
            brand.name,
            key: const Key('kitchen.sheet.brand.name'),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: SpacingTokens.s),
        ],
        Wrap(
          spacing: SpacingTokens.s,
          runSpacing: SpacingTokens.s,
          children: [
            FilledButton.tonal(
              key: const Key('kitchen.sheet.brand.pick'),
              onPressed: onPick,
              child: Text(
                brand == null ? l10n.kitchenBrandPick : l10n.kitchenBrandChange,
              ),
            ),
            if (brand != null)
              TextButton(
                key: const Key('kitchen.sheet.brand.clear'),
                onPressed: onClear,
                child: Text(l10n.kitchenBrandClear),
              ),
          ],
        ),
        const SizedBox(height: SpacingTokens.s),
        switch (brand) {
          null => KitchenInfoNote(
            key: const Key('kitchen.sheet.brand.why'),
            text: l10n.kitchenBrandWhy,
          ),
          // SAF-07: a typed brand is never a recorded brand.
          TypedBrand() => KitchenInfoNote(
            key: const Key('kitchen.sheet.brand.typedNote'),
            text: l10n.kitchenBrandUnknownNote,
          ),
          ReferenceBrand() => const SizedBox.shrink(),
        },
      ],
    );
  }
}
