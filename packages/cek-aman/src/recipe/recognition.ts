import { isObject, own } from "../normalize.js";
import type { RecipeIngredientInput } from "../types.js";

/**
 * One item as photo recognition returns it, before the user confirms it
 * (REC-02, REC-04): the shape of contract 0.3 `RecognizedItem`, so a value of
 * the generated contract type is accepted as it is. It is never evidence of
 * allergen, halal or any other safety status (REC-06, SAF-10): Cek Aman relies
 * on reference ingredient data only.
 */
export interface RecognitionOutput {
  /** The checklist line ID. Never read. */
  readonly id?: string;
  /** The name as read from the photo; kept only as the name shown. */
  readonly label: string;
  /**
   * The reference ingredient the API matched by name (AI-06), not yet
   * confirmed by the user. Never read: the item stays unresolved.
   */
  readonly ingredientId?: string | null;
  /** Never read. */
  readonly displayName?: unknown;
  /** Contract 0.3: high, medium or low. Never read. */
  readonly confidence?: unknown;
  /** Likely reference ingredients for a low-confidence item (REC-03). Never read. */
  readonly options?: unknown;
  /** The saved kitchen item this may match (REC-05). Never read. */
  readonly kitchenItemId?: string | null;
  /** The model that produced the item, when the AI service reports one. Never read. */
  readonly modelId?: string;
}

/** An engine ingredient that is unresolved by construction, so it fails closed (SAF-09). */
export interface UnresolvedIngredientInput extends RecipeIngredientInput {
  readonly ingredientId: null;
}

/**
 * REC-06: the only way recognition output enters a Cek Aman evaluation. The
 * item stays unresolved (`ingredientId: null`) whatever the API's name match,
 * options, confidence or model say, so every member with a hard rule gets
 * "Check the label", never "Safe". The label is kept only as the name shown
 * in the reason.
 *
 * An item becomes a resolved ingredient only once the user confirms it
 * (REC-04) and the API stores it as a kitchen item with a reference ID; from
 * then on it is a kitchen item, not recognition output. The engine cannot tell
 * the two apart by their `ingredientId`, so the API must never pass a
 * recognized item to Cek Aman any other way.
 */
export function ingredientFromRecognition(item: RecognitionOutput): UnresolvedIngredientInput {
  const raw: unknown = item;
  const label = isObject(raw) ? own(raw, "label") : undefined;
  return { ingredientId: null, rawName: typeof label === "string" ? label : "" };
}
