// K4 item sheet (screens.md K4), T-033 part: the ingredient's name and
// toggle, the custom-item note (KIT-05, SAF-09) and "Hapus dari Dapur
// Saya" with Undo. Amount, brand and sets (KIT-08, KIT-09) come with T-034.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_result.dart';
import '../../core/config/app_config.dart';
import '../../core/config/config_keys.dart';
import '../../core/theme/tokens.dart';
import '../../data/kitchen_state.dart';
import '../../data/models/kitchen.dart';
import '../../l10n/generated/app_localizations.dart';
import '../auth/widgets/onboarding_scaffold.dart' show InlineMessage;
import 'labels.dart';
import 'widgets/kitchen_item_toggle.dart';
import 'widgets/kitchen_widgets.dart';

/// Opens K4 for [itemId]. After a removal, [onRemoved] runs with the item
/// as it was, so the list screen can offer Undo.
Future<void> openKitchenItemSheet(
  BuildContext context,
  String itemId, {
  required void Function(KitchenEntry removed) onRemoved,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => KitchenItemSheet(itemId: itemId, onRemoved: onRemoved),
);

class KitchenItemSheet extends ConsumerStatefulWidget {
  const KitchenItemSheet({
    super.key,
    required this.itemId,
    required this.onRemoved,
  });

  final String itemId;
  final void Function(KitchenEntry removed) onRemoved;

  @override
  ConsumerState<KitchenItemSheet> createState() => _KitchenItemSheetState();
}

class _KitchenItemSheetState extends ConsumerState<KitchenItemSheet> {
  bool _removing = false;
  String? _message;

  Future<void> _remove(KitchenEntry item) async {
    setState(() {
      _removing = true;
      _message = null;
    });
    final kitchen = ref.read(kitchenProvider.notifier);
    final result = await kitchen.remove(item.id);
    if (!mounted) return;
    switch (result) {
      case Ok():
        Navigator.of(context).pop();
        widget.onRemoved(item);
      case Err(:final failure):
        final l10n = AppLocalizations.of(context);
        setState(() {
          _removing = false;
          _message = kitchenFailureText(
            l10n,
            failure,
            write: KitchenWrite.remove,
          );
        });
    }
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
      if (notice == null || notice.entry.id != widget.itemId) return;
      setState(
        () => _message = kitchenFailureText(
          l10n,
          notice.failure,
          write: KitchenWrite.toggle,
          name: kitchenItemName(context, notice.entry, catalog: catalog),
        ),
      );
    });

    final item = switch (state) {
      KitchenLoaded(:final list) => list.byId(widget.itemId),
      _ => null,
    };
    if (item == null) {
      // Removed, or the session changed: nothing to show.
      if (!_removing) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).maybePop();
        });
      }
      return const SizedBox(height: 48);
    }
    final sending = state is KitchenLoaded && state.sending.contains(item.id);
    final name = kitchenItemName(context, item, catalog: catalog);
    final config = ref.watch(appConfigProvider);

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
              sending: sending,
              minHeight: config
                  .get(ConfigKeys.kitchenToggleMinHeightDp)
                  .toDouble(),
              onTap: () {
                setState(() => _message = null);
                ref.read(kitchenProvider.notifier).toggle(item.id);
              },
            ),
          ),
          if (item.isCustom) ...[
            const SizedBox(height: SpacingTokens.l),
            KitchenInfoNote(
              key: const Key('kitchen.sheet.customNote'),
              text: l10n.kitchenCustomNote,
            ),
          ],
          if (_message case final message?) ...[
            const SizedBox(height: SpacingTokens.l),
            InlineMessage(key: const Key('kitchen.sheet.error'), text: message),
          ],
          const SizedBox(height: SpacingTokens.xl),
          OutlinedButton.icon(
            key: const Key('kitchen.sheet.remove'),
            onPressed: _removing ? null : () => unawaited(_remove(item)),
            icon: const Icon(Icons.delete_outline),
            label: Text(l10n.kitchenItemRemove),
          ),
        ],
      ),
    );
  }
}
