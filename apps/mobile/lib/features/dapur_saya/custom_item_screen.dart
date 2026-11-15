// K3 New ingredient (screens.md K3; KIT-05, SAF-09).
//
// A custom item is stored with `ingredientId: null` and flagged, so Cek
// Aman gives it "Cek label" for members with hard rules (SAF-09). The note
// says so in the `info` colors, not a safety color, and nothing on this
// screen calls an ingredient "aman". When the name is close to a known
// ingredient, that one is offered first ("Pakai …"), so Cek Aman can check
// it; it is never forced.
//
// A full page rather than a sheet, like the T-028 forms, so it fits at
// 200% text with the keyboard open. With or without internet the item is
// added at once and queued (KIT-16). The name is checked here against the
// server's rules first (text_rules.dart), so a name the server would refuse
// is never queued; if the server still refuses it, Dapur Saya says so and
// the item goes away.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../../app/widgets/section_scaffold.dart';
import '../../core/api/api_error_text.dart';
import '../../core/api/api_problem.dart';
import '../../core/theme/tokens.dart';
import '../../data/ingredient_search.dart';
import '../../data/kitchen_state.dart';
import '../../data/models/kitchen.dart';
import '../../data/text_rules.dart';
import '../../l10n/generated/app_localizations.dart';
import '../auth/widgets/onboarding_scaffold.dart' show InlineMessage;
import 'widgets/kitchen_widgets.dart';

/// The contract's `KitchenCustomName` limit.
const customNameMaxLength = kitchenTextMaxLength;

/// Opens K3 above the navigation. True when an ingredient was added.
Future<bool> openCustomItem(BuildContext context, {String initialName = ''}) =>
    Navigator.of(context, rootNavigator: true)
        .push<bool>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => CustomItemScreen(initialName: initialName),
          ),
        )
        .then((added) => added ?? false);

class CustomItemScreen extends ConsumerStatefulWidget {
  const CustomItemScreen({super.key, this.initialName = ''});

  final String initialName;

  @override
  ConsumerState<CustomItemScreen> createState() => _CustomItemScreenState();
}

class _CustomItemScreenState extends ConsumerState<CustomItemScreen> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initialName.trim(),
  );
  api.KitchenCategory? _category;
  bool _saving = false;
  String? _nameError;
  bool _categoryMissing = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _done(KitchenAddResult result) {
    final l10n = AppLocalizations.of(context);
    switch (result) {
      case KitchenAdded():
        Navigator.of(context).pop(true);
      case KitchenAddAtLimit(:final maxItems):
        setState(() {
          _saving = false;
          _message = l10n.kitchenLimitReached(maxItems);
        });
      case KitchenAddUnavailable():
        setState(() {
          _saving = false;
          _message = l10n.errorGenericBody;
        });
    }
  }

  void _add() {
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    final problem = textProblem(name, maxLength: customNameMaxLength);
    setState(() {
      _nameError = switch (problem) {
        null => null,
        TextProblem.empty => l10n.errorFieldRequired,
        TextProblem.tooLong => ApiErrorText.field(
          l10n,
          FieldErrorKind.tooLong,
          maxLength: customNameMaxLength,
        ),
        TextProblem.hiddenCharacters => ApiErrorText.field(
          l10n,
          FieldErrorKind.invalid,
          maxLength: customNameMaxLength,
        ),
      };
      _categoryMissing = _category == null;
      _message = null;
    });
    if (problem != null || _category == null) return;
    setState(() => _saving = true);
    _done(
      ref
          .read(kitchenProvider.notifier)
          .add(CustomIngredient(name), category: _category),
    );
  }

  Future<void> _useKnown(CatalogEntry known) async {
    var category = known.category ?? _category;
    if (category == null) {
      category = await pickKitchenCategory(context);
      if (category == null || !mounted) return;
    }
    setState(() {
      _saving = true;
      _message = null;
    });
    _done(
      ref
          .read(kitchenProvider.notifier)
          .add(ReferenceIngredient(known.ingredientId), category: category),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final catalog = switch (ref.watch(catalogProvider)) {
      CatalogReady(:final catalog) => catalog,
      _ => null,
    };
    final known = catalog == null
        ? null
        : closestCatalogMatch(catalog, _name.text);

    return SectionScaffold(
      title: l10n.kitchenCustomTitle,
      isTabRoot: false,
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: SpacingTokens.l),
        children: [
          ContentFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const Key('kitchen.custom.name'),
                  controller: _name,
                  enabled: !_saving,
                  maxLength: customNameMaxLength,
                  textCapitalization: TextCapitalization.sentences,
                  // The user's own words: the keyboard must not learn or
                  // change them (security review T-028 M1).
                  enableIMEPersonalizedLearning: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: l10n.kitchenCustomName,
                    errorText: _nameError,
                    errorMaxLines: 4,
                  ),
                ),
                if (known != null) ...[
                  const SizedBox(height: SpacingTokens.m),
                  _DidYouMean(
                    name: known.ingredient.displayName.forLanguage(language),
                    enabled: !_saving,
                    onUse: () => _useKnown(known.ingredient),
                  ),
                ],
                const SizedBox(height: SpacingTokens.xl),
                Semantics(
                  header: true,
                  child: Text(
                    l10n.kitchenCustomCategory,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: SpacingTokens.s),
                KitchenCategoryChips(
                  keyPrefix: 'kitchen.custom.category',
                  selected: _category,
                  onSelected: (c) => setState(() {
                    _category = c;
                    _categoryMissing = false;
                  }),
                ),
                if (_categoryMissing) ...[
                  const SizedBox(height: SpacingTokens.s),
                  Text(
                    l10n.errorFieldRequired,
                    key: const Key('kitchen.custom.categoryMissing'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: SpacingTokens.xl),
                KitchenInfoNote(
                  key: const Key('kitchen.custom.note'),
                  text: l10n.kitchenCustomNote,
                ),
                if (_message case final message?) ...[
                  const SizedBox(height: SpacingTokens.l),
                  InlineMessage(
                    key: const Key('kitchen.custom.error'),
                    text: message,
                  ),
                ],
                const SizedBox(height: SpacingTokens.xl),
                FilledButton(
                  key: const Key('kitchen.custom.add'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  onPressed: _saving ? null : _add,
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : Text(l10n.kitchenCustomAdd),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DidYouMean extends StatelessWidget {
  const _DidYouMean({
    required this.name,
    required this.enabled,
    required this.onUse,
  });

  final String name;
  final bool enabled;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const Key('kitchen.custom.didYouMean'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.kitchenCustomDidYouMean(name)),
        const SizedBox(height: SpacingTokens.s),
        FilledButton.tonal(
          key: const Key('kitchen.custom.useKnown'),
          onPressed: enabled ? onUse : null,
          child: Text(l10n.kitchenCustomUseKnown(name)),
        ),
      ],
    );
  }
}
