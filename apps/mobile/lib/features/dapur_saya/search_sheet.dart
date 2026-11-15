// K2 Search and add (screens.md K2; KIT-04).
//
// - The query goes to the API in a POST body (never in a URL) and is never
//   logged. Without internet, the catalog kept on the phone is searched
//   instead, and the sheet says so; with no copy on the phone it says
//   `kitchen.search.offlineNoCache`.
// - 503 `reference_data_unavailable` shows its own message, never "no
//   results"; adding a new (custom) ingredient still works then (AI-08).
// - "Tambah" adds the ingredient as "Ada" and keeps the sheet open; the row
//   then shows its state, which a tap toggles.
// Checklist mode (from the photo checklist) comes with T-039.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_problem.dart';
import '../../core/api/api_result.dart';
import '../../core/config/app_config.dart';
import '../../core/config/config_keys.dart';
import '../../core/theme/tokens.dart';
import '../../data/ingredient_search.dart';
import '../../data/kitchen_state.dart';
import '../../data/models/kitchen.dart';
import '../../data/repositories/kitchen_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../auth/widgets/onboarding_scaffold.dart'
    show InlineMessage, InlineMessageKind;
import '../keluarga_saya/widgets/family_widgets.dart' show SkeletonBlock;
import 'custom_item_screen.dart';
import 'labels.dart';
import 'widgets/kitchen_item_toggle.dart';
import 'widgets/kitchen_widgets.dart';

/// Opens K2 as a full-height sheet with the keyboard open.
Future<void> openKitchenSearch(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const KitchenSearchSheet(),
    );

sealed class _View {
  const _View();
}

final class _Idle extends _View {
  const _Idle();
}

final class _Searching extends _View {
  const _Searching();
}

final class _Hits extends _View {
  const _Hits(this.hits, {required this.fromPhone});

  final List<IngredientHit> hits;
  final bool fromPhone;
}

/// 503 `reference_data_unavailable`.
final class _Unavailable extends _View {
  const _Unavailable();
}

final class _OfflineNoCache extends _View {
  const _OfflineNoCache();
}

final class _Failed extends _View {
  const _Failed(this.failure);

  final ApiFailure failure;
}

class KitchenSearchSheet extends ConsumerStatefulWidget {
  const KitchenSearchSheet({super.key});

  @override
  ConsumerState<KitchenSearchSheet> createState() => _KitchenSearchSheetState();
}

class _KitchenSearchSheetState extends ConsumerState<KitchenSearchSheet> {
  final _query = TextEditingController();
  // Snackbars show inside the sheet, above its barrier.
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  Timer? _debounce;
  int _generation = 0;
  _View _view = const _Idle();
  String _searched = '';
  final Set<String> _adding = {};

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _changed(String text) {
    _debounce?.cancel();
    final query = text.trim();
    if (query.isEmpty) {
      _generation++;
      setState(() {
        _view = const _Idle();
        _searched = '';
      });
      return;
    }
    final wait = ref
        .read(appConfigProvider)
        .get(ConfigKeys.kitchenSearchDebounceMs);
    _debounce = Timer(Duration(milliseconds: wait), () => _search(query));
  }

  Future<void> _search(String query) async {
    _debounce?.cancel();
    if (query.isEmpty) return;
    final generation = ++_generation;
    setState(() => _view = const _Searching());
    final repo = ref.read(kitchenRepositoryProvider);
    final result = await repo.search(query);
    _View next;
    switch (result) {
      case Ok(:final value):
        next = _Hits(value, fromPhone: false);
      case Err(failure: NetworkFailure()):
        final cached = await repo.cachedCatalog();
        next = cached == null
            ? const _OfflineNoCache()
            : _Hits(searchCatalog(cached, query), fromPhone: true);
      case Err(:final failure)
          when failure.problemCode == ApiErrorCode.referenceDataUnavailable:
        next = const _Unavailable();
      case Err(:final failure):
        next = _Failed(failure);
    }
    if (!mounted || generation != _generation) return;
    setState(() {
      _view = next;
      _searched = query;
    });
  }

  Future<void> _add(CatalogEntry ingredient) async {
    final l10n = AppLocalizations.of(context);
    final category = ingredient.category == null
        ? await pickKitchenCategory(context)
        : null;
    if (ingredient.category == null && category == null) return;
    if (!mounted) return;
    setState(() => _adding.add(ingredient.ingredientId));
    final ApiResult<KitchenEntry> result;
    try {
      result = await ref
          .read(kitchenProvider.notifier)
          .add(
            ReferenceIngredient(ingredient.ingredientId),
            category: category,
          );
    } finally {
      // "Tambah" never stays disabled, whatever happened (T-033 M1).
      if (mounted) setState(() => _adding.remove(ingredient.ingredientId));
    }
    if (!mounted) return;
    if (result case Err(:final failure)) {
      final maxItems = switch (ref.read(kitchenProvider)) {
        KitchenLoaded(:final list) => list.maxItems,
        _ => null,
      };
      _snack(
        kitchenFailureText(
          l10n,
          failure,
          write: KitchenWrite.add,
          maxItems: maxItems,
        ),
      );
    }
  }

  void _snack(String text) => _messenger.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _addCustom(String query) async {
    final added = await openCustomItem(context, initialName: query);
    if (added && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final kitchen = ref.watch(kitchenProvider);
    final catalog = switch (ref.watch(catalogProvider)) {
      CatalogReady(:final catalog) => catalog,
      _ => null,
    };
    ref.listen<KitchenNotice?>(kitchenNoticesProvider, (_, notice) {
      if (notice == null || !(ModalRoute.of(context)?.isCurrent ?? false)) {
        return;
      }
      _snack(
        kitchenFailureText(
          l10n,
          notice.failure,
          write: KitchenWrite.toggle,
          name: kitchenItemName(context, notice.entry, catalog: catalog),
        ),
      );
    });

    final query = _query.text.trim();
    final view = _view;
    final children = <Widget>[
      switch (view) {
        _Idle() => Text(
          l10n.kitchenSearchEmpty,
          key: const Key('kitchen.search.empty'),
          style: theme.textTheme.bodyLarge,
        ),
        _Searching() => const Column(
          children: [
            SkeletonBlock(height: 56),
            SizedBox(height: SpacingTokens.s),
            SkeletonBlock(height: 56),
            SizedBox(height: SpacingTokens.s),
            SkeletonBlock(height: 56),
          ],
        ),
        _Hits(:final hits, :final fromPhone) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (fromPhone) ...[
              InlineMessage(
                key: const Key('kitchen.search.fromPhone'),
                kind: InlineMessageKind.info,
                text: l10n.kitchenSearchFromPhone,
              ),
              const SizedBox(height: SpacingTokens.m),
            ],
            if (hits.isEmpty)
              Text(
                l10n.kitchenSearchNoMatch(_searched),
                key: const Key('kitchen.search.noMatch'),
                style: theme.textTheme.bodyLarge,
              ),
            for (final hit in hits)
              _HitRow(
                hit: hit,
                inKitchen: switch (kitchen) {
                  KitchenLoaded(:final list) => list.byIngredientId(
                    hit.ingredient.ingredientId,
                  ),
                  _ => null,
                },
                sending: kitchen is KitchenLoaded ? kitchen.sending : const {},
                adding: _adding.contains(hit.ingredient.ingredientId),
                onAdd: () => _add(hit.ingredient),
              ),
          ],
        ),
        _Unavailable() => InlineMessage(
          key: const Key('kitchen.search.unavailable'),
          kind: InlineMessageKind.info,
          text: l10n.kitchenSearchUnavailable,
        ),
        _OfflineNoCache() => InlineMessage(
          key: const Key('kitchen.search.offlineNoCache'),
          kind: InlineMessageKind.info,
          text: l10n.kitchenSearchOfflineNoCache,
        ),
        _Failed() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InlineMessage(
              key: const Key('kitchen.search.error'),
              text: l10n.errorGenericBody,
            ),
            const SizedBox(height: SpacingTokens.m),
            FilledButton.tonal(
              key: const Key('kitchen.search.retry'),
              onPressed: () => _search(query),
              child: Text(l10n.commonRetry),
            ),
          ],
        ),
      },
      // A new ingredient can be added whenever something was searched,
      // also while the reference list is unavailable (custom items do not
      // need it).
      if (query.isNotEmpty &&
          query == _searched &&
          (view is _Hits || view is _Unavailable)) ...[
        const SizedBox(height: SpacingTokens.m),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const Key('kitchen.search.addCustom'),
            onPressed: () => _addCustom(query),
            icon: const Icon(Icons.add),
            label: Text(l10n.kitchenSearchAddCustom(query)),
          ),
        ),
      ],
    ];

    return ScaffoldMessenger(
      key: _messenger,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SpacingTokens.l,
                SpacingTokens.m,
                SpacingTokens.s,
                SpacingTokens.s,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('kitchen.search.field'),
                      controller: _query,
                      autofocus: true,
                      maxLength: customNameMaxLength,
                      textInputAction: TextInputAction.search,
                      // What the user types stays out of the keyboard's
                      // memory, and is never autocorrected away from a
                      // local name.
                      enableIMEPersonalizedLearning: false,
                      autocorrect: false,
                      onChanged: _changed,
                      onSubmitted: (text) => _search(text.trim()),
                      decoration: InputDecoration(
                        hintText: l10n.kitchenSearchHint,
                        labelText: l10n.kitchenSearchHint,
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        prefixIcon: const Icon(Icons.search),
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.xs),
                  IconButton(
                    key: const Key('kitchen.search.close'),
                    tooltip: l10n.commonClose,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  SpacingTokens.l,
                  SpacingTokens.s,
                  SpacingTokens.l,
                  SpacingTokens.xl,
                ),
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HitRow extends ConsumerWidget {
  const _HitRow({
    required this.hit,
    required this.inKitchen,
    required this.sending,
    required this.adding,
    required this.onAdd,
  });

  final IngredientHit hit;
  final KitchenEntry? inKitchen;
  final Set<String> sending;
  final bool adding;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final ingredient = hit.ingredient;
    final name = ingredient.displayName.forLanguage(language);
    final title = switch (hit.matchedName) {
      final alias? => l10n.kitchenSearchAlias(name, alias),
      null => name,
    };
    final category = ingredient.category ?? inKitchen?.category;
    final id = ingredient.ingredientId;
    final item = inKitchen;

    final Widget trailing = item != null
        ? KitchenItemToggle(
            key: Key('kitchen.search.state.$id'),
            name: name,
            available: item.isAvailable,
            sending: sending.contains(item.id),
            stateOnly: true,
            minHeight: ref
                .watch(appConfigProvider)
                .get(ConfigKeys.minTouchTargetDp)
                .toDouble(),
            onTap: () => ref.read(kitchenProvider.notifier).toggle(item.id),
          )
        : FilledButton.tonal(
            key: Key('kitchen.search.add.$id'),
            onPressed: adding ? null : onAdd,
            child: Text(l10n.kitchenSearchAdd),
          );

    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        if (category != null)
          Text(
            kitchenCategoryLabel(l10n, category),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
    // At large text the action moves under the name (accessibility.md 3.2).
    final large = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    // "Tambah" is read with the name and category in one node; the state
    // chip already names the ingredient itself.
    final Widget row = Padding(
      key: Key('kitchen.search.hit.$id'),
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.s),
      child: large
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                texts,
                const SizedBox(height: SpacingTokens.s),
                trailing,
              ],
            )
          : Row(
              children: [
                Expanded(child: texts),
                const SizedBox(width: SpacingTokens.m),
                trailing,
              ],
            ),
    );
    return item == null ? MergeSemantics(child: row) : row;
  }
}
