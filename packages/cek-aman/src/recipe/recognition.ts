import { isObject, own } from "../normalize.js";
import type { RecipeIngredientInput } from "../types.js";

/**
 * One item as photo recognition returns it (REC-02), before the user confirms
 * it (REC-04). It is never evidence of allergen, halal or any other safety
 * status (REC-06, SAF-10): Cek Aman relies on reference ingredient data only.
 */
export interface RecognitionOutput {
  /** The name as read from the photo. */
  readonly label: string;
  /** Whatever the recognizer reports (contract 0.3: high, medium, low). Never read. */
  readonly confidence: unknown;
  /** The model that produced the item. Never read. */
  readonly modelId: string;
  /** A reference ID the recognizer or a name match proposed. Never read. */
  readonly proposedIngredientId?: string | null;
}

/** An engine ingredient that is unresolved by construction, so it fails closed (SAF-09). */
export interface UnresolvedIngredientInput extends RecipeIngredientInput {
  readonly ingredientId: null;
}

/**
 * REC-06: the only way recognition output enters a Cek Aman evaluation. The
 * item stays unresolved (`ingredientId: null`), so every member with a hard
 * rule gets "Check the label", never "Safe". The label is kept only as the
 * name shown in the reason; confidence, model ID and any proposed reference
 * ID are dropped, so none of them can change an allergen or halal result.
 *
 * An item becomes a resolved ingredient only once the user confirms it
 * (REC-04) and the API maps it to a reference ID itself (AI-06); from then on
 * it is a kitchen item, not recognition output.
 */
export function ingredientFromRecognition(item: RecognitionOutput): UnresolvedIngredientInput {
  const raw: unknown = item;
  const label = isObject(raw) ? own(raw, "label") : undefined;
  return { ingredientId: null, rawName: typeof label === "string" ? label : "" };
}
