// K1 Dapur Saya list (screens.md K1; KIT-01 to KIT-07, NFR-02, NFR-15).
//
// - Sections in the nine KIT-03 categories, labeled from the API codes;
//   empty categories are hidden. Within a category the most used items
//   come first (KIT-06, the server's rank; A to Z until T-032 records use).
// - One tap toggles "Ada" and "Habis" from local state at once, with or
//   without internet; the change is queued and synced (KIT-16). The app
//   bar caption says "Tersimpan", "Mengirim perubahan…" or "Belum terkirim
//   · {n} perubahan"; items with an unsent change carry a dot. A change the
//   server refuses for good goes back with a message; a newer change from
//   another phone wins and says so.
// - Default staples (KIT-07) are items like any other.
// - Custom items carry "Belum dikenal" (KIT-05); Cek Aman gives them "Cek
//   label" (SAF-09). Nothing here is a safety state and nothing says
//   "aman".
// - Without internet the phone's copy is shown (household data, bound to
//   the account) with `state.offline.banner`, and everything still works.
// - The sets row (KIT-08) with "Tandai semua ada"; amounts and brands
//   (KIT-09) on the second line of an item. Photo setup comes with T-039.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../../app/widgets/section_scaffold.dart';
import '../../core/api/api_error_text.dart';
import '../../core/config/app_config.dart';
import '../../core/config/config_keys.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/theme/tokens.dart';
import '../../data/kitchen_state.dart';
import '../../data/models/kitchen.dart';
import '../../data/sets_state.dart';
import '../../l10n/generated/app_localizations.dart';
import '../auth/widgets/onboarding_scaffold.dart'
    show InlineMessage, InlineMessageKind;
import '../keluarga_saya/widgets/family_widgets.dart'
    show ErrorPanel, SectionCard, SkeletonBlock;
import 'custom_item_screen.dart';
import 'item_sheet.dart';
import 'labels.dart';
import 'search_sheet.dart';
import 'sets_screen.dart';
import 'widgets/kitchen_item_toggle.dart';
import 'widgets/kitchen_widgets.dart';

enum KitchenFilter { all, available, out }

class DapurSayaScreen extends ConsumerStatefulWidget {
  const DapurSayaScreen({super.key});

  @override
  ConsumerState<DapurSayaScreen> createState() => _DapurSayaScreenState();
}

class _DapurSayaScreenState extends ConsumerState<DapurSayaScreen> {
  KitchenFilter _filter = KitchenFilter.all;
  final Set<api.KitchenCategory> _collapsed = {};

  IngredientCatalog? get _catalog => switch (ref.read(catalogProvider)) {
    CatalogReady(:final catalog) => catalog,
    _ => null,
  };

  void _onRemoved(KitchenEntry removed) {
    final l10n = AppLocalizations.of(context);
    final name = kitchenItemName(context, removed, catalog: _catalog);
    final config = ref.read(appConfigProvider);
    showKitchenSnack(
      context,
      l10n.kitchenItemRemoved(name),
      duration: Duration(milliseconds: config.get(ConfigKeys.snackbarActionMs)),
      action: SnackBarAction(
        key: const Key('kitchen.removed.undo'),
        label: l10n.commonUndo,
        onPressed: () => ref.read(kitchenProvider.notifier).restore(removed),
      ),
    );
  }

  Future<void> _openMenu() async {
    final l10n = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                key: const Key('kitchen.menu.search'),
                leading: const Icon(Icons.search),
                title: Text(l10n.kitchenMenuSearch),
                onTap: () => Navigator.of(context).pop('search'),
              ),
              ListTile(
                key: const Key('kitchen.menu.custom'),
                leading: const Icon(Icons.edit_outlined),
                title: Text(l10n.kitchenMenuCustom),
                onTap: () => Navigator.of(context).pop('custom'),
              ),
              const SizedBox(height: SpacingTokens.s),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 'search':
        await openKitchenSearch(context);
      case 'custom':
        await openCustomItem(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(kitchenProvider);
    // Watching keeps the catalog download going, for offline search.
    final catalogState = ref.watch(catalogProvider);
    final catalog = catalogState is CatalogReady ? catalogState.catalog : null;
    final kitchen = ref.read(kitchenProvider.notifier);

    ref.listen<KitchenNotice?>(kitchenNoticesProvider, (_, notice) {
      if (notice == null || !(ModalRoute.of(context)?.isCurrent ?? true)) {
        return;
      }
      showKitchenSnack(
        context,
        kitchenNoticeText(
          l10n,
          notice,
          nameOf: (ingredient, item) => kitchenIngredientName(
            context,
            ingredient,
            item: item,
            catalog: catalog,
          ),
        ),
      );
    });

    final Widget body = switch (state) {
      KitchenLoading() => const _Skeleton(),
      KitchenLoadFailed(:final failure) => _Scroll(
        children: [
          ErrorPanel(
            key: const Key('kitchen.error'),
            title: ApiErrorText.of(l10n, failure).title,
            body: ApiErrorText.of(l10n, failure).body,
            retryKey: const Key('kitchen.retry'),
            onRetry: kitchen.reload,
          ),
        ],
      ),
      KitchenLoaded(:final list, :final pending, :final sync) =>
        RefreshIndicator(
          onRefresh: () => Future.wait([
            kitchen.refresh(),
            ref.read(catalogProvider.notifier).refresh(),
            ref.read(setsProvider.notifier).reload(),
          ]),
          child: _list(context, list, pending, sync, catalog),
        ),
    };
    final sync = state is KitchenLoaded ? state.sync : null;

    return SectionScaffold(
      title: l10n.kitchenTitle,
      subtitle: sync == null ? null : KitchenSyncCaption(status: sync),
      subtitleText: sync == null
          ? null
          : sync.sending
          ? l10n.kitchenSyncSyncing
          : sync.pendingCount > 0
          ? l10n.kitchenSyncPending(sync.pendingCount)
          : l10n.kitchenSyncSaved,
      body: body,
      floatingActionButton: state is KitchenLoaded
          ? FloatingActionButton.extended(
              key: const Key('kitchen.fab'),
              onPressed: _openMenu,
              icon: const Icon(Icons.add),
              label: Text(l10n.kitchenFab),
            )
          : null,
    );
  }

  Widget _list(
    BuildContext context,
    KitchenList list,
    Set<String> pending,
    KitchenSyncStatus sync,
    IngredientCatalog? catalog,
  ) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final config = ref.watch(appConfigProvider);
    final minHeight = config.get(ConfigKeys.kitchenToggleMinHeightDp);
    final frequentCount = config.get(ConfigKeys.kitchenFrequentCount);
    String nameOf(KitchenEntry e) =>
        kitchenItemName(context, e, catalog: catalog);

    bool shown(KitchenEntry e) => switch (_filter) {
      KitchenFilter.all => true,
      KitchenFilter.available => e.isAvailable,
      KitchenFilter.out => !e.isAvailable,
    };

    Widget toggle(KitchenEntry e) => KitchenItemToggle(
      key: Key('kitchen.item.${e.id}'),
      name: nameOf(e),
      available: e.isAvailable,
      isCustom: e.isCustom,
      pending: pending.contains(e.id),
      details: kitchenItemDetails(l10n, e),
      minHeight: minHeight.toDouble(),
      onTap: () => ref.read(kitchenProvider.notifier).toggle(e.id),
      onLongPress: () =>
          openKitchenItemSheet(context, e.id, onRemoved: _onRemoved),
    );

    final sections = <Widget>[];
    for (final category in kitchenCategoryOrder) {
      final all = [
        for (final e in list.items)
          if (e.category == category) e,
      ];
      final visible = all.where(shown).toList();
      if (visible.isEmpty) continue;
      final order = orderCategoryItems(
        visible,
        frequentCount: frequentCount,
        nameOf: nameOf,
      );
      sections.add(
        _CategorySection(
          category: category,
          available: all.where((e) => e.isAvailable).length,
          out: all.where((e) => !e.isAvailable).length,
          collapsed: _collapsed.contains(category),
          onToggle: () => setState(() {
            if (!_collapsed.remove(category)) _collapsed.add(category);
          }),
          frequent: [for (final e in order.frequent) toggle(e)],
          other: [for (final e in order.other) toggle(e)],
        ),
      );
    }

    return _Scroll(
      children: [
        if (sync.problem == KitchenSyncProblem.offline) ...[
          InlineMessage(
            key: const Key('kitchen.offline'),
            kind: InlineMessageKind.info,
            text: l10n.stateOfflineBanner,
          ),
          const SizedBox(height: SpacingTokens.m),
        ],
        if (sync.problem == KitchenSyncProblem.failed &&
            sync.pendingCount > 0) ...[
          InlineMessage(
            key: const Key('kitchen.sync.failed'),
            kind: InlineMessageKind.info,
            text: l10n.kitchenSyncFailed,
          ),
          const SizedBox(height: SpacingTokens.s),
        ],
        if (sync.problem != null && sync.pendingCount > 0) ...[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const Key('kitchen.sync.retry'),
              onPressed: ref.read(kitchenProvider.notifier).syncNow,
              icon: const Icon(Icons.sync),
              label: Text(l10n.kitchenSyncRetryNow),
            ),
          ),
          const SizedBox(height: SpacingTokens.m),
        ],
        _SearchField(onTap: () => openKitchenSearch(context)),
        const SizedBox(height: SpacingTokens.l),
        _SetsRow(list: list),
        const SizedBox(height: SpacingTokens.l),
        if (list.items.isEmpty)
          SectionCard(
            key: const Key('kitchen.empty'),
            title: l10n.kitchenEmptyTitle,
            children: [
              Text(l10n.kitchenEmptyBody),
              const SizedBox(height: SpacingTokens.m),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.tonal(
                  key: const Key('kitchen.empty.list'),
                  onPressed: () => openKitchenSearch(context),
                  child: Text(l10n.promptKitchenList),
                ),
              ),
            ],
          )
        else ...[
          _FilterChips(
            selected: _filter,
            onSelected: (f) => setState(() => _filter = f),
          ),
          const SizedBox(height: SpacingTokens.l),
          if (sections.isEmpty)
            Text(
              _filter == KitchenFilter.out
                  ? l10n.kitchenFilterEmptyOut
                  : l10n.kitchenFilterEmptyAvailable,
              key: const Key('kitchen.filter.empty'),
              style: theme.textTheme.bodyLarge,
            ),
          for (final section in sections) ...[
            section,
            const SizedBox(height: SpacingTokens.l),
          ],
        ],
        if (list.atLimit)
          Text(
            l10n.kitchenLimitReached(list.maxItems),
            key: const Key('kitchen.limit'),
            style: theme.textTheme.bodyMedium,
          ),
        // Room above the FAB.
        const SizedBox(height: 96),
      ],
    );
  }
}

/// K1 sets row (KIT-08): title, "Kelola" and one card per set. Sideways at
/// normal text, a vertical list from text scale 1.3 (screens.md K1).
class _SetsRow extends ConsumerWidget {
  const _SetsRow({required this.list});

  final KitchenList list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(setsProvider);
    final sets = state is SetsLoaded
        ? state.sets.items
        : const <IngredientSetInfo>[];
    final vertical = MediaQuery.textScalerOf(context).scale(1) >= 1.3;
    final cards = [
      for (final set in sets)
        SetCard(
          set: set,
          count: setItemsIn(set, list).length,
          onMarkAll: () => markSetAvailable(context, ref, set),
        ),
    ];
    return Column(
      key: const Key('kitchen.sets.row'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  l10n.kitchenSetsTitle,
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ),
            TextButton(
              key: const Key('kitchen.sets.manage'),
              onPressed: () => openKitchenSets(context),
              child: Text(l10n.kitchenSetsManage),
            ),
          ],
        ),
        if (state is SetsLoaded && sets.isEmpty)
          Text(
            l10n.kitchenSetsEmpty,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else if (vertical)
          for (final card in cards) ...[
            card,
            const SizedBox(height: SpacingTokens.s),
          ]
        else if (cards.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final card in cards)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: SpacingTokens.s,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 160,
                        maxWidth: 240,
                      ),
                      child: card,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Scroll extends StatelessWidget {
  const _Scroll({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.symmetric(vertical: SpacingTokens.l),
    children: [
      ContentFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ],
  );
}

/// Skeleton chips per category (first open on a new phone).
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    const chips = Wrap(
      spacing: SpacingTokens.s,
      runSpacing: SpacingTokens.s,
      children: [
        SizedBox(width: 96, child: SkeletonBlock(height: 56)),
        SizedBox(width: 120, child: SkeletonBlock(height: 56)),
        SizedBox(width: 80, child: SkeletonBlock(height: 56)),
      ],
    );
    return _Scroll(
      key: const Key('kitchen.loading'),
      children: [
        const SkeletonBlock(height: 56),
        const SizedBox(height: SpacingTokens.l),
        for (var i = 0; i < 3; i++) ...const [
          SizedBox(width: 140, child: SkeletonBlock(height: 24)),
          SizedBox(height: SpacingTokens.s),
          chips,
          SizedBox(height: SpacingTokens.l),
        ],
      ],
    );
  }
}

/// Looks like a search field and opens K2.
class _SearchField extends StatelessWidget {
  const _SearchField({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final app = AppColors.of(context);
    return Semantics(
      button: true,
      label: l10n.kitchenSearchHint,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: theme.colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.full),
          side: BorderSide(color: app.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('kitchen.search.open'),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.l,
                vertical: SpacingTokens.s,
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: SpacingTokens.m),
                  Expanded(
                    child: Text(
                      l10n.kitchenSearchHint,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onSelected});

  final KitchenFilter selected;
  final ValueChanged<KitchenFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String label(KitchenFilter f) => switch (f) {
      KitchenFilter.all => l10n.kitchenFilterAll,
      KitchenFilter.available => l10n.kitchenFilterAvailable,
      KitchenFilter.out => l10n.kitchenFilterOut,
    };
    return Wrap(
      spacing: SpacingTokens.s,
      runSpacing: SpacingTokens.s,
      children: [
        for (final f in KitchenFilter.values)
          ChoiceChip(
            key: Key('kitchen.filter.${f.name}'),
            label: Text(label(f)),
            selected: selected == f,
            onSelected: (_) => onSelected(f),
          ),
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.available,
    required this.out,
    required this.collapsed,
    required this.onToggle,
    required this.frequent,
    required this.other,
  });

  final api.KitchenCategory category;
  final int available;
  final int out;
  final bool collapsed;
  final VoidCallback onToggle;
  final List<Widget> frequent;
  final List<Widget> other;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final title = kitchenCategoryLabel(l10n, category);
    final summary = l10n.kitchenCategorySummary(available, out);
    Widget wrap(List<Widget> children) => Wrap(
      spacing: SpacingTokens.s,
      runSpacing: SpacingTokens.s,
      children: children,
    );

    return Column(
      key: Key('kitchen.category.${category.toJson()}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // TalkBack: a heading, with "diciutkan" / "dibentangkan".
        Semantics(
          header: true,
          button: true,
          label: [
            title,
            summary,
            collapsed
                ? l10n.kitchenCategoryA11yCollapsed
                : l10n.kitchenCategoryA11yExpanded,
          ].join(', '),
          excludeSemantics: true,
          onTap: onToggle,
          child: InkWell(
            key: Key('kitchen.category.${category.toJson()}.header'),
            onTap: onToggle,
            borderRadius: BorderRadius.circular(RadiusTokens.control),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: SpacingTokens.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: theme.textTheme.titleLarge),
                          Text(
                            summary,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(collapsed ? Icons.expand_more : Icons.expand_less),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (!collapsed) ...[
          const SizedBox(height: SpacingTokens.s),
          if (frequent.isNotEmpty) wrap(frequent),
          if (frequent.isNotEmpty && other.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: SpacingTokens.s),
              child: Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.s,
                    ),
                    child: Text(
                      l10n.kitchenCategoryOther,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
            ),
          if (other.isNotEmpty) wrap(other),
        ],
      ],
    );
  }
}
