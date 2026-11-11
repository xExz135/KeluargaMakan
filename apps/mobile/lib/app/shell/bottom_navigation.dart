// Bottom navigation for compact windows (navigation.md 2, components.md
// navigationBarTheme).
//
// Material's NavigationBar clamps label text to a fixed 1.3x and has a fixed
// height. Here labels follow the system text size and only shrink when they
// would not fit their slot on one line (FittedNavLabel, owner decision
// 2026-11-11). The bar is 80dp at minimum and grows with its labels. Colors
// and label styles come from the navigationBarTheme.

import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import 'fitted_nav_label.dart';

@immutable
final class ShellDestination {
  const ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<ShellDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navTheme = theme.navigationBarTheme;
    return Material(
      color: navTheme.backgroundColor ?? theme.colorScheme.surfaceContainer,
      elevation: navTheme.elevation ?? ElevationTokens.level2,
      shadowColor: theme.colorScheme.shadow,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        top: false,
        // The slot width is measured here because IntrinsicHeight below
        // cannot contain a LayoutBuilder.
        child: LayoutBuilder(
          builder: (context, constraints) {
            final labelWidth =
                constraints.maxWidth / destinations.length -
                2 * _Destination.horizontalPadding;
            // One size for every label, measured in the bold selected style
            // (owner decision 2026-11-11: shrink to fit, never mid-word).
            final labelScaler = fitAllTextScaler(
              texts: [for (final d in destinations) d.label],
              style: DefaultTextStyle.of(context).style.merge(
                _Destination.labelStyle(Theme.of(context), selected: true),
              ),
              scaler: MediaQuery.textScalerOf(context),
              maxWidth: labelWidth,
              textDirection: Directionality.of(context),
            );
            return ConstrainedBox(
              constraints: BoxConstraints(minHeight: navTheme.height ?? 80),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < destinations.length; i++)
                      Expanded(
                        child: _Destination(
                          destination: destinations[i],
                          selected: i == selectedIndex,
                          labelScaler: labelScaler,
                          onTap: () => onSelected(i),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Destination extends StatelessWidget {
  const _Destination({
    required this.destination,
    required this.selected,
    required this.labelScaler,
    required this.onTap,
  });

  static const double horizontalPadding = SpacingTokens.xs;

  static TextStyle? labelStyle(ThemeData theme, {required bool selected}) =>
      theme.navigationBarTheme.labelTextStyle?.resolve({
        if (selected) WidgetState.selected,
      }) ??
      theme.textTheme.labelSmall;

  final ShellDestination destination;
  final bool selected;

  /// Shared scaler that fits every label of the bar on one line.
  final TextScaler labelScaler;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final labelStyle = _Destination.labelStyle(theme, selected: selected);
    final indicator =
        theme.navigationBarTheme.indicatorColor ?? scheme.primaryContainer;
    // Selection is shown by the filled icon and the pill, not color alone.
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: SpacingTokens.m,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 32,
                decoration: ShapeDecoration(
                  color: selected ? indicator : Colors.transparent,
                  shape: const StadiumBorder(),
                ),
                child: Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  color: selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: SpacingTokens.xs),
              // One line, shrunk to fit at large text sizes; the text (and so
              // the semantics label) is never cut.
              Text(
                destination.label,
                style: labelStyle,
                textScaler: labelScaler,
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
