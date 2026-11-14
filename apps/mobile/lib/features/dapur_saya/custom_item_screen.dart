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
// 200% text with the keyboard open. Without internet the input is kept
// and the page says that adding needs internet (no offline queue until
// T-034, QUESTIONS #68).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../../app/widgets/section_scaffold.dart';
import '../../core/api/api_error_text.dart';
import '../../core/api/api_problem.dart';
import '../../core/api/api_result.dart';
import '../../core/theme/tokens.dart';
import '../../data/ingredient_search.dart';
import '../../data/kitchen_state.dart';
import '../../data/models/kitchen.dart';
import '../../l10n/generated/app_localizations.dart';
import '../auth/widgets/onboarding_scaffold.dart' show InlineMessage;
import 'widgets/kitchen_widgets.dart';

/// The contract's `KitchenCustomName` limit.
const customNameMaxLength = 60;

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

  int? get _maxItems => switch (ref.read(kitchenProvider)) {
    KitchenLoaded(:final list) => list.maxItems,
    _ => null,
  };

  void _fail(ApiFailure failure) {
    final l10n = AppLocalizations.of(context);
    final fieldError = switch (failure) {
      ProblemFailure(:final problem)
          when problem.code == ApiErrorCode.validationFailed =>
        problem.fieldErrors
            .where((e) => e.pointer == '/customName')
            .firstOrNull,
      _ => null,
    };
    setState(() {
      _saving = false;
      if (fieldError != null) {
        _nameError = ApiErrorText.field(
          l10n,
          fieldError.kind,
          maxLength: customNameMaxLength,
        );
        _message = null;
      } else {
        _message = kitchenFailureText(
          l10n,
          failure,
          write: KitchenWrite.add,
          maxItems: _maxItems,
        );
      }
    });
  }

  Future<void> _add() async {
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    setState(() {
      _nameError = name.isEmpty ? l10n.errorFieldRequired : null;
      _categoryMissing = _category == null;
      _message = null;
    });
    if (name.isEmpty || _category == null) return;
    setState(() => _saving = true);
    final result = await ref
        .read(kitchenProvider.notifier)
        .add(CustomIngredient(name), category: _category);
    if (!mounted) return;
    switch (result) {
      case Ok():
        Navigator.of(context).pop(true);
      case Err(:final failure):
        _fail(failure);
    }
  }

  Future<void> _useKnown(CatalogEntry known) async {
    var category = known.category == null ? _category : null;
    if (known.category == null && category == null) {
      category = await pickKitchenCategory(context);
      if (category == null || !mounted) return;
    }
    setState(() {
      _saving = true;
      _message = null;
    });
    final result = await ref
        .read(kitchenProvider.notifier)
        .add(ReferenceIngredient(known.ingredientId), category: category);
    if (!mounted) return;
    switch (result) {
      case Ok():
        Navigator.of(context).pop(true);
      case Err(:final failure):
        _fail(failure);
    }
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
