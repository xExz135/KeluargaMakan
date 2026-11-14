// F2g Guardian confirmation (SET-10, PRF-18; screens.md F2g). DRAFT: needs
// legal review.
//
// Shown before a child profile is created, and before an adult profile is
// changed to an infant, child or teen age group. The text is the server's
// `guardian_confirmation` ConsentText; its version and language go back with
// the profile write, where the server records the confirmation. The checkbox
// sentence is the app string `family.guardian.check` until the contract has
// a statement field (contract-alignment.md M4). Online only.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../../core/api/api_result.dart';
import '../../core/theme/tokens.dart';
import '../../data/repositories/consent_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import 'labels.dart';

/// Why a guardian confirmation could not be asked.
enum GuardianTextProblem { offline, loadFailed }

/// Loads the guardian text and asks the manager. Returns the confirmation to
/// send, null when the manager cancelled, or a [GuardianTextProblem].
Future<Object?> askGuardianConfirmation(
  BuildContext context,
  WidgetRef ref, {
  required String childName,
}) async {
  final result = await ref
      .read(consentRepositoryProvider)
      .getConsentText(
        api.ConsentPurpose.guardianConfirmation,
        apiLanguageOf(context),
      );
  if (!context.mounted) return null;
  final api.ConsentText text;
  switch (result) {
    case Ok(:final value):
      text = value;
    case Err(failure: NetworkFailure()):
      return GuardianTextProblem.offline;
    case Err():
      return GuardianTextProblem.loadFailed;
  }
  final confirmed = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (_) => GuardianDialog(text: text, childName: childName),
  );
  if (confirmed != true) return null;
  return api.GuardianConfirmationInput(
    confirmed: true,
    textVersion: text.version,
    language: text.language,
  );
}

class GuardianDialog extends StatefulWidget {
  const GuardianDialog({
    super.key,
    required this.text,
    required this.childName,
  });

  final api.ConsentText text;
  final String childName;

  @override
  State<GuardianDialog> createState() => _GuardianDialogState();
}

class _GuardianDialogState extends State<GuardianDialog> {
  /// Never pre-ticked (SET-10).
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final text = widget.text;
    return AlertDialog(
      scrollable: true,
      title: Text(l10n.familyGuardianTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (text.isDraft) ...[
            Text(l10n.consentDraftRibbon, style: theme.textTheme.labelMedium),
            const SizedBox(height: SpacingTokens.s),
          ],
          Text(text.title, style: theme.textTheme.titleMedium),
          for (final section in text.sections) ...[
            const SizedBox(height: SpacingTokens.m),
            Text(section.heading, style: theme.textTheme.titleSmall),
            const SizedBox(height: SpacingTokens.xs),
            Text(section.body),
          ],
          const SizedBox(height: SpacingTokens.l),
          CheckboxListTile(
            key: const Key('guardian.check'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _checked,
            onChanged: (value) => setState(() => _checked = value ?? false),
            title: Text(l10n.familyGuardianCheck(widget.childName)),
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('guardian.cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          key: const Key('guardian.confirm'),
          onPressed: _checked ? () => Navigator.of(context).pop(true) : null,
          child: Text(l10n.familyGuardianConfirm),
        ),
      ],
    );
  }
}
