// K4 brand search (screens.md K4; KIT-09, SAF-07).
//
// - The list offers only the ingredient's brands from the verified
//   reference data (the catalog's `brands`, from the API or the phone's
//   copy of it). Nothing else is ever offered as a listed brand.
// - A brand that is not in the list can be typed. It is stored as text,
//   never as a listed brand, and the page says that Cek Aman then marks the
//   ingredient Cek label (`kitchen.brand.unknownNote`). A typed text that
//   matches a listed name is not turned into that brand by the app: the
//   listed row is shown first for the user to pick.
// - A custom ingredient takes a typed brand only (contract
//   `KitchenBrandInput`).
// - Nothing here says a brand is safe or verified. The typed text stays out
//   of the keyboard's memory and out of logs.
// A full page, like K3, so it fits at 200% text with the keyboard open.

import 'package:flutter/material.dart';

import '../../app/widgets/section_scaffold.dart';
import '../../core/api/api_error_text.dart';
import '../../core/api/api_problem.dart' show FieldErrorKind;
import '../../core/theme/tokens.dart';
import '../../data/ingredient_search.dart' show foldIngredientName;
import '../../data/models/kitchen.dart';
import '../../data/text_rules.dart';
import '../../l10n/generated/app_localizations.dart';
import 'widgets/kitchen_widgets.dart';

/// Opens the brand search for an ingredient called [ingredientName]. Returns
/// the chosen brand, or null when the user went back.
Future<KitchenBrand?> pickKitchenBrand(
  BuildContext context, {
  required String ingredientName,
  required List<CatalogBrand> brands,
  required bool allowListed,
}) => Navigator.of(context, rootNavigator: true).push<KitchenBrand>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => BrandPickerScreen(
      ingredientName: ingredientName,
      brands: allowListed ? brands : const [],
      listAvailable: allowListed,
    ),
  ),
);

class BrandPickerScreen extends StatefulWidget {
  const BrandPickerScreen({
    super.key,
    required this.ingredientName,
    required this.brands,
    this.listAvailable = true,
  });

  final String ingredientName;
  final List<CatalogBrand> brands;

  /// False for a custom ingredient: only a typed brand.
  final bool listAvailable;

  @override
  State<BrandPickerScreen> createState() => _BrandPickerScreenState();
}

class _BrandPickerScreenState extends State<BrandPickerScreen> {
  final _query = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _useTyped() {
    final l10n = AppLocalizations.of(context);
    final text = _query.text.trim();
    final problem = textProblem(text, maxLength: kitchenTextMaxLength);
    if (problem != null) {
      setState(
        () => _error = ApiErrorText.field(l10n, switch (problem) {
          TextProblem.empty => FieldErrorKind.required,
          TextProblem.tooLong => FieldErrorKind.tooLong,
          TextProblem.hiddenCharacters => FieldErrorKind.invalid,
        }, maxLength: kitchenTextMaxLength),
      );
      return;
    }
    Navigator.of(context).pop(TypedBrand(text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final typed = _query.text.trim();
    final folded = foldIngredientName(typed);
    final matches = [
      for (final b in widget.brands)
        if (folded.isEmpty || foldIngredientName(b.name).contains(folded)) b,
    ];
    final exact = matches.any((b) => foldIngredientName(b.name) == folded);

    return SectionScaffold(
      title: l10n.kitchenBrandTitle,
      isTabRoot: false,
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: SpacingTokens.l),
        children: [
          ContentFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.ingredientName, style: theme.textTheme.titleMedium),
                const SizedBox(height: SpacingTokens.m),
                TextField(
                  key: const Key('kitchen.brand.field'),
                  controller: _query,
                  autofocus: true,
                  maxLength: kitchenTextMaxLength,
                  textCapitalization: TextCapitalization.words,
                  // The user's own words: the keyboard must not learn or
                  // change them.
                  enableIMEPersonalizedLearning: false,
                  autocorrect: false,
                  onSubmitted: (_) {
                    if (typed.isNotEmpty && !exact) _useTyped();
                  },
                  decoration: InputDecoration(
                    labelText: l10n.kitchenBrandHint,
                    prefixIcon: const Icon(Icons.search),
                    errorText: _error,
                    errorMaxLines: 4,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: SpacingTokens.m),
                if (!widget.listAvailable || widget.brands.isEmpty) ...[
                  KitchenInfoNote(
                    key: const Key('kitchen.brand.listMissing'),
                    text: l10n.kitchenBrandListMissing,
                  ),
                  const SizedBox(height: SpacingTokens.m),
                ],
                for (final brand in matches)
                  ListTile(
                    key: Key('kitchen.brand.option.${brand.brandId}'),
                    contentPadding: EdgeInsets.zero,
                    minTileHeight: 56,
                    title: Text(brand.name),
                    onTap: () =>
                        Navigator.of(context)
                            .pop(ReferenceBrand(brand.brandId, brand.name)),
                  ),
                if (typed.isNotEmpty && !exact) ...[
                  const SizedBox(height: SpacingTokens.s),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      key: const Key('kitchen.brand.useTyped'),
                      onPressed: _useTyped,
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(l10n.kitchenBrandUseTyped(typed)),
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.s),
                  // SAF-07: a typed brand never counts as a recorded brand.
                  KitchenInfoNote(
                    key: const Key('kitchen.brand.typedNote'),
                    text: l10n.kitchenBrandUnknownNote,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
