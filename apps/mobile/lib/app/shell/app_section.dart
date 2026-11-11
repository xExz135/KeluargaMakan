// Main navigation sections (INT-02, docs/design/navigation.md 1).

import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/config/config_keys.dart';
import '../../l10n/generated/app_localizations.dart';

enum AppSection {
  home('/home', Icons.home_outlined, Icons.home_rounded),
  kitchen('/kitchen', Icons.kitchen_outlined, Icons.kitchen_rounded),
  recipes('/recipes', Icons.menu_book_outlined, Icons.menu_book_rounded),

  /// V2 attach point (Rencana Mingguan). Hidden unless nav.planTabEnabled.
  plan('/plan', Icons.calendar_month_outlined, Icons.calendar_month_rounded),
  family('/family', Icons.group_outlined, Icons.group_rounded);

  const AppSection(this.path, this.icon, this.selectedIcon);

  final String path;
  final IconData icon;
  final IconData selectedIcon;

  /// INT-02: no more than five sections.
  static const maxSections = 5;

  String label(AppLocalizations l10n) => switch (this) {
    home => l10n.navHome,
    kitchen => l10n.navKitchen,
    recipes => l10n.navRecipes,
    plan => l10n.navPlan,
    family => l10n.navFamily,
  };

  /// The sections shown, in INT-02 order. V1: Beranda, Dapur Saya, Resep,
  /// Keluarga.
  static List<AppSection> visible(AppConfig config) {
    final planEnabled = config.get(ConfigKeys.planTabEnabled);
    final sections = [
      for (final section in values)
        if (section != plan || planEnabled) section,
    ];
    assert(sections.length <= maxSections, 'INT-02 allows at most 5 sections');
    return sections;
  }
}
