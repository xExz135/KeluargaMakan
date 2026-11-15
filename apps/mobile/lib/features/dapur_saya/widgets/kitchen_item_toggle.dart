// KitchenItemToggle (components.md 8.5; KIT-02, KIT-05, NFR-02, INT-03).
//
// - "Ada": kitchen container fill and border, a plain `check` icon.
// - "Habis": the out container, no icon, the word "Habis" after the name.
// So the state never rests on color alone. The kitchen colors are not the
// safety colors: "I have it" must never read as "it is safe".
// - Custom item (KIT-05): a small `help` icon and "Belum dikenal". It is not
//   a safety badge; Cek Aman gives such items "Cek label" (SAF-09) on its
//   own surfaces.
// - A change not confirmed by the server yet (queued or on its way,
//   KIT-16): a 6 dp dot, read as "Belum terkirim".
// - Amount or brand (KIT-09): a second line, "Sedikit · {brand}", read
//   after the name. A brand is a name only, never a safety mark.
// One tap toggles; long press opens the item sheet. Height at least
// `kitchen.toggleMinHeightDp`; names wrap and never truncate.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/tokens.dart';
import '../../../l10n/generated/app_localizations.dart';

class KitchenItemToggle extends StatelessWidget {
  const KitchenItemToggle({
    super.key,
    required this.name,
    required this.available,
    required this.minHeight,
    required this.onTap,
    this.isCustom = false,
    this.pending = false,
    this.details,
    this.onLongPress,
    this.stateOnly = false,
  });

  /// The ingredient name, shown and read out.
  final String name;
  final bool available;
  final bool isCustom;

  /// A change the server has not confirmed yet.
  final bool pending;

  /// The amount and brand line, or null.
  final String? details;
  final double minHeight;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// Shows only the state word ("Ada" / "Habis"), for rows that already
  /// name the ingredient (K2 search results). Still read with the name.
  final bool stateOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final app = AppColors.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    // Icons grow with the text up to 1.5x, staying next to their word.
    double icon(double size) => math.min(scaler.scale(size), size * 1.5);

    final background = available
        ? app.kitchenAvailableContainer
        : app.kitchenOutContainer;
    final foreground = available
        ? app.onKitchenAvailableContainer
        : app.onKitchenOutContainer;
    final border = available
        ? app.kitchenAvailableBorder
        : app.kitchenOutBorder;
    final nameStyle = theme.textTheme.labelLarge?.copyWith(color: foreground);
    final smallStyle = theme.textTheme.bodySmall?.copyWith(color: foreground);

    final label = [
      available
          ? l10n.kitchenItemA11yAvailable(name)
          : l10n.kitchenItemA11yOut(name),
      if (details != null && !stateOnly) '$details.',
      if (isCustom) l10n.kitchenItemA11yCustom,
      if (pending) l10n.kitchenItemA11yPending,
    ].join(' ');

    final Widget text = stateOnly
        ? Text(
            available ? l10n.kitchenFilterAvailable : l10n.kitchenItemOutLabel,
            style: nameStyle,
          )
        : Text.rich(
            TextSpan(
              children: [
                TextSpan(text: name),
                if (!available)
                  TextSpan(
                    text: ' · ${l10n.kitchenItemOutLabel}',
                    style: smallStyle,
                  ),
              ],
            ),
            style: nameStyle,
          );

    void tap() {
      HapticFeedback.selectionClick();
      onTap();
    }

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(RadiusTokens.control),
      side: BorderSide(color: border, width: BorderTokens.hairline),
    );

    return Semantics(
      // Its own node, so it is never merged with the text next to it.
      container: true,
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: tap,
      onLongPress: onLongPress,
      onLongPressHint: onLongPress == null ? null : l10n.kitchenItemOptionsHint,
      child: Material(
        color: background,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: tap,
          onLongPress: onLongPress,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight, minWidth: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.m,
                vertical: SpacingTokens.s,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (available) ...[
                    Icon(
                      Icons.check,
                      size: icon(IconSizeTokens.badgeCompact),
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: SpacingTokens.xs),
                  ],
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        text,
                        if (details case final line? when !stateOnly)
                          Text(
                            line,
                            key: const Key('kitchen.item.details'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: foreground,
                            ),
                          ),
                        if (isCustom && !stateOnly)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.help_outline,
                                size: icon(16),
                                color: foreground,
                              ),
                              const SizedBox(width: SpacingTokens.xs),
                              Flexible(
                                child: Text(
                                  l10n.kitchenItemCustomMarker,
                                  style: smallStyle,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (pending) ...[
                    const SizedBox(width: SpacingTokens.s),
                    Container(
                      key: const Key('kitchen.item.pendingDot'),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
