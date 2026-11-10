import type {
  DietSuitability,
  HalalValue,
  MappingConfirmer,
  NonHalalSource,
  StandardAllergen,
  Verification,
} from "./vocabulary.js";

// ---------------------------------------------------------------------------
// Reference data (shape of data/schema/ingredient.schema.json). Values are
// owned by the content team; the engine only reads them.
// ---------------------------------------------------------------------------

export interface ComponentData {
  readonly verification: Verification;
  /** Reference ingredient IDs this ingredient contains (SAF-03, SAF-06). */
  readonly ingredientIds: readonly string[];
}

export interface AllergenData {
  readonly verification: Verification;
  readonly contains: readonly StandardAllergen[];
  /** "Possibly contains", for example kecap that may contain wheat. */
  readonly mayContain: readonly StandardAllergen[];
}

export interface HalalData {
  readonly verification: Verification;
  readonly value: HalalValue;
  /** Required and non-empty when `value` is `not_halal`, empty otherwise. */
  readonly nonHalalSources: readonly NonHalalSource[];
}

export interface DietData {
  readonly verification: Verification;
  readonly vegetarian: DietSuitability;
  readonly vegan: DietSuitability;
}

/** Safety-relevant data that can differ between brands. */
export interface SafetyData {
  readonly components: ComponentData;
  readonly allergens: AllergenData;
  readonly halal: HalalData;
  readonly diet: DietData;
}

export interface BrandVariant extends SafetyData {
  readonly brandId: string;
  readonly brandName: string;
  /** SAF-07: only a verified variant replaces the generic data. */
  readonly verified: boolean;
}

export interface ReferenceIngredient extends SafetyData {
  readonly id: string;
  readonly displayName: { readonly id: string; readonly en: string };
  readonly localNames: readonly string[];
  readonly category: string;
  /** SAF-07: true when components, allergens or halal status vary by brand. */
  readonly brandVaries: boolean;
  readonly brandVariants: readonly BrandVariant[];
  readonly tkpiCode: string | null;
}

export interface ReferenceDataset {
  readonly schema: string;
  /** DAT-06 reference data version, recorded with every result. */
  readonly version: string;
  readonly ingredients: readonly ReferenceIngredient[];
}

// ---------------------------------------------------------------------------
// Hard rules (shape of data/schema/hard-rule.schema.json), PRF-03, PRF-08.
// ---------------------------------------------------------------------------

export type RuleMapping =
  | {
      readonly status: "mapped";
      readonly ingredientIds: readonly string[];
      readonly confirmedBy: MappingConfirmer;
    }
  | { readonly status: "proposed"; readonly ingredientIds: readonly string[] }
  | { readonly status: "unmapped" };

export type HardRule =
  | { readonly ruleId: string; readonly type: "allergy"; readonly allergen: StandardAllergen }
  | { readonly ruleId: string; readonly type: "halal" }
  | { readonly ruleId: string; readonly type: "vegetarian" }
  | { readonly ruleId: string; readonly type: "vegan" }
  | {
      readonly ruleId: string;
      readonly type: "medical_exclusion";
      readonly freeText: string | null;
      readonly mapping: RuleMapping;
    }
  | {
      readonly ruleId: string;
      readonly type: "free_text";
      readonly freeText: string;
      readonly mapping: RuleMapping;
    };

// ---------------------------------------------------------------------------
// Engine input and output.
// ---------------------------------------------------------------------------

export interface RecipeIngredientInput {
  /**
   * Resolved reference ingredient ID, or null when unresolved: a custom
   * ingredient (KIT-05), or an AI-named ingredient not yet mapped to the
   * reference data (REC-06, SAF-10). Null always fails closed (SAF-09).
   */
  readonly ingredientId: string | null;
  /** The name as written in the recipe, shown in reasons. */
  readonly rawName: string;
}

/** A brand the household recorded for an ingredient in Dapur Saya (SAF-07). */
export interface RecordedBrand {
  readonly ingredientId: string;
  readonly brandId: string;
}

/** One selected member (PRF-09, PRF-11). Pass only the members who are eating. */
export interface MemberRulesInput {
  readonly memberId: string;
  readonly hardRules: readonly HardRule[];
}

/**
 * Engine input. There is deliberately no override, acknowledgement or
 * "force safe" field of any kind (SAF-12), and no AI output (SAF-10).
 */
export interface CekAmanInput {
  readonly ingredients: readonly RecipeIngredientInput[];
  readonly recordedBrands: readonly RecordedBrand[];
  readonly members: readonly MemberRulesInput[];
  readonly reference: ReferenceDataset;
}

export type SafetyStatus = "safe" | "not_safe" | "check_label";

/** `contains` and `component` mean "Not safe"; the other kinds mean "Check the label". */
export type ReasonKind = "contains" | "component" | "unknown" | "brand_uncertain" | "unmapped_rule";

export type ReasonCode =
  // Not safe
  | "allergen_contains"
  | "halal_not_halal"
  | "diet_not_suitable"
  | "excluded_ingredient"
  // Check the label: missing or uncertain data
  | "no_ingredients"
  | "ingredient_unresolved"
  | "ingredient_not_in_reference"
  | "components_unverified"
  | "component_not_in_reference"
  | "component_cycle"
  | "allergens_unverified"
  | "allergen_may_contain"
  | "allergen_related"
  | "allergen_unrecognized"
  | "halal_uncertain"
  | "diet_uncertain"
  // Check the label: brand uncertainty (SAF-07)
  | "brand_not_recorded"
  | "brand_unverified"
  | "component_brand_varies"
  // Check the label: rule cannot be evaluated (PRF-08, SAF-09)
  | "rule_unmapped"
  | "rule_mapping_unconfirmed"
  | "rule_mapping_unknown_ingredient"
  | "rule_invalid";

export interface RuleRef {
  readonly ruleId: string;
  readonly type: string;
  readonly allergen: string | null;
}

export interface IngredientRef {
  /** Position in the input ingredient list. */
  readonly index: number;
  readonly ingredientId: string | null;
  readonly rawName: string;
}

export interface SafetyReason {
  readonly kind: ReasonKind;
  readonly code: ReasonCode;
  readonly rule: RuleRef;
  /** Null only for reasons about the rule itself or an empty recipe. */
  readonly ingredient: IngredientRef | null;
  /** Component IDs from the recipe ingredient down to the one concerned; empty for the ingredient itself. */
  readonly componentPath: readonly string[];
  /** Verified brand variant whose data was used, or null for generic data. */
  readonly brandId: string | null;
  /** Allergen tag, non-halal source, diet or excluded ingredient ID, when relevant. */
  readonly detail: string | null;
}

export interface MemberSafetyResult {
  readonly memberId: string;
  readonly status: SafetyStatus;
  readonly reasons: readonly SafetyReason[];
}

export interface CekAmanResult {
  /** One entry per selected member, in input order. Nobody else (PRF-11). */
  readonly perMember: readonly MemberSafetyResult[];
  readonly ruleSetVersion: string;
  readonly referenceVersion: string;
}
