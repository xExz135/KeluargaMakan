// Shared pieces of the Dapur Saya screens: failure messages, the category
// picker and the info note. None of these shows a safety state.

import 'package:flutter/material.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../../../core/api/api_error_text.dart';
import '../../../core/api/api_problem.dart';
import '../../../core/api/api_result.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/tokens.dart';
import '../../../data/models/kitchen.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../labels.dart';

/// What the user tried to do, for the message after a failure.
enum KitchenWrite { toggle, add, remove }

/// One line explaining why a kitchen change did not go through. Text comes
/// from the error code only (contract-alignment.md 5).
String kitchenFailureText(
  AppLocalizations l10n,
  ApiFailure failure, {
  required KitchenWrite write,
  String? name,
  int? maxItems,
}) {
  if (failure is NetworkFailure) {
    return switch (write) {
      KitchenWrite.toggle => l10n.kitchenChangeNeedsInternet(name ?? ''),
      KitchenWrite.add => l10n.kitchenAddOffline,
      KitchenWrite.remove => l10n.kitchenRemoveOffline,
    };
  }
  switch (failure.problemCode) {
    case ApiErrorCode.kitchenItemLimitReached when maxItems != null:
      return l10n.kitchenLimitReached(maxItems);
    case ApiErrorCode.referenceDataUnavailable:
      return l10n.kitchenSearchUnavailable;
    case ApiErrorCode.notFound:
      return l10n.errorApiNotFound;
    case ApiErrorCode.refreshTokenInvalid:
      return l10n.errorApiSignedOut;
    case _ when write == KitchenWrite.toggle:
      return l10n.kitchenChangeFailed(name ?? '');
    case _:
      return ApiErrorText.of(l10n, failure).body;
  }
}

/// Shows [text] in the nearest messenger, replacing the current snackbar.
void showKitchenSnack(
  BuildContext context,
  String text, {
  SnackBarAction? action,
  Duration? duration,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        action: action,
        duration: duration ?? const Duration(seconds: 4),
      ),
    );
}

/// Choice chips for the nine KIT-03 categories.
class KitchenCategoryChips extends StatelessWidget {
  const KitchenCategoryChips({
    super.key,
    required this.selected,
    required this.onSelected,
    this.keyPrefix = 'kitchen.category.pick',
  });

  final api.KitchenCategory? selected;
  final ValueChanged<api.KitchenCategory> onSelected;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: SpacingTokens.s,
      runSpacing: SpacingTokens.s,
      children: [
        for (final c in kitchenCategoryOrder)
          ChoiceChip(
            key: Key('$keyPrefix.${c.toJson()}'),
            label: Text(kitchenCategoryLabel(l10n, c)),
            selected: selected == c,
            onSelected: (_) => onSelected(c),
          ),
      ],
    );
  }
}

/// Asks for a category, for a reference ingredient that has none.
Future<api.KitchenCategory?> pickKitchenCategory(BuildContext context) =>
    showDialog<api.KitchenCategory>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.kitchenPickCategoryTitle),
          scrollable: true,
          content: KitchenCategoryChips(
            selected: null,
            onSelected: (c) => Navigator.of(context).pop(c),
          ),
          actions: [
            TextButton(
              key: const Key('kitchen.category.pick.cancel'),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.commonCancel),
            ),
          ],
        );
      },
    );

/// A static note in the `info` colors (not a safety color), for example
/// `kitchen.custom.note`.
class KitchenInfoNote extends StatelessWidget {
  const KitchenInfoNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final app = AppColors.of(context);
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: app.infoContainer,
        borderRadius: BorderRadius.circular(RadiusTokens.control),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.m),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(Icons.info_outline, color: app.infoIcon),
            ),
            const SizedBox(width: SpacingTokens.m),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: app.onInfoContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
