// Bottom navigation for compact windows (navigation.md 2, components.md
// navigationBarTheme).
//
// Material's NavigationBar clamps label text to 1.3x and has a fixed height.
// accessibility.md 3 requires labels to follow system text scaling up to
// 200%, wrapping to two lines instead of being hidden, and no fixed height on
// the navigation bar, so this bar is 80dp at minimum and grows with its
// labels. Colors and label styles come from the navigationBarTheme.

import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

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
        child: ConstrainedBox(
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
                      onTap: () => onSelected(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Destination extends StatelessWidget {
  const _Destination({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final ShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final states = {if (selected) WidgetState.selected};
    final labelStyle =
        theme.navigationBarTheme.labelTextStyle?.resolve(states) ??
        theme.textTheme.labelSmall;
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
            horizontal: SpacingTokens.xs,
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
              Text(
                destination.label,
                style: labelStyle,
                textAlign: TextAlign.center,
                softWrap: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
