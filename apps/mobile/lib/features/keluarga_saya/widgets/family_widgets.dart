// Building blocks shared by the Keluarga Saya screens (screens.md F1 to F6).
//
// None of these shows a safety state. The neutral note uses the
// `neutralContainer` colors and the outlined info icon (safety-badges.md
// 4.4); the safety colors and icons are never used here.

import 'package:flutter/material.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/tokens.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Initials on one of the eight avatar colors (tokens.json `avatar`).
/// `avatar_1` … `avatar_8` pick the color; anything else falls back to a
/// stable hash of the profile ID (contract-alignment.md 4, M10). No member
/// photos in V1 (QUESTIONS #27). Decorative: the name is always next to it.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.profileId,
    required this.name,
    required this.avatar,
    this.size = 40,
  });

  final String profileId;
  final String name;
  final api.Avatar avatar;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final index = avatarColorIndex(
      avatar.colorToken.orElse(null),
      profileId,
      colors.avatarBackgrounds.length,
    );
    return ExcludeSemantics(
      child: AvatarCircle(
        initials: initialsOf(name),
        background: colors.avatarBackgrounds[index],
        foreground: colors.avatarText,
        size: size,
      ),
    );
  }
}

class AvatarCircle extends StatelessWidget {
  const AvatarCircle({
    super.key,
    required this.initials,
    required this.background,
    required this.foreground,
    required this.size,
  });

  final String initials;
  final Color background;
  final Color foreground;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: background, shape: BoxShape.circle),
    // The circle has a fixed size, so the initials do not scale with the
    // system text size (the name next to it does).
    child: Text(
      initials,
      maxLines: 1,
      textScaler: TextScaler.noScaling,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(color: foreground, fontSize: size * 0.4, height: 1),
    ),
  );
}

/// `avatar_N` → N - 1; otherwise a stable hash of [profileId].
int avatarColorIndex(String? token, String profileId, int count) {
  final match = RegExp(r'^avatar_([1-9])$').firstMatch(token ?? '');
  final n = match == null ? null : int.parse(match.group(1)!);
  if (n != null && n <= count) return n - 1;
  // FNV-1a over the UTF-16 code units: the same on every run and device.
  var hash = 0x811c9dc5;
  for (final unit in profileId.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
  }
  return hash % count;
}

/// The contract token for avatar color [index] (0-based).
String avatarColorToken(int index) => 'avatar_${index + 1}';

/// Up to two initials: "Mama Rina" → "MR", "ibu" → "I".
String initialsOf(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  return words.take(2).map((w) => w.characters.first.toUpperCase()).join();
}

/// A small text tag such as "Anda" or "Anak" (never a color alone).
class TextTag extends StatelessWidget {
  const TextTag(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(RadiusTokens.badge),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.s,
          vertical: 2,
        ),
        child: Text(
          text,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}

/// The neutral "rules not saved / not filled in / not loaded" line:
/// `neutralContainer` with the outlined info icon. Not a safety state.
class NeutralNote extends StatelessWidget {
  const NeutralNote({super.key, required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final app = AppColors.of(context);
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: app.neutralContainer,
        borderRadius: BorderRadius.circular(RadiusTokens.badge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.s),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon ?? Icons.info_outlined,
              size: IconSizeTokens.badgeCompact,
              color: app.neutralIcon,
            ),
            const SizedBox(width: SpacingTokens.s),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: app.onNeutralContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A section card on F3 with a title, an optional "Ubah" button and body.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.children,
    this.onEdit,
    this.editKey,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback? onEdit;
  final Key? editKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final app = AppColors.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: app.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusTokens.card),
        side: BorderSide(color: app.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: theme.textTheme.titleLarge),
                  ),
                ),
                if (onEdit != null)
                  TextButton(
                    key: editKey,
                    onPressed: onEdit,
                    child: Text(l10n.commonEdit),
                  ),
              ],
            ),
            const SizedBox(height: SpacingTokens.s),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// A static grey block for loading states (no animation, so tests and
/// reduced-motion settings are not affected).
class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({super.key, this.height = 72});

  final double height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.of(context).skeleton,
        borderRadius: BorderRadius.circular(RadiusTokens.card),
      ),
    ),
  );
}

/// A full-width error with a title, body and "Coba lagi".
class ErrorPanel extends StatelessWidget {
  const ErrorPanel({
    super.key,
    required this.title,
    required this.body,
    required this.onRetry,
    this.retryKey,
  });

  final String? title;
  final String body;
  final VoidCallback onRetry;
  final Key? retryKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(RadiusTokens.card),
        ),
        child: Padding(
          padding: const EdgeInsets.all(SpacingTokens.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, color: scheme.onErrorContainer),
                  const SizedBox(width: SpacingTokens.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          Text(
                            title!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: scheme.onErrorContainer,
                            ),
                          ),
                        Text(
                          body,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SpacingTokens.m),
              FilledButton.tonal(
                key: retryKey,
                onPressed: onRetry,
                child: Text(l10n.commonRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows a snackbar with [text], replacing any current one.
void showFamilySnack(BuildContext context, String text) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}
