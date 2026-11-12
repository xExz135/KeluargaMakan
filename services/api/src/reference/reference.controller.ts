import { RULE_SET_VERSION, STANDARD_ALLERGENS } from "@keluargamakan/cek-aman";
import type { Schemas } from "@keluargamakan/contracts";
import { Controller, Get } from "@nestjs/common";

import { Requires } from "../authz/access.js";

/**
 * PRF-04: the standard allergen list, straight from the Cek Aman rule-set
 * vocabulary (T-012), in its display order. The API adds no values of its
 * own; a change to the list is a rule-set change in packages/cek-aman.
 */
@Controller("v1/reference")
export class ReferenceController {
  @Get("allergens")
  @Requires("reference:read")
  allergens(): Schemas["StandardAllergenList"] {
    return { ruleSetVersion: RULE_SET_VERSION, items: [...STANDARD_ALLERGENS] };
  }
}
