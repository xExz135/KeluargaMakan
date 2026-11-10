// TEST FIXTURE: not real safety or nutrition data
//
// Fictional household members and hard rules for Cek Aman tests only. No real
// people or health data. Never load this file outside tests.

import type { MemberRulesInput } from "../../../packages/cek-aman/src/types.js";

export const fixtureMembers = {
  /** No hard rules. */
  ibu: { memberId: "fx-member-ibu", hardRules: [] },
  kakak: {
    memberId: "fx-member-kakak",
    hardRules: [{ ruleId: "fx-rule-kakak-shrimp", type: "allergy", allergen: "shrimp" }],
  },
  adik: {
    memberId: "fx-member-adik",
    hardRules: [{ ruleId: "fx-rule-adik-shellfish", type: "allergy", allergen: "shellfish" }],
  },
  ayah: {
    memberId: "fx-member-ayah",
    hardRules: [{ ruleId: "fx-rule-ayah-halal", type: "halal" }],
  },
  kakek: {
    memberId: "fx-member-kakek",
    hardRules: [{ ruleId: "fx-rule-kakek-soy", type: "allergy", allergen: "soy" }],
  },
  bibi: {
    memberId: "fx-member-bibi",
    hardRules: [{ ruleId: "fx-rule-bibi-wheat", type: "allergy", allergen: "wheat" }],
  },
  paman: {
    memberId: "fx-member-paman",
    hardRules: [{ ruleId: "fx-rule-paman-fish", type: "allergy", allergen: "fish" }],
  },
  sepupu: {
    memberId: "fx-member-sepupu",
    hardRules: [{ ruleId: "fx-rule-sepupu-milk", type: "allergy", allergen: "milk" }],
  },
  tante: {
    memberId: "fx-member-tante",
    hardRules: [{ ruleId: "fx-rule-tante-vegetarian", type: "vegetarian" }],
  },
  keponakan: {
    memberId: "fx-member-keponakan",
    hardRules: [{ ruleId: "fx-rule-keponakan-vegan", type: "vegan" }],
  },
  nenek: {
    memberId: "fx-member-nenek",
    hardRules: [
      {
        ruleId: "fx-rule-nenek-durian",
        type: "medical_exclusion",
        freeText: "fixture: avoid durian",
        mapping: { status: "mapped", ingredientIds: ["fx_durian"], confirmedBy: "manager" },
      },
    ],
  },
  om: {
    memberId: "fx-member-om",
    hardRules: [
      {
        ruleId: "fx-rule-om-freetext",
        type: "free_text",
        freeText: "fixture: allergic to a fruit not on the list",
        mapping: { status: "unmapped" },
      },
    ],
  },
  kakekBuyut: {
    memberId: "fx-member-kakek-buyut",
    hardRules: [
      {
        ruleId: "fx-rule-buyut-proposed",
        type: "free_text",
        freeText: "fixture: no durian",
        // Proposed by the system or an AI, never confirmed: must not be trusted.
        mapping: { status: "proposed", ingredientIds: ["fx_durian"] },
      },
    ],
  },
} as const satisfies Record<string, MemberRulesInput>;

export type FixtureMemberKey = keyof typeof fixtureMembers;
