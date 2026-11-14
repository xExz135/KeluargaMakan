// Localized labels for Keluarga Saya values (contract-alignment.md 3 and 4).
//
// Every label comes from a contract code. The allergen picker lists the
// codes in the API's order (listStandardAllergens); this file only names
// them and never decides which allergens exist (PRF-04). Rule labels are
// plain names, never a safety state: no rule label says a person or a food
// is "aman".

import 'package:flutter/widgets.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../../l10n/generated/app_localizations.dart';

String ageGroupLabel(AppLocalizations l10n, api.AgeGroup group) =>
    switch (group) {
      api.AgeGroup.infant => l10n.ageInfant,
      api.AgeGroup.child => l10n.ageChild,
      api.AgeGroup.teen => l10n.ageTeen,
      api.AgeGroup.adult => l10n.ageAdult,
      api.AgeGroup.elderly => l10n.ageElderly,
    };

/// Infant, child and teen are child profiles (PRF-18, DECISIONS 2026-11-10).
/// The server's `isChild` is the flag shown; this only picks the flow
/// before a profile exists (guardian confirmation, SET-10).
bool isChildAgeGroup(api.AgeGroup group) =>
    group != api.AgeGroup.adult && group != api.AgeGroup.elderly;

/// The age groups offered, in PRF-01 order. The manager's own profile is
/// always an adult (DECISIONS 2026-11-12, QUESTIONS #46).
List<api.AgeGroup> ageGroupsFor({required bool manager}) => manager
    ? const [api.AgeGroup.adult, api.AgeGroup.elderly]
    : const [
        api.AgeGroup.infant,
        api.AgeGroup.child,
        api.AgeGroup.teen,
        api.AgeGroup.adult,
        api.AgeGroup.elderly,
      ];

/// The allergen's name. Null (an allergy code this app version does not
/// know) is "Alergi lain".
String allergenLabel(AppLocalizations l10n, api.StandardAllergen? code) =>
    switch (code) {
      api.StandardAllergen.peanut => l10n.allergenPeanut,
      api.StandardAllergen.treeNut => l10n.allergenTreeNut,
      api.StandardAllergen.shellfish => l10n.allergenShellfishAll,
      api.StandardAllergen.shrimp => l10n.allergenShrimp,
      api.StandardAllergen.fish => l10n.allergenFish,
      api.StandardAllergen.egg => l10n.allergenEgg,
      api.StandardAllergen.milk => l10n.allergenMilk,
      api.StandardAllergen.soy => l10n.allergenSoy,
      api.StandardAllergen.wheat => l10n.allergenWheat,
      api.StandardAllergen.gluten => l10n.allergenGluten,
      api.StandardAllergen.sesame => l10n.allergenSesame,
      null => l10n.allergenUnknown,
    };

String dietLabel(AppLocalizations l10n, api.HardRuleType type) =>
    switch (type) {
      api.HardRuleType.halal => l10n.ruleHalal,
      api.HardRuleType.vegetarian => l10n.ruleVegetarian,
      api.HardRuleType.vegan => l10n.ruleVegan,
      // Not diet rules; named by ruleLabel.
      api.HardRuleType.allergy ||
      api.HardRuleType.medicalExclusion ||
      api.HardRuleType.freeText => '',
    };

/// The diet rules in the picker's order.
const dietRuleTypes = [
  api.HardRuleType.halal,
  api.HardRuleType.vegetarian,
  api.HardRuleType.vegan,
];

/// The groups of F3's Aturan wajib section, in order.
enum RuleGroup { diet, allergy, medical, other }

RuleGroup ruleGroupOf(api.HardRuleType type) => switch (type) {
  api.HardRuleType.allergy => RuleGroup.allergy,
  api.HardRuleType.medicalExclusion => RuleGroup.medical,
  api.HardRuleType.freeText => RuleGroup.other,
  api.HardRuleType.halal ||
  api.HardRuleType.vegetarian ||
  api.HardRuleType.vegan => RuleGroup.diet,
};

String ruleGroupLabel(AppLocalizations l10n, RuleGroup group) =>
    switch (group) {
      RuleGroup.diet => l10n.onboardingRulesGroupDiet,
      RuleGroup.allergy => l10n.onboardingRulesGroupAllergy,
      RuleGroup.medical => l10n.familyRulesGroupMedical,
      RuleGroup.other => l10n.onboardingRulesGroupOther,
    };

/// What a rule is, in one line: an allergy (Alergi Udang), a diet (Halal),
/// the written text, or a doctor's restriction (Pantangan dokter: …). A
/// doctor's restriction without text is named by its matched ingredients.
String ruleLabel(
  AppLocalizations l10n,
  Locale locale,
  ({api.HardRuleType type, api.StandardAllergen? allergen, String? freeText})
  rule, {
  List<api.MappedIngredient> mapped = const [],
}) => switch (rule.type) {
  api.HardRuleType.allergy => l10n.rulesFreeTextAsAllergy(
    allergenLabel(l10n, rule.allergen),
  ),
  api.HardRuleType.freeText => rule.freeText ?? '',
  api.HardRuleType.medicalExclusion => l10n.familyRulesMedicalLabel(
    rule.freeText ?? ingredientNames(locale, mapped),
  ),
  final type => dietLabel(l10n, type),
};

String hardRuleLabel(AppLocalizations l10n, Locale locale, api.HardRule r) =>
    ruleLabel(l10n, locale, (
      type: r.type,
      allergen: r.allergen,
      freeText: r.freeText,
    ), mapped: r.mapping?.ingredients ?? const []);

/// Server-localized names (`LocalizedText`) in the app's language.
String localized(Locale locale, api.LocalizedText text) =>
    locale.languageCode == 'en' ? text.en : text.id;

String ingredientNames(Locale locale, List<api.MappedIngredient> items) =>
    items.map((i) => localized(locale, i.displayName)).join(', ');

/// Whether a free-text or doctor's rule is still waiting to be matched, so
/// Cek Aman gives every recipe for the member "Cek label" (PRF-08, SAF-09).
/// Only `mapped` with a confirmer counts as matched; anything else waits
/// (contract-alignment.md 2).
bool isAwaitingMapping(api.HardRule rule) {
  if (rule.type != api.HardRuleType.freeText &&
      rule.type != api.HardRuleType.medicalExclusion) {
    return false;
  }
  final mapping = rule.mapping;
  return mapping == null ||
      mapping.status != api.MappingStatus.mapped ||
      mapping.confirmedBy == null;
}

String spiceLabel(AppLocalizations l10n, api.SpiceLevel level) =>
    switch (level) {
      api.SpiceLevel.notSpicy => l10n.prefSpiceNone,
      api.SpiceLevel.medium => l10n.prefSpiceMedium,
      api.SpiceLevel.spicy => l10n.prefSpiceHot,
    };

const spiceLevels = [
  api.SpiceLevel.notSpicy,
  api.SpiceLevel.medium,
  api.SpiceLevel.spicy,
];

String lessOfLabel(AppLocalizations l10n, api.LessOf value) => switch (value) {
  api.LessOf.fried => l10n.prefLessFried,
  api.LessOf.sugar => l10n.prefLessSugar,
  api.LessOf.salt => l10n.prefLessSalt,
  api.LessOf.santan => l10n.prefLessSantan,
};

const lessOfValues = [
  api.LessOf.fried,
  api.LessOf.sugar,
  api.LessOf.salt,
  api.LessOf.santan,
];

String textureLabel(AppLocalizations l10n, api.TexturePreference value) =>
    switch (value) {
      api.TexturePreference.soft => l10n.prefTextureSoft,
      api.TexturePreference.crunchy => l10n.prefTextureCrispy,
      api.TexturePreference.soupy => l10n.prefTextureSoupy,
    };

const textureValues = [
  api.TexturePreference.soft,
  api.TexturePreference.crunchy,
  api.TexturePreference.soupy,
];

String portionLabel(AppLocalizations l10n, api.PortionSize size) =>
    switch (size) {
      api.PortionSize.small => l10n.portionSmall,
      api.PortionSize.normal => l10n.portionNormal,
      api.PortionSize.large => l10n.portionLarge,
    };

const portionSizes = [
  api.PortionSize.small,
  api.PortionSize.normal,
  api.PortionSize.large,
];

/// The app's language as the contract's `Language`.
api.Language apiLanguageOf(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'en'
    ? api.Language.en
    : api.Language.id;
