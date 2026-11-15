// K5 ingredient sets (screens.md K5; KIT-08, KIT-16).
//
// - The list of sets: name, count, "Tandai semua ada", and a menu to edit
//   or delete. "Buat set" opens the editor: a name and a checklist of the
//   kitchen's items by category.
// - "Tandai semua ada" sets every item of the set that is still in the
//   kitchen to "Ada" in one tap and never marks anything "Habis". It works
//   without internet (the changes are queued like taps, KIT-16). Undo puts
//   the earlier states back (snackbar for `ui.snackbarActionMs`). When
//   everything was already "Ada": `kitchen.sets.allAlready`.
// - Creating, editing and deleting a set need internet in V1 (sets_state
//   .dart, QUESTIONS #74): the input is kept and the page says so.
// - Deleting a set leaves its items in the kitchen.
// - Set names are the user's own text: the keyboard does not learn them and
//   they are never logged.
// Full pages, like K3, so they fit at 200% text.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/widgets/section_scaffold.dart';
import '../../core/api/api_error_text.dart';
import '../../core/api/api_problem.dart';
import '../../core/api/api_result.dart';
import '../../core/config/app_config.dart';
import '../../core/config/config_keys.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/theme/tokens.dart';
import '../../data/kitchen_state.dart';
import '../../data/models/kitchen.dart';
import '../../data/sets_state.dart';
import '../../data/text_rules.dart';
import '../../l10n/generated/app_localizations.dart';
import '../auth/widgets/onboarding_scaffold.dart'
    show InlineMessage, InlineMessageKind;
import '../keluarga_saya/widgets/family_widgets.dart' show ErrorPanel;
import 'labels.dart';
import 'widgets/kitchen_widgets.dart';

/// The set's items that are still in the kitchen, as shown.
List<KitchenEntry> setItemsIn(IngredientSetInfo set, KitchenList? list) => [
  for (final id in set.itemIds) ?list?.byId(id),
];

/// KIT-08 "Tandai semua ada" for [set], with Undo.
void markSetAvailable(
  BuildContext context,
  WidgetRef ref,
  IngredientSetInfo set,
) {
  final l10n = AppLocalizations.of(context);
  final kitchen = ref.read(kitchenProvider.notifier);
  final before = kitchen.markAvailable(set.itemIds);
  if (before.isEmpty) {
    showKitchenSnack(context, l10n.kitchenSetsAllAlready);
    return;
  }
  final config = ref.read(appConfigProvider);
  showKitchenSnack(
    context,
    l10n.kitchenSetMarkedAll(before.length),
    duration: Duration(milliseconds: config.get(ConfigKeys.snackbarActionMs)),
    action: SnackBarAction(
      key: const Key('kitchen.sets.undo'),
      label: l10n.commonUndo,
      onPressed: () => kitchen.restoreStates(before),
    ),
  );
}

/// Opens K5 above the navigation.
Future<void> openKitchenSets(BuildContext context) => Navigator.of(
  context,
  rootNavigator: true,
).push<void>(MaterialPageRoute(builder: (_) => const KitchenSetsScreen()));

/// Opens the set editor; [set] null creates one.
Future<void> openSetEditor(BuildContext context, {IngredientSetInfo? set}) =>
    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => SetEditorScreen(set: set),
      ),
    );

class KitchenSetsScreen extends ConsumerWidget {
  const KitchenSetsScreen({super.key});

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    IngredientSetInfo set,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.kitchenSetsDeleteTitle(set.name)),
        content: Text(l10n.kitchenSetsDeleteBody),
        actions: [
          TextButton(
            key: const Key('kitchen.sets.delete.cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            key: const Key('kitchen.sets.delete.confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await ref.read(setsProvider.notifier).delete(set.id);
    if (!context.mounted) return;
    showKitchenSnack(context, switch (result) {
      Ok() => l10n.kitchenSetsDeleted(set.name),
      Err(:final failure) => kitchenFailureText(l10n, failure),
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final setsState = ref.watch(setsProvider);
    final kitchen = ref.watch(kitchenProvider);
    final list = kitchen is KitchenLoaded ? kitchen.list : null;

    final Widget content = switch (setsState) {
      SetsLoading() => const Center(child: CircularProgressIndicator()),
      SetsLoadFailed(:final failure) => ErrorPanel(
        key: const Key('kitchen.sets.error'),
        title: ApiErrorText.of(l10n, failure).title,
        body: ApiErrorText.of(l10n, failure).body,
        retryKey: const Key('kitchen.sets.retry'),
        onRetry: ref.read(setsProvider.notifier).reload,
      ),
      SetsLoaded(:final sets) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (sets.items.isEmpty)
            Text(
              l10n.kitchenSetsEmpty,
              key: const Key('kitchen.sets.empty'),
              style: theme.textTheme.bodyLarge,
            ),
          for (final set in sets.items) ...[
            SetCard(
              set: set,
              count: setItemsIn(set, list).length,
              onMarkAll: () => markSetAvailable(context, ref, set),
              menu: PopupMenuButton<String>(
                key: Key('kitchen.sets.menu.${set.id}'),
                tooltip: l10n.kitchenSetsOptions(set.name),
                onSelected: (choice) {
                  if (choice == 'edit') {
                    unawaited(openSetEditor(context, set: set));
                  } else {
                    unawaited(_delete(context, ref, set));
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    key: const Key('kitchen.sets.menu.edit'),
                    value: 'edit',
                    child: Text(l10n.commonEdit),
                  ),
                  PopupMenuItem(
                    key: const Key('kitchen.sets.menu.delete'),
                    value: 'delete',
                    child: Text(l10n.commonDelete),
                  ),
                ],
              ),
            ),
            const SizedBox(height: SpacingTokens.m),
          ],
          const SizedBox(height: SpacingTokens.l),
          if (sets.atLimit)
            Text(
              l10n.kitchenSetsLimitReached(sets.maxSets),
              key: const Key('kitchen.sets.limit'),
            )
          else
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.icon(
                key: const Key('kitchen.sets.create'),
                onPressed: () => openSetEditor(context),
                icon: const Icon(Icons.add),
                label: Text(l10n.kitchenSetsCreate),
              ),
            ),
        ],
      ),
    };

    return SectionScaffold(
      title: l10n.kitchenSetsTitle,
      isTabRoot: false,
      body: RefreshIndicator(
        onRefresh: ref.read(setsProvider.notifier).reload,
        child: ListView(
          key: const Key('kitchen.sets.screen'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: SpacingTokens.l),
          children: [ContentFrame(child: content)],
        ),
      ),
    );
  }
}

/// One set: name, count and "Tandai semua ada" (K1 sets row and K5).
class SetCard extends StatelessWidget {
  const SetCard({
    super.key,
    required this.set,
    required this.count,
    required this.onMarkAll,
    this.menu,
  });

  final IngredientSetInfo set;
  final int count;
  final VoidCallback onMarkAll;
  final Widget? menu;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final app = AppColors.of(context);
    return DecoratedBox(
      key: Key('kitchen.set.${set.id}'),
      decoration: BoxDecoration(
        color: app.card,
        borderRadius: BorderRadius.circular(RadiusTokens.control),
        border: Border.all(color: app.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: MergeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(set.name, style: theme.textTheme.titleMedium),
                        Text(
                          l10n.kitchenSetsItemCount(count),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ?menu,
              ],
            ),
            const SizedBox(height: SpacingTokens.s),
            FilledButton.tonal(
              key: Key('kitchen.set.${set.id}.markAll'),
              onPressed: onMarkAll,
              child: Text(l10n.kitchenSetsMarkAll),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ Editor

class SetEditorScreen extends ConsumerStatefulWidget {
  const SetEditorScreen({super.key, this.set});

  /// Null: a new set.
  final IngredientSetInfo? set;

  @override
  ConsumerState<SetEditorScreen> createState() => _SetEditorScreenState();
}

class _SetEditorScreenState extends ConsumerState<SetEditorScreen> {
  late final TextEditingController _name = TextEditingController(
    text: widget.set?.name ?? '',
  );
  late final Set<String> _picked = {...?widget.set?.itemIds};
  bool _saving = false;
  String? _nameError;
  String? _message;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save(KitchenList? list) async {
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    final problem = textProblem(name, maxLength: setNameMaxLength);
    setState(() {
      _message = null;
      _nameError = problem == null
          ? null
          : ApiErrorText.field(l10n, switch (problem) {
              TextProblem.empty => FieldErrorKind.required,
              TextProblem.tooLong => FieldErrorKind.tooLong,
              TextProblem.hiddenCharacters => FieldErrorKind.invalid,
            }, maxLength: setNameMaxLength);
    });
    if (problem != null) return;
    // Only items the server knows; an item removed meanwhile drops out.
    final ids = [
      for (final id in _picked)
        if (list?.byId(id) case final item? when !item.isLocalOnly) id,
    ];
    setState(() => _saving = true);
    final sets = ref.read(setsProvider.notifier);
    final set = widget.set;
    final ApiResult<IngredientSetInfo> result = set == null
        ? await sets.create(name, ids)
        : await sets.replace(set.id, name, ids);
    if (!mounted) return;
    switch (result) {
      case Ok():
        Navigator.of(context).pop();
      case Err(:final failure):
        final maxSets = switch (ref.read(setsProvider)) {
          SetsLoaded(:final sets) => sets.maxSets,
          _ => null,
        };
        setState(() {
          _saving = false;
          _message =
              failure.problemCode == ApiErrorCode.ingredientSetLimitReached &&
                  maxSets != null
              ? l10n.kitchenSetsLimitReached(maxSets)
              : kitchenFailureText(l10n, failure);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final kitchen = ref.watch(kitchenProvider);
    final list = kitchen is KitchenLoaded ? kitchen.list : null;
    final catalog = switch (ref.watch(catalogProvider)) {
      CatalogReady(:final catalog) => catalog,
      _ => null,
    };
    final items = list?.items ?? const <KitchenEntry>[];
    final hasLocal = items.any((i) => i.isLocalOnly);

    return SectionScaffold(
      title: widget.set == null
          ? l10n.kitchenSetsCreate
          : l10n.kitchenSetsEditTitle,
      isTabRoot: false,
      body: ListView(
        key: const Key('kitchen.setEditor'),
        padding: const EdgeInsets.symmetric(vertical: SpacingTokens.l),
        children: [
          ContentFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const Key('kitchen.setEditor.name'),
                  controller: _name,
                  enabled: !_saving,
                  maxLength: setNameMaxLength,
                  textCapitalization: TextCapitalization.sentences,
                  enableIMEPersonalizedLearning: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: l10n.kitchenSetsNameLabel,
                    hintText: l10n.kitchenSetsNameHint,
                    errorText: _nameError,
                    errorMaxLines: 4,
                  ),
                ),
                const SizedBox(height: SpacingTokens.l),
                Semantics(
                  header: true,
                  child: Text(
                    l10n.kitchenSetsItemsLabel,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: SpacingTokens.s),
                if (items.isEmpty)
                  Text(
                    l10n.kitchenSetsNoItems,
                    key: const Key('kitchen.setEditor.noItems'),
                  ),
                if (hasLocal) ...[
                  Text(
                    l10n.kitchenSetsLocalItemNote,
                    key: const Key('kitchen.setEditor.localNote'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.s),
                ],
                for (final category in kitchenCategoryOrder)
                  if (items.any((i) => i.category == category)) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: SpacingTokens.m),
                      child: Semantics(
                        header: true,
                        child: Text(
                          kitchenCategoryLabel(l10n, category),
                          style: theme.textTheme.labelLarge,
                        ),
                      ),
                    ),
                    for (final item in items)
                      if (item.category == category)
                        CheckboxListTile(
                          key: Key('kitchen.setEditor.item.${item.id}'),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            kitchenItemName(context, item, catalog: catalog),
                          ),
                          value: _picked.contains(item.id),
                          onChanged: item.isLocalOnly || _saving
                              ? null
                              : (on) => setState(() {
                                  if (on ?? false) {
                                    _picked.add(item.id);
                                  } else {
                                    _picked.remove(item.id);
                                  }
                                }),
                        ),
                  ],
                if (_message case final message?) ...[
                  const SizedBox(height: SpacingTokens.l),
                  InlineMessage(
                    key: const Key('kitchen.setEditor.error'),
                    kind: InlineMessageKind.info,
                    text: message,
                  ),
                ],
                const SizedBox(height: SpacingTokens.xl),
                FilledButton(
                  key: const Key('kitchen.setEditor.save'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  onPressed: _saving ? null : () => _save(list),
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : Text(l10n.kitchenSetsSave),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ Add to set

/// "Masukkan ke set" (K4): ticks the sets [itemId] belongs to. Online only.
Future<void> openAddToSet(BuildContext context, String itemId) =>
    showDialog<void>(
      context: context,
      builder: (_) => _AddToSetDialog(itemId: itemId),
    );

class _AddToSetDialog extends ConsumerStatefulWidget {
  const _AddToSetDialog({required this.itemId});

  final String itemId;

  @override
  ConsumerState<_AddToSetDialog> createState() => _AddToSetDialogState();
}

class _AddToSetDialogState extends ConsumerState<_AddToSetDialog> {
  final Set<String> _busy = {};
  String? _message;

  Future<void> _toggle(IngredientSetInfo set, bool on) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy.add(set.id);
      _message = null;
    });
    final ids = [
      for (final id in set.itemIds)
        if (id != widget.itemId) id,
      if (on) widget.itemId,
    ];
    final result = await ref
        .read(setsProvider.notifier)
        .replace(set.id, set.name, ids);
    if (!mounted) return;
    setState(() {
      _busy.remove(set.id);
      if (result case Err(:final failure)) {
        _message = kitchenFailureText(l10n, failure);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(setsProvider);
    final sets = state is SetsLoaded
        ? state.sets.items
        : const <IngredientSetInfo>[];
    return AlertDialog(
      title: Text(l10n.kitchenItemAddToSet),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state is SetsLoading)
            const Center(child: CircularProgressIndicator())
          else if (sets.isEmpty)
            Text(
              l10n.kitchenSetsPickerEmpty,
              key: const Key('kitchen.addToSet.empty'),
            ),
          for (final set in sets)
            CheckboxListTile(
              key: Key('kitchen.addToSet.${set.id}'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(set.name),
              value: set.itemIds.contains(widget.itemId),
              onChanged: _busy.contains(set.id)
                  ? null
                  : (on) => _toggle(set, on ?? false),
            ),
          if (_message case final message?) ...[
            const SizedBox(height: SpacingTokens.m),
            InlineMessage(
              key: const Key('kitchen.addToSet.error'),
              kind: InlineMessageKind.info,
              text: message,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          key: const Key('kitchen.addToSet.close'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonClose),
        ),
      ],
    );
  }
}
