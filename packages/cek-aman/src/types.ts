import type {
  DietSuitability,
  HalalValue,
  MappingConfirmer,
  NonHalalSource,
  REASON_CODES,
  REASON_KINDS,
  SAFETY_STATUSES,
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

/**
 * REC-06, SAF-10: photo recognition output (contract 0.3 `RecognizedItem`) has
 * no place in any engine input. Its `label`, `confidence` and `options` (and
 * an AI service's `modelId`) can never be set here, so spreading a recognized
 * item into an input fails to compile; convert it with
 * `ingredientFromRecognition`, which leaves it unresolved.
 *
 * At run time the engine ignores those fields, but it does read
 * `ingredientId`, and a recognized item carries the API's unconfirmed name
 * match there. The engine cannot tell it from a confirmed one, so this type
 * and the converter are the guard, together with REC-04 in the API (an
 * unconfirmed result never reaches Cek Aman).
 */
export interface RecognitionFieldsAbsent {
  readonly label?: never;
  readonly confidence?: never;
  readonly options?: never;
  readonly modelId?: never;
}

export interface RecipeIngredientInput extends RecognitionFieldsAbsent {
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

/** SAF-04 result per member; the values are `SAFETY_STATUSES`. */
export type SafetyStatus = (typeof SAFETY_STATUSES)[number];

/** `contains` and `component` mean "Not safe"; the other kinds mean "Check the label". */
export type ReasonKind = (typeof REASON_KINDS)[number];

/** Why a member got "Not safe" or "Check the label"; the values are `REASON_CODES`. */
export type ReasonCode = (typeof REASON_CODES)[number];

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
