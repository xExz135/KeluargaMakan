// F2 Add profile and the F3 header edit (PRF-01, PRF-07, PRF-18, SET-10;
// screens.md F2 and F2g).
//
// Name, age group and an initials avatar on one of the eight avatar colors.
// No member photo upload in V1 (QUESTIONS #27). The child flag comes from
// the server (`isChild`); it cannot be set by hand. A child age group needs
// the guardian confirmation (F2g) before the profile is created or changed.
// The manager's own profile offers Dewasa and Lansia only (QUESTIONS #46).
//
// Saving is online only in this version: there is no offline outbox yet,
// so without an answer the form stays open with what was typed
// (QUESTIONS, T-028 report).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../../core/api/api_error_text.dart';
import '../../core/api/api_problem.dart';
import '../../core/api/api_result.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/theme/tokens.dart';
import '../../data/family_profiles_state.dart';
import '../../data/models/family.dart';
import '../../data/repositories/auth_repository.dart' show randomUuidV4;
import '../../data/repositories/profiles_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../auth/widgets/onboarding_scaffold.dart';
import 'guardian_dialog.dart';
import 'labels.dart';
import 'widgets/family_widgets.dart';

/// What the form saved.
@immutable
final class ProfileFormResult {
  const ProfileFormResult(this.member, {required this.created});

  final FamilyMember member;
  final bool created;

  /// The member moved between adult and child and has stored rules: the
  /// manager is asked for consent again (QUESTIONS #62).
  bool get renewalRequired =>
      member.rules is RulesSaved &&
      (member.rules as RulesSaved).renewalRequired;
}

/// Opens F2 to add a member ([member] null) or edit one.
Future<ProfileFormResult?> openProfileForm(
  BuildContext context, {
  FamilyMember? member,
  int memberCount = 0,
}) => Navigator.of(context, rootNavigator: true).push<ProfileFormResult>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => ProfileFormScreen(member: member, memberCount: memberCount),
  ),
);

class ProfileFormScreen extends ConsumerStatefulWidget {
  const ProfileFormScreen({super.key, this.member, this.memberCount = 0});

  final FamilyMember? member;

  /// For a new member's default avatar color.
  final int memberCount;

  @override
  ConsumerState<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends ConsumerState<ProfileFormScreen> {
  static const _maxName = 30;
  static const _avatarCount = 8;

  late final TextEditingController _name;
  api.AgeGroup? _ageGroup;
  late int _colorIndex;
  bool _saving = false;
  String? _nameError;
  String? _message;

  /// The last create body sent and its key, so a retry of the same body
  /// reuses the key (and a changed body gets a new one).
  String? _sentBody;
  String? _sentKey;

  FamilyMember? get _member => widget.member;
  bool get _isManager => _member?.isManager ?? false;

  @override
  void initState() {
    super.initState();
    final member = _member;
    _name = TextEditingController(text: member?.name ?? '')
      ..addListener(() => setState(() => _nameError = null));
    _ageGroup = member?.ageGroup;
    _colorIndex = member == null
        ? widget.memberCount % _avatarCount
        : avatarColorIndex(
            member.avatar.colorToken.orElse(null),
            member.id,
            _avatarCount,
          );
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String get _trimmedName => _name.text.trim();

  bool get _dirty {
    final member = _member;
    if (member == null) {
      return _trimmedName.isNotEmpty || _ageGroup != null;
    }
    return _trimmedName != member.name ||
        _ageGroup != member.ageGroup ||
        _colorIndex !=
            avatarColorIndex(
              member.avatar.colorToken.orElse(null),
              member.id,
              _avatarCount,
            );
  }

  bool get _canSave => !_saving && _trimmedName.isNotEmpty && _ageGroup != null;

  api.Avatar get _avatar => api.Avatar(
    style: api.AvatarStyle.initials,
    colorToken: api.Optional.present(avatarColorToken(_colorIndex)),
  );

  Future<void> _confirmDiscard() async {
    if (!_dirty) {
      Navigator.of(context).pop();
      return;
    }
    final l10n = AppLocalizations.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: Text(l10n.familyAddDiscardTitle),
        actions: [
          TextButton(
            key: const Key('profile.discard.cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            key: const Key('profile.discard.confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.familyAddDiscardConfirm),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  /// The guardian confirmation for a child group, or null when the form
  /// should stop (cancelled, or the text could not load).
  Future<api.GuardianConfirmationInput?> _guardian() async {
    final l10n = AppLocalizations.of(context);
    final answer = await askGuardianConfirmation(
      context,
      ref,
      childName: _trimmedName,
    );
    if (!mounted) return null;
    switch (answer) {
      case api.GuardianConfirmationInput():
        return answer;
      case GuardianTextProblem.offline:
        setState(() => _message = l10n.familyGuardianOffline);
      case GuardianTextProblem.loadFailed:
        setState(() => _message = l10n.familyGuardianLoadError);
    }
    return null;
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final member = _member;
    final ageGroup = _ageGroup!;
    setState(() {
      _message = null;
      _nameError = null;
    });

    // A child group needs the guardian confirmation first: always for a new
    // child, and when an adult profile becomes a child.
    api.GuardianConfirmationInput? guardian;
    final needsGuardian =
        isChildAgeGroup(ageGroup) &&
        (member == null || !isChildAgeGroup(member.ageGroup));
    if (needsGuardian) {
      guardian = await _guardian();
      if (!mounted || guardian == null) return;
    }
    setState(() => _saving = true);

    final repo = ref.read(profilesRepositoryProvider);
    final ApiResult<FamilyMember> result;
    if (member == null) {
      final body = api.ProfileCreate(
        name: _trimmedName,
        ageGroup: ageGroup,
        avatar: api.Optional.present(_avatar),
        guardianConfirmation: guardian == null
            ? const api.Optional.absent()
            : api.Optional.present(guardian),
      );
      final wire = body.toJson().toString();
      if (wire != _sentBody) {
        _sentBody = wire;
        _sentKey = randomUuidV4();
      }
      result = await repo.createProfile(body, idempotencyKey: _sentKey!);
    } else {
      final body = api.ProfileUpdate(
        name: _trimmedName == member.name
            ? const api.Optional.absent()
            : api.Optional.present(_trimmedName),
        avatar: api.Optional.present(_avatar),
        ageGroup: ageGroup == member.ageGroup
            ? const api.Optional.absent()
            : api.Optional.present(ageGroup),
        guardianConfirmation: guardian == null
            ? const api.Optional.absent()
            : api.Optional.present(guardian),
      );
      result = await repo.updateProfile(member.id, body);
    }
    if (!mounted) return;
    await _handle(result);
  }

  Future<void> _handle(ApiResult<FamilyMember> result) async {
    final l10n = AppLocalizations.of(context);
    switch (result) {
      case Ok(:final value):
        await ref.read(familyProfilesProvider.notifier).refresh();
        if (!mounted) return;
        Navigator.of(context)
            .pop(ProfileFormResult(value, created: _member == null));
        return;
      case Err(failure: ManagerProfileMustBeAdultFailure()):
        _message = l10n.familyAgeManagerOnlyAdult;
      case Err(failure: NetworkFailure()):
        _message = l10n.familySaveOffline;
      case Err(failure: final ProblemFailure failure):
        final problem = failure.problem;
        switch (problem.code) {
          case ApiErrorCode.validationFailed:
            final nameError = problem.fieldErrors
                .where((e) => e.pointer == '/name')
                .firstOrNull;
            if (nameError != null) {
              _nameError = ApiErrorText.field(
                l10n,
                nameError.kind,
                maxLength: _maxName,
              );
            } else {
              _message = l10n.errorApiValidationFailed;
            }
          case ApiErrorCode.profileLimitReached:
            final state = ref.read(familyProfilesProvider);
            final max = state is FamilyLoaded
                ? state.profiles.maxProfiles ?? state.profiles.members.length
                : 12;
            _message = l10n.familyListLimitReached(max);
          case ApiErrorCode.guardianConfirmationRequired:
            _message = l10n.familyGuardianRequired;
          case ApiErrorCode.consentTextOutdated:
            _message = l10n.consentTextUpdated;
          case ApiErrorCode.notFound:
            _message = l10n.errorApiNotFound;
          default:
            _message = ApiErrorText.of(l10n, failure).body;
        }
      case Err(:final failure):
        _message = ApiErrorText.of(l10n, failure).body;
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final groups = ageGroupsFor(manager: _isManager);
    final initials = initialsOf(_trimmedName.isEmpty ? '?' : _trimmedName);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_saving) _confirmDiscard();
      },
      child: OnboardingScaffold(
        title: _member == null ? l10n.familyAddTitle : l10n.familyEditTitle,
        bottom: [
          OnboardingButton(
            key: const Key('profile.save'),
            label: l10n.familyAddSave,
            loadingLabel: _saving ? l10n.commonLoading : null,
            onPressed: _canSave ? _save : null,
          ),
        ],
        children: [
          TextField(
            key: const Key('profile.name'),
            controller: _name,
            enabled: !_saving,
            maxLength: _maxName,
            textCapitalization: TextCapitalization.words,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l10n.familyAddNameLabel,
              hintText: l10n.familyAddNameHint,
              errorText: _nameError,
            ),
          ),
          const SizedBox(height: SpacingTokens.l),
          Semantics(
            header: true,
            child: Text(
              l10n.familyAddAgeGroup,
              style: theme.textTheme.titleMedium,
            ),
          ),
          if (_isManager) ...[
            const SizedBox(height: SpacingTokens.xs),
            Text(l10n.familyAgeManagerOnlyAdult),
          ],
          const SizedBox(height: SpacingTokens.s),
          Wrap(
            spacing: SpacingTokens.s,
            runSpacing: SpacingTokens.s,
            children: [
              for (final group in groups)
                ChoiceChip(
                  key: Key('profile.age.${group.toJson()}'),
                  label: Text(ageGroupLabel(l10n, group)),
                  selected: _ageGroup == group,
                  onSelected: _saving
                      ? null
                      : (_) => setState(() => _ageGroup = group),
                ),
            ],
          ),
          const SizedBox(height: SpacingTokens.xl),
          Semantics(
            header: true,
            child: Text(
              l10n.familyAddAvatar,
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: SpacingTokens.s),
          Wrap(
            spacing: SpacingTokens.s,
            runSpacing: SpacingTokens.s,
            children: [
              for (var i = 0; i < _avatarCount; i++)
                Semantics(
                  button: true,
                  selected: _colorIndex == i,
                  label: l10n.familyAddAvatarColor(i + 1),
                  child: InkResponse(
                    key: Key('profile.avatar.$i'),
                    onTap: _saving
                        ? null
                        : () => setState(() => _colorIndex = i),
                    radius: 28,
                    child: ExcludeSemantics(
                      child: Container(
                        width: 56,
                        height: 56,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _colorIndex == i
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            width: BorderTokens.focus,
                          ),
                        ),
                        child: AvatarCircle(
                          initials: initials,
                          background: colors.avatarBackgrounds[i],
                          foreground: colors.avatarText,
                          size: 44,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (_message != null) ...[
            const SizedBox(height: SpacingTokens.l),
            InlineMessage(key: const Key('profile.message'), text: _message!),
          ],
        ],
      ),
    );
  }
}
