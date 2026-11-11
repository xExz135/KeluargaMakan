"""Endpoint skeletons on the mock provider: shapes, AI-06 questions, ID mapping, guards.

TEST FIXTURE: not real safety or nutrition data. Ingredient IDs are fixture IDs.
"""

from __future__ import annotations

from typing import Any

import pytest

from app.providers.mock import MockMode, MockProvider
from tests.support import (
    AUTH,
    HOUSEHOLD_REF,
    adapt_body,
    harness,
    recognize_body,
    speech_headers,
    tweak_body,
)

# ---------- recognition ----------


def test_rec02_rec03_ai06_checklist_with_confidence_and_questions_for_low_confidence() -> None:
    h = harness()
    body = h.client.post("/recognize/ingredients", json=recognize_body(), headers=AUTH).json()
    assert body["confirmationRequired"] is True
    assert body["ruleCheckRequired"] is True
    assert {c["rawName"] for c in body["candidates"]} == {"bayam", "tempe"}
    assert all(c["confidence"] >= 0.6 for c in body["candidates"])
    (question,) = body["questions"]
    assert question["confidence"] < 0.6
    assert [o["rawName"] for o in question["options"]] == ["tahu", "tempe"]
    # The low-confidence item is asked, never listed as recognized.
    assert "tahu" not in {c["rawName"] for c in body["candidates"]}


def test_rec05_saved_ingredient_match_keeps_its_id() -> None:
    h = harness()
    body = h.client.post("/recognize/ingredients", json=recognize_body(), headers=AUTH).json()
    by_name = {c["rawName"]: c for c in body["candidates"]}
    assert by_name["bayam"]["ingredientId"] == "fixture_bayam"
    assert by_name["tempe"]["ingredientId"] is None


def test_ai06_ids_not_in_the_household_list_stay_unmapped() -> None:
    mock = MockProvider(
        responses={
            "recognize.ingredients": {
                "candidates": [
                    {
                        "rawName": "udang",
                        "ingredientId": "invented_id",
                        "confidence": 0.95,
                        "photoIndex": 0,
                    },
                    {
                        "rawName": "tahu",
                        "ingredientId": "invented_id_2",
                        "confidence": 0.3,
                        "photoIndex": 0,
                        "alternatives": [{"rawName": "x", "ingredientId": "bad"}],
                    },
                ]
            }
        }
    )
    h = harness(mock=mock)
    body = h.client.post("/recognize/ingredients", json=recognize_body(), headers=AUTH).json()
    assert body["candidates"][0]["ingredientId"] is None
    assert all(o["ingredientId"] is None for o in body["questions"][0]["options"])


def test_ai06_low_confidence_mode_returns_only_questions() -> None:
    h = harness(mock=MockProvider(mode=MockMode.LOW_CONFIDENCE))
    body = h.client.post("/recognize/ingredients", json=recognize_body(), headers=AUTH).json()
    assert body["candidates"] == []
    assert len(body["questions"]) == 3


def test_recognition_output_pointing_at_a_missing_photo_is_rejected() -> None:
    mock = MockProvider(
        responses={
            "recognize.ingredients": {
                "candidates": [{"rawName": "tempe", "confidence": 0.9, "photoIndex": 4}]
            }
        }
    )
    h = harness(mock=mock)
    response = h.client.post("/recognize/ingredients", json=recognize_body(), headers=AUTH)
    assert response.status_code == 502
    assert response.json()["fallback"] == "manual_entry"


def test_ai01_question_text_with_a_safety_claim_is_dropped() -> None:
    mock = MockProvider(
        responses={
            "recognize.ingredients": {
                "candidates": [
                    {
                        "rawName": "tahu",
                        "confidence": 0.3,
                        "photoIndex": 0,
                        "question": "Ini tahu yang halal?",
                    }
                ]
            }
        }
    )
    h = harness(mock=mock)
    body = h.client.post("/recognize/ingredients", json=recognize_body(), headers=AUTH).json()
    assert body["questions"][0]["text"] is None


# ---------- adaptation ----------


def test_lib06_lib07_ai02_adapted_recipe_is_labeled_and_based_on_the_library() -> None:
    h = harness()
    body = h.client.post("/adapt/recipe", json=adapt_body(), headers=AUTH).json()
    assert body["status"] == "ok"
    assert body["adapted"] is True
    assert body["generated"] is False
    assert body["ruleCheckRequired"] is True
    recipe = body["recipe"]
    assert recipe["basedOn"] == {"recipeId": "fixture_recipe_tumis", "version": "1"}
    assert recipe["servings"] == 4
    assert recipe["ingredients"][0]["quantity"] == 400
    assert recipe["ingredients"][0]["changed"] is True


def test_lib06_ids_outside_the_recipe_and_kitchen_become_raw_names() -> None:
    mock = MockProvider()
    h = harness(mock=mock)
    original = mock._adaptation

    def with_invented_id(prompt: Any) -> Any:
        output = dict(original(prompt))
        output["ingredients"] = [
            *output["ingredients"],  # type: ignore[misc]
            {"ingredientId": "invented_id", "rawName": "kecap", "quantity": 1, "unit": "sdm"},
            {"ingredientId": "fixture_tempe", "rawName": "tempe", "quantity": 100, "unit": "gram"},
        ]
        return output

    mock._adaptation = with_invented_id  # type: ignore[method-assign]
    recipe = h.client.post("/adapt/recipe", json=adapt_body(), headers=AUTH).json()["recipe"]
    by_name = {i["rawName"]: i["ingredientId"] for i in recipe["ingredients"]}
    assert by_name["kecap"] is None
    assert by_name["tempe"] == "fixture_tempe"
    assert by_name["bayam"] == "fixture_bayam"


def test_ai06_low_confidence_adaptation_asks_and_returns_no_recipe() -> None:
    h = harness(mock=MockProvider(mode=MockMode.LOW_CONFIDENCE))
    body = h.client.post("/adapt/recipe", json=adapt_body(), headers=AUTH).json()
    assert body["status"] == "needs_clarification"
    assert body["recipe"] is None
    assert body["questions"]


@pytest.mark.parametrize(
    "step",
    ["Masak ayam setengah matang agar empuk.", "Resep ini aman untuk alergi.", "Sudah teruji."],
)
def test_ai05_tnt09_unsafe_or_claiming_adaptation_is_rejected(step: str) -> None:
    mock = MockProvider()
    original = mock._adaptation

    def unsafe(prompt: Any) -> Any:
        output = dict(original(prompt))
        output["steps"] = [{"index": 1, "text": step}]
        return output

    mock._adaptation = unsafe  # type: ignore[method-assign]
    h = harness(mock=mock)
    response = h.client.post("/adapt/recipe", json=adapt_body(), headers=AUTH)
    assert response.status_code == 502
    assert response.json() == {
        "code": "ai_output_rejected",
        "feature": "adaptation",
        "fallback": "library_recipe",
        "retryable": False,
    }


# ---------- Taste & Tweak ----------


def test_tnt04_fixes_have_action_amount_and_timing() -> None:
    h = harness()
    body = h.client.post("/tweak", json=tweak_body(), headers=AUTH).json()
    assert body["status"] == "ok"
    assert body["ruleCheckRequired"] is True
    assert 1 <= len(body["fixes"]) <= 3
    for fix in body["fixes"]:
        assert fix["action"] and fix["timing"]
        if fix["ingredient"]:
            assert fix["amount"]["text"]


def test_tnt06_less_salt_prefers_acid_over_salt_for_bland() -> None:
    h = harness()
    plain = h.client.post("/tweak", json=tweak_body(), headers=AUTH).json()
    less_salt = h.client.post("/tweak", json=tweak_body(lessSalt=True), headers=AUTH).json()
    assert "salt" in {f["kind"] for f in plain["fixes"]}
    assert {f["kind"] for f in less_salt["fixes"]} == {"acid"}


@pytest.mark.parametrize(
    ("text", "status", "reason", "key"),
    [
        ("Apakah boleh untuk diabetes?", "referral", "medical", "ai.medicalReferral"),
        ("Obat apa yang cocok kalau sakit perut?", "referral", "medical", "ai.medicalReferral"),
        ("Boleh ayam setengah matang biar cepat?", "refused", "food_handling", "ai.foodHandling"),
        ("Sisa semalaman di suhu ruang masih bisa?", "refused", "food_handling", "ai.foodHandling"),
        (
            "Apakah ini aman untuk alergi udang?",
            "refused",
            "food_rule_question",
            "ai.foodRuleQuestion",
        ),
        ("Ini halal?", "refused", "food_rule_question", "ai.foodRuleQuestion"),
        ("Tolong buatkan puisi", "refused", "off_topic", "ai.offTopic"),
        ("Write me a poem about politics", "refused", "off_topic", "ai.offTopic"),
    ],
)
def test_ai04_ai05_ai13_guarded_questions_never_reach_the_provider(
    text: str, status: str, reason: str, key: str
) -> None:
    h = harness()
    body = h.client.post("/tweak", json=tweak_body(button=None, text=text), headers=AUTH).json()
    assert (body["status"], body["reason"], body["messageKey"]) == (status, reason, key)
    assert body["fixes"] == []
    assert body["promptId"] == "guard.keywords"
    assert not h.mock.calls


def test_tnt02_cooking_text_goes_to_the_provider() -> None:
    h = harness()
    text = "Kuahnya terlalu encer, bagaimana?"
    body = h.client.post("/tweak", json=tweak_body(button=None, text=text), headers=AUTH).json()
    assert body["status"] == "ok"
    assert len(h.mock.calls) == 1


def test_ai01_ai05_output_with_only_claiming_fixes_falls_back_to_curated() -> None:
    mock = MockProvider(
        responses={
            "tweak.advice": {
                "confidence": 0.9,
                "fixes": [
                    {
                        "action": "Tambahkan susu, aman untuk semua.",
                        "kind": "fat",
                        "timing": "sekarang",
                    },
                    {
                        "action": "Biarkan ayam setengah matang.",
                        "kind": "technique",
                        "timing": "sekarang",
                    },
                    {
                        "action": "Baik untuk diabetes, tambah kayu manis.",
                        "kind": "aromatic",
                        "timing": "sekarang",
                    },
                ],
            }
        }
    )
    h = harness(mock=mock)
    response = h.client.post("/tweak", json=tweak_body(), headers=AUTH)
    # Every fix breaks a guard, so nothing usable is left: the API shows curated fixes.
    assert response.status_code == 502
    assert response.json()["fallback"] == "curated_fixes"


def test_ai01_one_clean_fix_survives_the_output_guard() -> None:
    mock = MockProvider(
        responses={
            "tweak.advice": {
                "confidence": 0.9,
                "fixes": [
                    {
                        "action": "Tambahkan keju, bebas gluten.",
                        "kind": "fat",
                        "timing": "sekarang",
                    },
                    {
                        "action": "Tambahkan 1 sdt air jeruk nipis.",
                        "kind": "acid",
                        "timing": "di akhir",
                    },
                ],
            }
        }
    )
    h = harness(mock=mock)
    body = h.client.post("/tweak", json=tweak_body(), headers=AUTH).json()
    assert [f["kind"] for f in body["fixes"]] == ["acid"]


def test_ai06_low_confidence_tweak_asks_a_question() -> None:
    h = harness(mock=MockProvider(mode=MockMode.LOW_CONFIDENCE))
    body = h.client.post("/tweak", json=tweak_body(), headers=AUTH).json()
    assert body["status"] == "needs_clarification"
    assert body["fixes"] == []
    assert body["question"]


def test_tnt04_more_than_three_fixes_is_rejected() -> None:
    fix = {"action": "Aduk rata.", "kind": "technique", "timing": "sekarang"}
    h = harness(
        mock=MockProvider(responses={"tweak.advice": {"confidence": 0.9, "fixes": [fix] * 4}})
    )
    assert h.client.post("/tweak", json=tweak_body(), headers=AUTH).status_code == 502


def test_tnt04_fix_adding_an_ingredient_without_amount_is_rejected() -> None:
    fix = {
        "action": "Tambahkan garam.",
        "kind": "salt",
        "timing": "sekarang",
        "ingredient": {"rawName": "garam"},
    }
    h = harness(mock=MockProvider(responses={"tweak.advice": {"confidence": 0.9, "fixes": [fix]}}))
    assert h.client.post("/tweak", json=tweak_body(), headers=AUTH).status_code == 502


def test_tweak_problem_needs_a_button_or_text() -> None:
    h = harness()
    response = h.client.post("/tweak", json=tweak_body(button=None), headers=AUTH)
    assert response.status_code == 422


# ---------- speech ----------


def test_int08_transcribe_returns_transcript_with_trace_fields() -> None:
    h = harness()
    response = h.client.post("/speech/transcribe", content=b"\x00" * 3200, headers=speech_headers())
    body = response.json()
    assert response.status_code == 200
    assert body["status"] == "ok"
    assert body["transcript"].endswith("lanjut")
    assert body["promptId"] == "speech.transcribe"
    assert body["modelId"] == "mock-stt-1"


def test_voi05_ai06_low_confidence_transcript_is_flagged() -> None:
    h = harness(mock=MockProvider(mode=MockMode.LOW_CONFIDENCE))
    response = h.client.post("/speech/transcribe", content=b"\x00" * 64, headers=speech_headers())
    assert response.json()["status"] == "needs_clarification"


def test_int08_transcribe_refuses_unknown_media_empty_and_oversized_audio() -> None:
    h = harness(MAX_AUDIO_BYTES="100")
    post = h.client.post
    assert (
        post(
            "/speech/transcribe", content=b"x", headers=speech_headers(mime="text/plain")
        ).status_code
        == 415
    )
    assert post("/speech/transcribe", content=b"", headers=speech_headers()).status_code == 422
    assert (
        post("/speech/transcribe", content=b"\x00" * 101, headers=speech_headers()).status_code
        == 413
    )
    assert not h.mock.calls


def test_int08_transcribe_needs_a_household_pseudonym_header() -> None:
    h = harness()
    headers = {k: v for k, v in speech_headers().items() if k != "X-Household-Ref"}
    assert h.client.post("/speech/transcribe", content=b"\x00", headers=headers).status_code == 422


def test_int08_synthesize_returns_audio_when_a_slot_is_configured() -> None:
    h = harness()
    body = h.client.post(
        "/speech/synthesize",
        json={
            "householdRef": HOUSEHOLD_REF,
            "dataUse": {"aiImprovementOptIn": True},
            "text": "Langkah 1: tumis bumbu.",
        },
        headers=AUTH,
    ).json()
    assert body["mimeType"] == "audio/wav"
    assert body["audioBase64"]
    assert body["confidence"] is None


def test_int08_synthesize_without_a_slot_points_to_on_device_speech() -> None:
    h = harness(TEXT_TO_SPEECH_PROVIDER="")
    response = h.client.post(
        "/speech/synthesize",
        json={
            "householdRef": HOUSEHOLD_REF,
            "dataUse": {"aiImprovementOptIn": True},
            "text": "Langkah 1.",
        },
        headers=AUTH,
    )
    assert response.status_code == 503
    assert response.json()["fallback"] == "device_text_to_speech"


def test_tnt05_fix_ingredient_ids_outside_recipe_and_kitchen_become_raw_names() -> None:
    fixes = [
        {
            "action": "Tambahkan 1 sdt kecap.",
            "kind": "other",
            "timing": "sekarang",
            "ingredient": {"ingredientId": "invented_id", "rawName": "kecap"},
            "amount": {"quantity": 1, "unit": "sdt", "text": "1 sdt"},
        },
        {
            "action": "Tambahkan bayam.",
            "kind": "other",
            "timing": "sekarang",
            "ingredient": {"ingredientId": "fixture_bayam", "rawName": "bayam"},
            "amount": {"quantity": 50, "unit": "gram", "text": "50 gram"},
        },
    ]
    h = harness(mock=MockProvider(responses={"tweak.advice": {"confidence": 0.9, "fixes": fixes}}))
    body = h.client.post("/tweak", json=tweak_body(), headers=AUTH).json()
    ids = [f["ingredient"]["ingredientId"] for f in body["fixes"]]
    assert ids == [None, "fixture_bayam"]
