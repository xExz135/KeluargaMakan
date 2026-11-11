// TEST FIXTURE: not real safety or nutrition data
//
// Fictional reference ingredients for Cek Aman tests only. Real ingredient
// names are used for readability, but every value here is invented to exercise
// the engine and is NOT verified allergen, component, halal or brand data.
// IDs carry the `fx_` prefix so they can never match real reference data.
// Never load this file outside tests (enforced by `pnpm check:fixtures`).

import type {
  AllergenData,
  BrandVariant,
  ComponentData,
  DietData,
  HalalData,
  ReferenceDataset,
  ReferenceIngredient,
} from "../../../packages/cek-aman/src/types.js";

export const FIXTURE_REFERENCE_VERSION = "TEST-FIXTURE-2026.11.0";

const noComponents: ComponentData = { verification: "verified", ingredientIds: [] };
const noAllergens: AllergenData = { verification: "verified", contains: [], mayContain: [] };
const halal: HalalData = { verification: "verified", value: "halal", nonHalalSources: [] };
const plantBased: DietData = {
  verification: "verified",
  vegetarian: "suitable",
  vegan: "suitable",
};
const animal: DietData = {
  verification: "verified",
  vegetarian: "not_suitable",
  vegan: "not_suitable",
};

type Overrides = Partial<Omit<ReferenceIngredient, "id" | "displayName" | "category">>;

function ingredient(
  id: string,
  nameId: string,
  nameEn: string,
  category: string,
  overrides: Overrides = {},
): ReferenceIngredient {
  return {
    id,
    displayName: { id: nameId, en: nameEn },
    localNames: [],
    category,
    components: noComponents,
    allergens: noAllergens,
    halal,
    diet: plantBased,
    brandVaries: false,
    brandVariants: [],
    tkpiCode: null,
    ...overrides,
  };
}

const contains = (...tags: AllergenData["contains"]): AllergenData => ({
  verification: "verified",
  contains: tags,
  mayContain: [],
});
const componentsOf = (...ids: string[]): ComponentData => ({
  verification: "verified",
  ingredientIds: ids,
});
const notHalal = (...sources: HalalData["nonHalalSources"]): HalalData => ({
  verification: "verified",
  value: "not_halal",
  nonHalalSources: sources,
});
const halalUncertain: HalalData = {
  verification: "verified",
  value: "uncertain",
  nonHalalSources: [],
};

function variant(
  brandId: string,
  brandName: string,
  verified: boolean,
  data: Pick<BrandVariant, "allergens"> & Partial<BrandVariant>,
): BrandVariant {
  return {
    brandId,
    brandName,
    verified,
    components: noComponents,
    halal,
    diet: plantBased,
    ...data,
  };
}

export const fixtureIngredients: readonly ReferenceIngredient[] = [
  // Plain ingredients
  ingredient("fx_nasi", "Nasi", "Cooked rice", "grain"),
  ingredient("fx_bawang_putih", "Bawang putih", "Garlic", "vegetable"),
  ingredient("fx_cabai", "Cabai", "Chili", "vegetable"),
  ingredient("fx_garam", "Garam", "Salt", "seasoning"),
  ingredient("fx_santan", "Santan", "Coconut milk", "dairy_alternative"),
  ingredient("fx_durian", "Durian", "Durian", "fruit"),
  ingredient("fx_msg", "Vetsin", "MSG", "seasoning"),
  ingredient("fx_tahu", "Tahu", "Tofu", "protein", { allergens: contains("soy") }),
  ingredient("fx_kacang_tanah", "Kacang tanah", "Peanut", "nut", {
    allergens: contains("peanut"),
  }),
  ingredient("fx_tepung_terigu", "Tepung terigu", "Wheat flour", "grain", {
    allergens: contains("wheat"),
  }),
  ingredient("fx_telur", "Telur ayam", "Chicken egg", "protein", {
    allergens: contains("egg"),
    diet: { verification: "verified", vegetarian: "suitable", vegan: "not_suitable" },
  }),
  ingredient("fx_susu", "Susu sapi", "Cow's milk", "dairy", {
    allergens: contains("milk"),
    diet: { verification: "verified", vegetarian: "suitable", vegan: "not_suitable" },
  }),
  ingredient("fx_ayam", "Daging ayam", "Chicken", "protein", { diet: animal }),
  ingredient("fx_babi", "Daging babi", "Pork", "protein", {
    halal: notHalal("pork"),
    diet: animal,
  }),
  ingredient("fx_udang", "Udang", "Shrimp", "seafood", {
    allergens: contains("shrimp"),
    diet: animal,
  }),
  ingredient("fx_ikan", "Ikan", "Fish", "seafood", { allergens: contains("fish"), diet: animal }),
  ingredient("fx_alkohol", "Alkohol", "Alcohol", "additive", { halal: notHalal("alcohol") }),
  // SAF-08 non-halal animal source (fixture value only).
  ingredient("fx_daging_kodok", "Daging kodok", "Frog meat", "protein", {
    halal: notHalal("non_halal_animal"),
    diet: animal,
  }),

  // SAF-06 hidden components (fixture values only)
  ingredient("fx_terasi", "Terasi", "Shrimp paste", "condiment", {
    localNames: ["belacan"],
    components: componentsOf("fx_udang", "fx_garam"),
    allergens: contains("shrimp"),
    diet: animal,
  }),
  // Petis is tagged through its component only, to exercise component detection.
  ingredient("fx_petis", "Petis udang", "Shrimp paste (petis)", "condiment", {
    components: componentsOf("fx_udang"),
    diet: animal,
  }),
  ingredient("fx_sambal_terasi", "Sambal terasi", "Chili shrimp paste sambal", "condiment", {
    components: componentsOf("fx_cabai", "fx_terasi", "fx_garam"),
    diet: animal,
  }),
  ingredient("fx_kerupuk_udang", "Kerupuk udang", "Prawn crackers", "snack", {
    components: componentsOf("fx_udang", "fx_tepung_terigu"),
    diet: animal,
  }),
  ingredient("fx_saus_tiram", "Saus tiram", "Oyster sauce", "condiment", {
    allergens: contains("shellfish"),
    halal: halalUncertain,
    diet: animal,
    brandVaries: true,
    brandVariants: [
      variant("fx_brand_tiram_a", "Fixture Tiram A", true, {
        allergens: { verification: "verified", contains: ["shellfish", "wheat"], mayContain: [] },
        diet: animal,
      }),
      variant("fx_brand_tiram_b", "Fixture Tiram B", false, {
        allergens: contains("shellfish"),
        diet: animal,
      }),
    ],
  }),
  ingredient("fx_kecap_ikan", "Kecap ikan", "Fish sauce", "condiment", {
    components: componentsOf("fx_ikan", "fx_garam"),
    allergens: contains("fish"),
    diet: animal,
  }),
  ingredient("fx_angciu", "Angciu", "Shaoxing rice wine", "condiment", {
    components: componentsOf("fx_alkohol"),
    halal: notHalal("alcohol"),
  }),
  // Mirin's own status is uncertain; its alcohol component makes it fail.
  ingredient("fx_mirin", "Mirin", "Mirin", "condiment", {
    components: componentsOf("fx_alkohol"),
    halal: halalUncertain,
  }),
  ingredient("fx_kecap_manis", "Kecap manis", "Sweet soy sauce", "condiment", {
    allergens: { verification: "verified", contains: ["soy"], mayContain: ["wheat"] },
    brandVaries: true,
    brandVariants: [
      variant("fx_brand_kecap_a", "Fixture Kecap A", true, { allergens: contains("soy") }),
      variant("fx_brand_kecap_b", "Fixture Kecap B", false, { allergens: contains("soy") }),
    ],
  }),
  ingredient("fx_kecap_asin", "Kecap asin", "Soy sauce", "condiment", {
    allergens: contains("soy", "wheat"),
    brandVaries: true,
  }),
  ingredient("fx_kaldu_bubuk", "Kaldu bubuk", "Bouillon powder", "seasoning", {
    components: { verification: "unverified", ingredientIds: ["fx_msg"] },
    allergens: { verification: "unverified", contains: [], mayContain: ["wheat", "milk"] },
    halal: { verification: "unverified", value: "uncertain", nonHalalSources: [] },
    diet: { verification: "unverified", vegetarian: "uncertain", vegan: "uncertain" },
    brandVaries: true,
  }),
  ingredient("fx_gelatin", "Gelatin", "Gelatin", "additive", {
    halal: halalUncertain,
    diet: animal,
    brandVaries: true,
  }),
  // Component data not yet verified by the content team.
  ingredient("fx_bumbu_instan", "Bumbu instan", "Instant spice mix", "seasoning", {
    components: { verification: "unverified", ingredientIds: [] },
  }),
];

export const fixtureReference: ReferenceDataset = {
  schema: "keluargamakan.reference.ingredients/1",
  version: FIXTURE_REFERENCE_VERSION,
  ingredients: fixtureIngredients,
};
