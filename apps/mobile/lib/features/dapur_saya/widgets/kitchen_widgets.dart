// Shared pieces of the Dapur Saya screens: failure and sync messages, the
// sync caption (KIT-16), the category picker and the info note. None of
// these shows a safety state.

import 'package:flutter/material.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../../../core/api/api_error_text.dart';
import '../../../core/api/api_problem.dart';
import '../../../core/api/api_result.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/tokens.dart';
import '../../../data/kitchen_state.dart';
import '../../../data/models/kitchen.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../labels.dart';

/// One line explaining why an online-only write (an ingredient set,
/// KIT-08) did not go through. Text comes from the error code only
/// (contract-alignment.md 5). Item changes never fail this way: they are
/// queued (KIT-16) and explained by [kitchenNoticeText].
String kitchenFailureText(AppLocalizations l10n, ApiFailure failure) {
  if (failure is NetworkFailure) return l10n.kitchenSetsNeedInternet;
  return switch (failure.problemCode) {
    ApiErrorCode.notFound => l10n.errorApiNotFound,
    ApiErrorCode.refreshTokenInvalid => l10n.errorApiSignedOut,
    _ => ApiErrorText.of(l10n, failure).body,
  };
}

/// The message for a sync event (KIT-16). [nameOf] names the ingredient.
String kitchenNoticeText(
  AppLocalizations l10n,
  KitchenNotice notice, {
  required String Function(IngredientKey ingredient, KitchenEntry? item) nameOf,
}) => switch (notice) {
  KitchenChangeRefused(:final ingredient, :final item) =>
    l10n.kitchenChangeFailed(nameOf(ingredient, item)),
  KitchenLimitReached(:final maxItems) => l10n.kitchenLimitReached(maxItems),
  KitchenOverwritten(:final ingredient, :final item) =>
    l10n.kitchenSyncOverwritten(nameOf(ingredient, item)),
  KitchenQueueFull(:final maxChanges) => l10n.kitchenQueueFull(maxChanges),
  KitchenChangesExpired(:final count, :final maxAgeHours) =>
    l10n.kitchenChangesExpired(count, (maxAgeHours / 24).ceil()),
};

/// The sync caption under the Dapur Saya title (screens.md K1, components
/// 8.9 "Sync pending"): "Tersimpan", "Mengirim perubahan…" or "Belum
/// terkirim · {n} perubahan", in the neutral container. A polite live
/// region, so TalkBack reads each change once.
class KitchenSyncCaption extends StatelessWidget {
  const KitchenSyncCaption({super.key, required this.status});

  final KitchenSyncStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final app = AppColors.of(context);
    final theme = Theme.of(context);
    final (text, icon) = status.sending
        ? (l10n.kitchenSyncSyncing, Icons.sync)
        : status.pendingCount > 0
        ? (
            l10n.kitchenSyncPending(status.pendingCount),
            Icons.cloud_upload_outlined,
          )
        : (l10n.kitchenSyncSaved, Icons.cloud_done_outlined);
    return Semantics(
      container: true,
      liveRegion: true,
      label: text,
      excludeSemantics: true,
      child: DecoratedBox(
        key: const Key('kitchen.sync.caption'),
        decoration: BoxDecoration(
          color: app.neutralContainer,
          borderRadius: BorderRadius.circular(RadiusTokens.full),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.s,
            vertical: SpacingTokens.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: app.neutralIcon),
              const SizedBox(width: SpacingTokens.xs),
              Flexible(
                child: Text(
                  text,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: app.onNeutralContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
