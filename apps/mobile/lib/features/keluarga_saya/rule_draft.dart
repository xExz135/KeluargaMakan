// A hard rule the manager picked but that is not saved yet (F2r, F4).
//
// Drafts live only in the screen's memory until consent is given and the
// server confirms each rule (ACC-08: nothing stored before consent, not even
// on the phone). toString never prints the rule (security review L2).

import 'package:flutter/widgets.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../../l10n/generated/app_localizations.dart';
import 'labels.dart';

@immutable
final class RuleDraft {
  const RuleDraft.diet(this.type) : allergen = null, freeText = null;

  const RuleDraft.allergy(api.StandardAllergen this.allergen)
    : type = api.HardRuleType.allergy,
      freeText = null;

  /// A rule the manager wrote. Without a search endpoint (QUESTIONS #49) it
  /// is saved unmapped, so Cek Aman gives every recipe for the member
  /// "Cek label" until it is matched (PRF-08, SAF-09).
  const RuleDraft.written(String this.freeText, {required bool medical})
    : type = medical
          ? api.HardRuleType.medicalExclusion
          : api.HardRuleType.freeText,
      allergen = null;

  final api.HardRuleType type;
  final api.StandardAllergen? allergen;
  final String? freeText;

  bool get isWritten =>
      type == api.HardRuleType.freeText ||
      type == api.HardRuleType.medicalExclusion;

  api.HardRuleCreate toApi() => api.HardRuleCreate(
    type: type,
    allergen: allergen == null
        ? const api.Optional.absent()
        : api.Optional.present(allergen),
    freeText: freeText == null
        ? const api.Optional.absent()
        : api.Optional.present(freeText),
  );

  String label(AppLocalizations l10n, Locale locale) => ruleLabel(
    l10n,
    locale,
    (type: type, allergen: allergen, freeText: freeText),
  );

  /// Whether a saved rule is the same rule (case and spacing aside), so the
  /// picker does not offer it twice.
  bool sameAs(api.HardRule rule) =>
      rule.type == type &&
      rule.allergen == allergen &&
      _fold(rule.freeText) == _fold(freeText);

  static String? _fold(String? text) =>
      text?.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  @override
  bool operator ==(Object other) =>
      other is RuleDraft &&
      other.type == type &&
      other.allergen == allergen &&
      _fold(other.freeText) == _fold(freeText);

  @override
  int get hashCode => Object.hash(type, allergen, _fold(freeText));

  @override
  String toString() => 'RuleDraft(${type.toJson()})';
}
