// F5 sheets: taste (PRF-05), likes and dislikes (PRF-06), portions (PRF-07).
//
// Soft data, never health data. Each sheet sends the whole object
// (`replaceSoftPreferences`, `replaceLikesDislikes`) or only the changed
// portion fields, and closes once the server confirmed. Without an answer
// the sheet stays open with the choices (no offline outbox yet, see the
// T-028 report). Likes and dislikes can only be removed here: adding needs
// the ingredient and dish search the contract does not have yet
// (QUESTIONS #49, contract-alignment.md M7).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../../../core/api/api_error_text.dart';
import '../../../core/api/api_result.dart';
import '../../../core/theme/tokens.dart';
import '../../../data/family_profiles_state.dart';
import '../../../data/models/family.dart';
import '../../../data/repositories/profiles_repository.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/widgets/onboarding_scaffold.dart';
import '../labels.dart';
import 'family_widgets.dart';

Future<void> _showSheet(BuildContext context, Widget child) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => child,
    );

Future<void> showPreferencesSheet(
  BuildContext context, {
  required FamilyMember member,
  required api.SoftPreferences current,
}) => _showSheet(context, _PreferencesSheet(member: member, current: current));

Future<void> showLikesSheet(
  BuildContext context, {
  required FamilyMember member,
  required api.LikesDislikes current,
}) => _showSheet(context, _LikesSheet(member: member, current: current));

Future<void> showPortionsSheet(
  BuildContext context, {
  required FamilyMember member,
  required api.Portions current,
}) => _showSheet(context, _PortionsSheet(member: member, current: current));

/// The frame of an F5 sheet: title with close, scrolling body, Simpan.
class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.title,
    required this.children,
    required this.onSave,
    required this.saving,
    this.message,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback? onSave;
  final bool saving;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return PopScope(
      canPop: !saving,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SpacingTokens.l,
                SpacingTokens.l,
                SpacingTokens.xs,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(title, style: theme.textTheme.titleLarge),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: l10n.commonClose,
                    onPressed: saving
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(SpacingTokens.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...children,
                    if (message != null) ...[
                      const SizedBox(height: SpacingTokens.m),
                      InlineMessage(text: message!),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SpacingTokens.l,
                0,
                SpacingTokens.l,
                SpacingTokens.l,
              ),
              child: OnboardingButton(
                key: const Key('sheet.save'),
                label: l10n.commonSave,
                loadingLabel: saving ? l10n.commonLoading : null,
                onPressed: onSave,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _heading(BuildContext context, String text) => Padding(
  padding: const EdgeInsets.only(top: SpacingTokens.s, bottom: SpacingTokens.s),
  child: Semantics(
    header: true,
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  ),
);

/// Saves with [send]; closes on success, else returns the message to show.
Future<String?> _saveWith<T>(
  BuildContext context,
  WidgetRef ref,
  Future<ApiResult<T>> Function() send,
) async {
  final l10n = AppLocalizations.of(context);
  final result = await send();
  if (!context.mounted) return null;
  switch (result) {
    case Ok():
      await ref.read(familyProfilesProvider.notifier).refresh();
      if (!context.mounted) return null;
      Navigator.of(context).pop();
      showFamilySnack(context, l10n.familyPrefsSaved);
      return null;
    case Err(failure: NetworkFailure()):
      return l10n.familySaveOffline;
    case Err(:final failure):
      return ApiErrorText.of(l10n, failure).body;
  }
}

// ------------------------------------------------------------ Taste

class _PreferencesSheet extends ConsumerStatefulWidget {
  const _PreferencesSheet({required this.member, required this.current});

  final FamilyMember member;
  final api.SoftPreferences current;

  @override
  ConsumerState<_PreferencesSheet> createState() => _PreferencesSheetState();
}

class _PreferencesSheetState extends ConsumerState<_PreferencesSheet> {
  late api.SpiceLevel? _spice = widget.current.spiceLevel;
  late final Set<api.LessOf> _less = {...widget.current.lessOf};
  late final Set<api.TexturePreference> _textures = {
    ...widget.current.textures,
  };
  bool _saving = false;
  String? _message;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _message = null;
    });
    final body = api.SoftPreferencesInput(
      spiceLevel: _spice,
      lessOf: _less,
      textures: _textures,
    );
    final message = await _saveWith(
      context,
      ref,
      () => ref
          .read(profilesRepositoryProvider)
          .replaceSoftPreferences(widget.member.id, body),
    );
    if (mounted) {
      setState(() {
        _saving = false;
        _message = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Wrap wrap(List<Widget> children) => Wrap(
      spacing: SpacingTokens.s,
      runSpacing: SpacingTokens.s,
      children: children,
    );
    return _SheetFrame(
      title: l10n.familyPrefsTitle,
      saving: _saving,
      message: _message,
      onSave: _saving ? null : _save,
      children: [
        Text(l10n.familyPrefsExplainer),
        _heading(context, l10n.onboardingTasteSpice),
        wrap([
          for (final level in spiceLevels)
            ChoiceChip(
              key: Key('prefs.spice.${level.toJson()}'),
              label: Text(spiceLabel(l10n, level)),
              selected: _spice == level,
              // Tapping the chosen level again clears it (null: ranked as
              // medium, contract SoftPreferencesInput).
              onSelected: _saving
                  ? null
                  : (on) => setState(() => _spice = on ? level : null),
            ),
        ]),
        const SizedBox(height: SpacingTokens.l),
        wrap([
          for (final value in lessOfValues)
            FilterChip(
              key: Key('prefs.less.${value.toJson()}'),
              label: Text(lessOfLabel(l10n, value)),
              selected: _less.contains(value),
              onSelected: _saving
                  ? null
                  : (on) => setState(
                      () => on ? _less.add(value) : _less.remove(value),
                    ),
            ),
          for (final value in textureValues)
            FilterChip(
              key: Key('prefs.texture.${value.toJson()}'),
              label: Text(textureLabel(l10n, value)),
              selected: _textures.contains(value),
              onSelected: _saving
                  ? null
                  : (on) => setState(
                      () => on ? _textures.add(value) : _textures.remove(value),
                    ),
            ),
        ]),
      ],
    );
  }
}

// ------------------------------------------------------------ Likes

class _LikesSheet extends ConsumerStatefulWidget {
  const _LikesSheet({required this.member, required this.current});

  final FamilyMember member;
  final api.LikesDislikes current;

  @override
  ConsumerState<_LikesSheet> createState() => _LikesSheetState();
}

class _LikesSheetState extends ConsumerState<_LikesSheet> {
  late final List<api.FoodRef> _likes = [...widget.current.likes];
  late final List<api.FoodRef> _dislikes = [...widget.current.dislikes];
  bool _saving = false;
  String? _message;

  static List<api.FoodRefInput> _inputs(List<api.FoodRef> items) => [
    for (final item in items)
      api.FoodRefInput(kind: item.kind, refId: item.refId),
  ];

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _message = null;
    });
    final body = api.LikesDislikesInput(
      likes: _inputs(_likes),
      dislikes: _inputs(_dislikes),
    );
    final message = await _saveWith(
      context,
      ref,
      () => ref
          .read(profilesRepositoryProvider)
          .replaceLikesDislikes(widget.member.id, body),
    );
    if (mounted) {
      setState(() {
        _saving = false;
        _message = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    Widget list(String title, List<api.FoodRef> items) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(context, title),
        if (items.isEmpty)
          Text(l10n.familyNothingYet)
        else
          Wrap(
            spacing: SpacingTokens.s,
            runSpacing: SpacingTokens.s,
            children: [
              for (final item in items)
                InputChip(
                  label: Text(localized(locale, item.displayName)),
                  deleteButtonTooltipMessage: l10n.familyLikesRemoveTooltip(
                    localized(locale, item.displayName),
                  ),
                  onDeleted: _saving
                      ? null
                      : () => setState(() => items.remove(item)),
                ),
            ],
          ),
      ],
    );
    return _SheetFrame(
      title: l10n.familyLikesTitle,
      saving: _saving,
      message: _message,
      onSave: _saving ? null : _save,
      children: [
        list(l10n.familyLikesLike, _likes),
        list(l10n.familyLikesDislike, _dislikes),
        const SizedBox(height: SpacingTokens.m),
        NeutralNote(text: l10n.familyLikesSearchUnavailable),
      ],
    );
  }
}

// ------------------------------------------------------------ Portions

class _PortionsSheet extends ConsumerStatefulWidget {
  const _PortionsSheet({required this.member, required this.current});

  final FamilyMember member;
  final api.Portions current;

  @override
  ConsumerState<_PortionsSheet> createState() => _PortionsSheetState();
}

class _PortionsSheetState extends ConsumerState<_PortionsSheet> {
  /// Null: the age-group default from configuration (PRF-07).
  late api.PortionSize? _meal = widget.current.portionSizeIsDefault
      ? null
      : widget.current.portionSize;
  late api.PortionSize? _rice = widget.current.ricePortionIsDefault
      ? null
      : widget.current.ricePortion;
  bool _saving = false;
  String? _message;

  api.PortionSize? get _savedMeal =>
      widget.current.portionSizeIsDefault ? null : widget.current.portionSize;
  api.PortionSize? get _savedRice =>
      widget.current.ricePortionIsDefault ? null : widget.current.ricePortion;

  Future<void> _save() async {
    if (_meal == _savedMeal && _rice == _savedRice) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = true;
      _message = null;
    });
    final body = api.ProfileUpdate(
      portionSize: _meal == _savedMeal
          ? const api.Optional.absent()
          : api.Optional.present(_meal),
      ricePortion: _rice == _savedRice
          ? const api.Optional.absent()
          : api.Optional.present(_rice),
    );
    final message = await _saveWith(
      context,
      ref,
      () => ref
          .read(profilesRepositoryProvider)
          .updateProfile(widget.member.id, body),
    );
    if (mounted) {
      setState(() {
        _saving = false;
        _message = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget row(
      String key,
      String title,
      api.PortionSize? chosen,
      api.PortionSize? shownDefault,
      ValueChanged<api.PortionSize?> onChanged,
    ) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(context, title),
        Wrap(
          spacing: SpacingTokens.s,
          runSpacing: SpacingTokens.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final size in portionSizes)
              ChoiceChip(
                key: Key('portion.$key.${size.toJson()}'),
                label: Text(portionLabel(l10n, size)),
                selected: (chosen ?? shownDefault) == size,
                onSelected: _saving ? null : (_) => onChanged(size),
              ),
            if (chosen == null)
              TextTag(l10n.familyPortionDefault)
            else
              TextButton(
                key: Key('portion.$key.default'),
                onPressed: _saving ? null : () => onChanged(null),
                child: Text(l10n.familyPortionUseDefault),
              ),
          ],
        ),
      ],
    );
    // While a value is the age-group default (`*IsDefault`), its chip shows
    // the server's default. After "Pakai bawaan" on a custom value the
    // default is not known yet: no size is ticked until the server answers.
    return _SheetFrame(
      title: l10n.familyPortionTitle,
      saving: _saving,
      message: _message,
      onSave: _saving ? null : _save,
      children: [
        row(
          'meal',
          l10n.familyPortionMeal,
          _meal,
          widget.current.portionSizeIsDefault
              ? widget.current.portionSize
              : null,
          (v) => setState(() => _meal = v),
        ),
        row(
          'rice',
          l10n.familyPortionRice,
          _rice,
          widget.current.ricePortionIsDefault
              ? widget.current.ricePortion
              : null,
          (v) => setState(() => _rice = v),
        ),
      ],
    );
  }
}
