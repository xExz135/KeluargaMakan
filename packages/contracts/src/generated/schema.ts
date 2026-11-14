// GENERATED FILE: do not edit. Source: packages/contracts/openapi.yaml.
// Regenerate with `pnpm --filter @keluargamakan/contracts run generate`.
export interface paths {
    "/v1/auth/code/request": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Send a sign-in code to a phone number or email
         * @description Sends a one-time verification code (ACC-01). The response is the same whether or not an account exists for the destination, so it cannot be used to discover accounts. Code length, expiry and the resend wait come from configuration. Requests are rate-limited per client address, per destination (hourly and daily), and while the destination has reached its limit of wrong codes; a limited request returns 429 with `Retry-After`.
         */
        post: operations["requestSignInCode"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/auth/code/verify": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Verify a sign-in code and start a session
         * @description Verifies the code for a challenge (ACC-01). On first sign-in a manager account is created with no household (`account.householdId` is null); the client then creates the household. On a later sign-in, including on a new device, the existing household is returned unchanged (ACC-13). Each code works once. Wrong codes count towards an attempt limit from configuration, and wrong codes across all of a destination's codes are capped per day (429 with `Retry-After`). Verification is also rate-limited per client address. A 503 leaves the code and its attempt count unchanged.
         */
        post: operations["verifySignInCode"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/auth/google": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Exchange a Google ID token for a session
         * @description Signs in with a Google ID token obtained on Android through Credential Manager (ACC-02). The server verifies the token with Google. When Google sign-in is unavailable the server returns 503 `sign_in_method_unavailable` and the client offers phone or email sign-in instead (INT-13). Apple sign-in is not part of this API.
         */
        post: operations["signInWithGoogle"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/auth/refresh": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Exchange a refresh token for new tokens
         * @description Rotates the refresh token. Each refresh token works once. If the response to a refresh is lost, the client may repeat the refresh with the same token within a grace window from configuration: it gets a new pair, and the pair from the lost response stops working. Reusing a token after the grace window, after the pair it was exchanged for has been used, or reusing a token that was replaced that way, revokes the whole session and returns 401 `refresh_token_invalid`. A 429 or 503 (for example `service_unavailable` after a concurrent change) leaves the session and the token unchanged; retry later.
         */
        post: operations["refreshSession"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/auth/sign-out": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Sign out on this device
         * @description Revokes the current session (its access and refresh tokens). Household data is kept on the server, so the user can sign in again on any device (ACC-13). The client clears its local session afterwards. Signing out an already revoked session returns 401, which the client treats as signed out.
         */
        post: operations["signOut"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/account": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Get the signed-in account */
        get: operations["getAccount"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/household": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get the household
         * @description Returns 409 `household_required` when the account has no household yet.
         */
        get: operations["getHousehold"];
        put?: never;
        /**
         * Create the household for the signed-in account
         * @description Creates the household with the signed-in account as its only manager, and the manager's own profile (ACC-03, ACC-04). An account has at most one household; a second call returns 409 `household_exists`.
         */
        post: operations["createHousehold"];
        delete?: never;
        options?: never;
        head?: never;
        /**
         * Update household details
         * @description Only the fields present are changed.
         */
        patch: operations["updateHousehold"];
        trace?: never;
    };
    "/v1/household/profiles": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * List the household's profiles
         * @description Returns every profile with its hard rules, preferences, likes and portions. The manager's own profile comes first. `maxProfiles` is the configured limit (PRF-02, at least 12, target). If any member's rules cannot be read or decrypted the whole request fails with 503 `rules_unavailable`; it never returns that member with an empty rule list (QUESTIONS #39).
         */
        get: operations["listProfiles"];
        put?: never;
        /**
         * Add a family member profile
         * @description Adds a member (PRF-01). Infant, child and teen age groups are flagged as children (PRF-18) and need the manager's confirmation as parent or guardian, which is recorded as a consent record (SET-10); without it the server returns 409 `guardian_confirmation_required`. Health data stays off for every new profile, children included, until a health-data consent is recorded (SET-10, ACC-08). Returns 409 `profile_limit_reached` at the configured limit (PRF-02).
         */
        post: operations["createProfile"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/household/profiles/{profileId}": {
        parameters: {
            query?: never;
            header?: never;
            path: {
                profileId: components["parameters"]["ProfileId"];
            };
            cookie?: never;
        };
        /**
         * Get one profile
         * @description Fails with 503 `rules_unavailable` when the member's rules cannot be read (QUESTIONS
         */
        get: operations["getProfile"];
        put?: never;
        post?: never;
        /**
         * Delete a profile and all of its data
         * @description Removes the member from suggestions, safety results and plans at once and deletes the profile's data (PRF-01, SET-07). The manager's own profile cannot be deleted here (409 `manager_profile_not_deletable`); the manager deletes the whole account instead.
         */
        delete: operations["deleteProfile"];
        options?: never;
        head?: never;
        /**
         * Edit a profile
         * @description Only the fields present are changed. Setting `portionSize` or `ricePortion` to null returns it to the age-group default from configuration (PRF-07). Changing an adult profile to an infant, child or teen age group needs `guardianConfirmation` (SET-10). The child flag follows the age group and cannot be set directly (PRF-18). The manager's own profile cannot take a child age group (409 `manager_profile_must_be_adult`, QUESTIONS #46). When a change moves the member between adult and child, a health-data consent given on the other text version no longer allows new health data: the stored rules stay and are still checked by Cek Aman, and `rules.consent.renewalRequired` is true until a new decision is recorded on the matching text (QUESTIONS #62).
         */
        patch: operations["updateProfile"];
        trace?: never;
    };
    "/v1/household/profiles/{profileId}/preferences": {
        parameters: {
            query?: never;
            header?: never;
            path: {
                profileId: components["parameters"]["ProfileId"];
            };
            cookie?: never;
        };
        get?: never;
        /**
         * Replace a profile's soft preferences
         * @description Soft preferences may be relaxed when selected members conflict (PRF-05, PRF-12). They are not hard rules and are never health data. The whole object is replaced, so an offline edit replayed later is safe to send again.
         */
        put: operations["replaceSoftPreferences"];
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/household/profiles/{profileId}/likes-dislikes": {
        parameters: {
            query?: never;
            header?: never;
            path: {
                profileId: components["parameters"]["ProfileId"];
            };
            cookie?: never;
        };
        get?: never;
        /**
         * Replace a profile's likes and dislikes
         * @description Likes and dislikes are ingredients or dishes (PRF-06). A dislike is not an allergy and is never treated as a hard rule. The whole object is replaced.
         */
        put: operations["replaceLikesDislikes"];
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/household/profiles/{profileId}/hard-rules": {
        parameters: {
            query?: never;
            header?: never;
            path: {
                profileId: components["parameters"]["ProfileId"];
            };
            cookie?: never;
        };
        /**
         * List a profile's hard rules and consent state
         * @description Returns the member's hard rules and the consent state that decides whether rules can be stored. With no current consent there are no rules, and clients show "rules not saved" for the member, never "Safe" (DECISIONS 2026-11-10). If the rules cannot be read or decrypted the server returns 503 `rules_unavailable`, never an empty list (QUESTIONS #39).
         */
        get: operations["listHardRules"];
        put?: never;
        /**
         * Add a hard rule
         * @description Adds an allergy from the standard list, halal, vegetarian, vegan, a medical exclusion or a free-text rule (PRF-03, PRF-04). Needs a current health-data consent for the member, else 409 `consent_required` (ACC-08), also while `consent.renewalRequired` is true; for a child the guardian confirmation must also be on record (SET-10). Free-text and medical-exclusion rules are saved as unmapped unless the manager picked matching ingredients (`mappedIngredientIds`). An unmapped rule makes Cek Aman return "Check the label" for related recipes, never "Safe" (PRF-08, SAF-09). Online only: the server re-evaluates affected safety results.
         */
        post: operations["createHardRule"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/household/profiles/{profileId}/hard-rules/{ruleId}": {
        parameters: {
            query?: never;
            header?: never;
            path: {
                profileId: components["parameters"]["ProfileId"];
                ruleId: components["parameters"]["RuleId"];
            };
            cookie?: never;
        };
        get?: never;
        put?: never;
        post?: never;
        /**
         * Remove a hard rule
         * @description The manager removes a rule from their family's data. This is an edit of the profile, not an override of a safety result: there is no way to override a "Not safe" result while a rule is active (SAF-12).
         */
        delete: operations["deleteHardRule"];
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/household/profiles/{profileId}/hard-rules/{ruleId}/mapping": {
        parameters: {
            query?: never;
            header?: never;
            path: {
                profileId: components["parameters"]["ProfileId"];
                ruleId: components["parameters"]["RuleId"];
            };
            cookie?: never;
        };
        get?: never;
        /**
         * Confirm which ingredients a free-text rule means
         * @description The manager confirms a mapping, either accepting a content-team proposal or choosing ingredients from the catalog (PRF-08). The rule becomes `mapped` with `confirmedBy: manager`, and affected safety results are re-evaluated. Only `free_text` and `medical_exclusion` rules have a mapping; other types return 409 `mapping_not_applicable`.
         */
        put: operations["confirmHardRuleMapping"];
        post?: never;
        /**
         * Reject or clear a free-text rule mapping
         * @description "Bukan ini": the rule returns to `unmapped` and goes back to the content team's anonymized queue (no names). Until it is mapped again, related recipes get "Check the label" (PRF-08, SAF-09). Other rule types return 409 `mapping_not_applicable`.
         */
        delete: operations["rejectHardRuleMapping"];
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/consent-texts/{purpose}": {
        parameters: {
            query: {
                language: components["schemas"]["Language"];
                /** @description For `health_data`: `child` for an infant, child or teen profile, `adult` otherwise (default). Ignored for `guardian_confirmation`. */
                audience?: components["schemas"]["ConsentAudience"];
            };
            header?: never;
            path: {
                purpose: components["schemas"]["ConsentPurpose"];
            };
            cookie?: never;
        };
        /**
         * Get the current consent text for a purpose
         * @description Returns the current text and its version, which the client sends back when recording a decision (SET-03). Texts are served from content, not built into the app, so legal changes need no release. `isDraft` stays true until legal approval. The health-data text has an adult and a child version (SET-10, QUESTIONS #62).
         */
        get: operations["getConsentText"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/household/profiles/{profileId}/consents": {
        parameters: {
            query?: never;
            header?: never;
            path: {
                profileId: components["parameters"]["ProfileId"];
            };
            cookie?: never;
        };
        /**
         * List a member's consent records
         * @description All consent records for the member, newest first, including withdrawn ones (SET-03).
         */
        get: operations["listConsentRecords"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/household/profiles/{profileId}/consents/health-data": {
        parameters: {
            query?: never;
            header?: never;
            path: {
                profileId: components["parameters"]["ProfileId"];
            };
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Record the manager's health-data consent decision for a member
         * @description Records an explicit decision, given or declined, on storing the member's hard rules (ACC-08, SET-03). Nothing is pre-given. `textVersion` must be the current version from `getConsentText` for the member's audience (the child text for an infant, child or teen profile), else 409 `consent_text_outdated`. `expectedConsent` is the member's `rules.consent` the manager was shown; if the stored state has moved since (another phone decided or withdrew), nothing is recorded and the answer is 409 `consent_changed`. For a child profile the guardian confirmation must be on record, else 409 `guardian_confirmation_required` (SET-10). A decline stores no rules; the member shows "rules not saved". Online only: never queue this request offline; ask again after a 409.
         */
        post: operations["recordHealthDataConsent"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/household/profiles/{profileId}/consents/health-data/withdraw": {
        parameters: {
            query?: never;
            header?: never;
            path: {
                profileId: components["parameters"]["ProfileId"];
            };
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Withdraw a member's health-data consent
         * @description Withdraws the current consent (SET-03). The member's hard rules stop being used at once and are deleted by `deletionDueBy`, set from the configured period (SET-04, 30 days target). Cek Aman no longer checks rules for this member, and clients show "rules not saved". `expectedConsent` is the state the manager was shown; if it has moved since, nothing changes and the answer is 409 `consent_changed`. Returns 409 `consent_not_active` when there is no current consent. Online only: never queue this request offline.
         */
        post: operations["withdrawHealthDataConsent"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/household/kitchen/items": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * List the household's saved ingredients
         * @description The saved kitchen of the session's household, the same on every phone signed in to it (KIT-01). Items come in KIT-03 category order. The default staples are created with the household as available and stay available until the user marks them out (KIT-07, ACC-05). Reference names come from the verified reference dataset; when it is not available the list is still returned, with `displayName` null.
         */
        get: operations["listKitchenItems"];
        put?: never;
        /**
         * Add an ingredient to the kitchen
         * @description Adds a reference ingredient found by search (KIT-04) or a custom ingredient (KIT-05). A custom ingredient is stored with `ingredientId: null` and `isCustom: true`; Cek Aman gives it "Check the label" for every member with a hard rule (SAF-09). An unknown `ingredientId` gives 400 `validation_failed`. When the reference dataset cannot be verified, adding a reference ingredient gives 503 `reference_data_unavailable` (custom ingredients still work). If the ingredient is already in the kitchen nothing is duplicated: the existing item takes the requested state and is returned with 200. Returns 409 `kitchen_item_limit_reached` at the configured limit.
         */
        post: operations["addKitchenItem"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/household/kitchen/items/{itemId}": {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description A kitchen item in the session's household. */
                itemId: components["parameters"]["ItemId"];
            };
            cookie?: never;
        };
        get?: never;
        put?: never;
        post?: never;
        /**
         * Remove an ingredient from the kitchen
         * @description Removes the item and its set memberships. A default staple can be removed too; marking it out keeps it in the list instead (KIT-07).
         */
        delete: operations["removeKitchenItem"];
        options?: never;
        head?: never;
        /**
         * Change an ingredient's state or details
         * @description One tap toggles available and out (KIT-02). Only the fields present are changed. The change is stamped with the server time and wins over any earlier change to the same ingredient (KIT-16); sending the same change again leaves the same result. `quantity` and `brand` (KIT-09) are served from T-032; a server without them answers 400 `validation_failed` for those fields.
         */
        patch: operations["updateKitchenItem"];
        trace?: never;
    };
    "/v1/household/kitchen/sets": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** List the household's ingredient sets */
        get: operations["listIngredientSets"];
        put?: never;
        /**
         * Create an ingredient set
         * @description A named group of kitchen items, for example "Belanja mingguan" (KIT-08). Unknown item IDs give 404 `not_found`. Returns 409 `ingredient_set_limit_reached` at the configured limit.
         */
        post: operations["createIngredientSet"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/household/kitchen/sets/{setId}": {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description An ingredient set in the session's household. */
                setId: components["parameters"]["SetId"];
            };
            cookie?: never;
        };
        get?: never;
        /**
         * Rename an ingredient set or change its items
         * @description The whole set is replaced, so an offline edit sent again is safe.
         */
        put: operations["replaceIngredientSet"];
        post?: never;
        /**
         * Delete an ingredient set
         * @description The items stay in the kitchen.
         */
        delete: operations["deleteIngredientSet"];
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/household/kitchen/sets/{setId}/mark-available": {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description An ingredient set in the session's household. */
                setId: components["parameters"]["SetId"];
            };
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Mark every item in a set available
         * @description "Tandai semua ada" (KIT-08): every item in the set becomes available in one call, stamped with the server time (KIT-16). No other item changes, and nothing becomes out. Sending it again leaves the same result. The response lists the set's items after the change; the client keeps the earlier states for its undo.
         */
        post: operations["markIngredientSetAvailable"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/household/kitchen/sync": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Send queued kitchen changes and fetch changes from other phones
         * @description KIT-16 offline sync. The phone sends the changes it queued while offline, oldest first, and the cursor of its last sync. Each change names its ingredient (a reference ID or a custom name), so an item added offline needs no server ID. The server places each change on its own clock at the time it was made (now minus `ageMs`, so a phone with a wrong clock still orders correctly) and keeps, per ingredient, the latest change: an older change than the stored one is `superseded` and the stored item is returned. Every change has a `changeId`; sending it again returns its first result without applying it twice, so replaying the queue is safe. The response carries every item changed or removed since the cursor (all items when `cursor` is null or too old, with `full: true`) and a new cursor. A rejected change (for example an unknown ingredient or the item limit) never stops the rest.
         */
        post: operations["syncKitchen"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/reference/ingredients": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get the whole reference ingredient catalog
         * @description Every ingredient of the verified reference dataset with its names, local and regional names, kitchen category and brands, for the copy the phone keeps for offline search (KIT-04). `referenceVersion` changes whenever the data changes. When the dataset is not loaded or fails verification the answer is 503 `reference_data_unavailable`, never an empty catalog. No safety data (components, allergens, halal) is included: only Cek Aman uses those. The `ETag` identifies the dataset; a phone that sends it back in `If-None-Match` gets 304 with no body while its copy is current, so refreshing the copy is cheap.
         */
        get: operations["listReferenceIngredients"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/reference/ingredients/search": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Search the reference ingredients by name or local name
         * @description Searches the standard Indonesian ingredient list by name (Indonesian or English) and by local or regional name, for example kemangi, daun salam, tempe or kecap manis (KIT-04). Matching ignores case, accents and spacing (Unicode NFKC); exact and starting matches come first. The same search picks ingredients for likes and dislikes (PRF-06) and for a rule mapping (PRF-08; QUESTIONS #49). The query is sent in the body so it never appears in a URL or an access log. An empty `items` means no ingredient matched; when the reference dataset is not loaded or fails verification the answer is 503 `reference_data_unavailable`, never an empty list.
         */
        post: operations["searchReferenceIngredients"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/reference/allergens": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * List the standard allergen list
         * @description The PRF-04 standard allergen list in display order, from the Cek Aman rule-set vocabulary. Clients show localized labels for each code.
         */
        get: operations["listStandardAllergens"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
}
export type webhooks = Record<string, never>;
export interface components {
    schemas: {
        /**
         * @description Opaque identifier (lowercase, safe for Cek Aman rule IDs).
         * @example 0b7f3c2e-6f1a-4c55-9d3e-2a1b4c5d6e7f
         */
        Id: string;
        /**
         * @description Identifier of a reference ingredient or library dish.
         * @example example_ingredient
         */
        ReferenceId: string;
        /**
         * @description App and content language (ACC-09). `id` is Bahasa Indonesia.
         * @enum {string}
         */
        Language: "id" | "en";
        /** @description Text in both languages. */
        LocalizedText: {
            id: string;
            en: string;
        };
        /** @description RFC 9457 problem details. `title` and `detail` are for developers and logs, in English, and never contain health data, names or contact details; clients show text localized from `code`. */
        Problem: {
            /**
             * @description Problem type URI, `urn:keluargamakan:problem:<code>`.
             * @example urn:keluargamakan:problem:consent_required
             */
            type: string;
            /** @example Consent required */
            title: string;
            status: number;
            code: components["schemas"]["ErrorCode"];
            detail?: string | null;
            /** @description Correlation ID to quote in support requests. */
            requestId: string;
            /** @description Present on 429 and on 503 when a retry time is known. */
            retryAfterSeconds?: number | null;
            /** @description Field errors for `validation_failed`. */
            errors?: components["schemas"]["FieldError"][];
        };
        FieldError: {
            /**
             * @description JSON Pointer (RFC 6901) into the request body, for example `/name`.
             * @example /name
             */
            pointer: string;
            code: components["schemas"]["FieldErrorCode"];
        };
        /** @enum {string} */
        FieldErrorCode: "required" | "invalid_type" | "invalid_format" | "invalid_value" | "too_short" | "too_long" | "too_many_items" | "duplicate" | "not_allowed";
        /**
         * @description Stable machine-readable error code. New codes may be added; clients treat an unknown code like `internal_error`.
         * @enum {string}
         */
        ErrorCode: "validation_failed" | "code_invalid" | "code_expired" | "code_attempts_exceeded" | "unauthenticated" | "access_token_expired" | "refresh_token_invalid" | "google_token_invalid" | "forbidden" | "not_found" | "household_required" | "household_exists" | "profile_limit_reached" | "manager_profile_not_deletable" | "guardian_confirmation_required" | "consent_required" | "consent_text_outdated" | "consent_not_active" | "consent_changed" | "manager_profile_must_be_adult" | "hard_rule_duplicate" | "mapping_not_applicable" | "idempotency_key_reused" | "kitchen_item_limit_reached" | "ingredient_set_limit_reached" | "rate_limited" | "rules_unavailable" | "reference_data_unavailable" | "sign_in_method_unavailable" | "service_unavailable" | "internal_error";
        /** @enum {string} */
        SignInChannel: "phone" | "email";
        /** @enum {string} */
        SignInMethod: "phone" | "email" | "google";
        /**
         * @description Android only (owner decision 2026-11-10).
         * @enum {string}
         */
        DevicePlatform: "android";
        /** @description Identifies the app installation for session management. No device name, model or advertising ID. */
        DeviceInfo: {
            /**
             * Format: uuid
             * @description Random UUID generated by the app on first launch.
             */
            installationId: string;
            platform: components["schemas"]["DevicePlatform"];
            /** @example 0.1.0 */
            appVersion: string;
        };
        /** @description `destination` is a phone number in E.164 form (the app turns "08…" into "+628…") or an email address, matching `channel`. */
        SignInCodeRequest: {
            channel: components["schemas"]["SignInChannel"];
            /** @example +6281200000000 */
            destination: string;
            /** @description Language of the message that carries the code. */
            language: components["schemas"]["Language"];
        };
        /** @description Does not echo the destination. */
        SignInCodeChallenge: {
            /** Format: uuid */
            challengeId: string;
            channel: components["schemas"]["SignInChannel"];
            /** @description Number of digits, from configuration. */
            codeLength: number;
            /** Format: date-time */
            expiresAt: string;
            /**
             * Format: date-time
             * @description Earliest time a new code may be requested (configuration).
             */
            resendAvailableAt: string;
        };
        SignInCodeVerification: {
            /** Format: uuid */
            challengeId: string;
            code: string;
            device: components["schemas"]["DeviceInfo"];
        };
        GoogleSignIn: {
            /** @description Google ID token from Credential Manager on Android. */
            idToken: string;
            device: components["schemas"]["DeviceInfo"];
        };
        SessionRefresh: {
            refreshToken: string;
        };
        /** @description Lifetimes come from configuration. Store tokens in encrypted device storage only. */
        SessionTokens: {
            /** @enum {string} */
            tokenType: "Bearer";
            accessToken: string;
            /** Format: date-time */
            accessTokenExpiresAt: string;
            refreshToken: string;
            /** Format: date-time */
            refreshTokenExpiresAt: string;
        };
        Session: {
            tokens: components["schemas"]["SessionTokens"];
            account: components["schemas"]["Account"];
            /** @description True when this sign-in created the account. */
            isNewAccount: boolean;
        };
        /**
         * @description V1 has manager accounts only; co-cooks arrive in V2 (ACC-11).
         * @enum {string}
         */
        AccountRole: "manager";
        /** @description The signed-in user's own account (SRS 18.1 Account). Contact details are returned only to their owner and are never sent to AI services (AI-03). */
        Account: {
            id: components["schemas"]["Id"];
            role: components["schemas"]["AccountRole"];
            /** @description Null until the household is created. */
            householdId: components["schemas"]["Id"] | null;
            signInMethods: components["schemas"]["SignInMethod"][];
            /** @description E.164 phone number, if verified. */
            phone: string | null;
            /** @description Email address, if verified or from Google. */
            email: string | null;
            /** Format: date-time */
            createdAt: string;
        };
        /**
         * @description IANA time zone name (NFR-16).
         * @example Asia/Jakarta
         */
        TimeZone: string;
        HouseholdName: string;
        City: string;
        /** @description SRS 18.1 Household. */
        Household: {
            id: components["schemas"]["Id"];
            name: components["schemas"]["HouseholdName"] | null;
            city: components["schemas"]["City"] | null;
            timeZone: components["schemas"]["TimeZone"];
            language: components["schemas"]["Language"];
            /** @description The household's only manager account (ACC-03). */
            managerAccountId: components["schemas"]["Id"];
            /** @description The manager's own profile. */
            managerProfileId: components["schemas"]["Id"];
            /** Format: date-time */
            createdAt: string;
            /** Format: date-time */
            updatedAt: string;
        };
        /** @description The manager's own profile from onboarding (ACC-04). Only a name is asked; the age group starts as `adult` and can be edited later. */
        ManagerProfileCreate: {
            name: components["schemas"]["ProfileName"];
            avatar?: components["schemas"]["Avatar"];
        };
        HouseholdCreate: {
            name?: components["schemas"]["HouseholdName"];
            city?: components["schemas"]["City"];
            timeZone: components["schemas"]["TimeZone"];
            language: components["schemas"]["Language"];
            managerProfile: components["schemas"]["ManagerProfileCreate"];
        };
        /** @description Fields present are changed; null clears `name` or `city`. */
        HouseholdUpdate: {
            name?: components["schemas"]["HouseholdName"] | null;
            city?: components["schemas"]["City"] | null;
            timeZone?: components["schemas"]["TimeZone"];
            language?: components["schemas"]["Language"];
        };
        /** @description Nickname such as "Ayah" or "Kakak" (PRF-01). */
        ProfileName: string;
        /**
         * @description PRF-01 age groups (DECISIONS 2026-11-10): infant 0–1, child 2–12, teen 13–17, adult 18–59, elderly 60+. Infant, child and teen are flagged as children (PRF-18).
         * @enum {string}
         */
        AgeGroup: "infant" | "child" | "teen" | "adult" | "elderly";
        /** @enum {string} */
        AvatarStyle: "initials" | "illustration";
        /** @description Initials on a colour, or a preset illustration with no faces. There is no member photo upload in V1 (QUESTIONS #27). */
        Avatar: {
            style: components["schemas"]["AvatarStyle"];
            /** @description Design-system avatar colour token, for `initials`. */
            colorToken?: string | null;
            /** @description Preset illustration ID, for `illustration`. */
            illustrationId?: string | null;
        };
        /** @enum {string} */
        PortionSize: "small" | "normal" | "large";
        /** @description PRF-07 portion size and rice portion. When `*IsDefault` is true the value is the age-group default from configuration. */
        Portions: {
            portionSize: components["schemas"]["PortionSize"];
            portionSizeIsDefault: boolean;
            ricePortion: components["schemas"]["PortionSize"];
            ricePortionIsDefault: boolean;
        };
        /** @description The manager confirms being the child's parent or guardian (SET-10). `confirmed` must be true; `textVersion` is the current `guardian_confirmation` consent text version. */
        GuardianConfirmationInput: {
            confirmed: boolean;
            textVersion: components["schemas"]["ConsentTextVersion"];
            language: components["schemas"]["Language"];
        };
        /** @description The recorded guardian confirmation for a child profile (SET-10). */
        GuardianConfirmation: {
            consentRecordId: components["schemas"]["Id"];
            /** Format: date-time */
            confirmedAt: string;
            textVersion: components["schemas"]["ConsentTextVersion"];
        };
        /** @description SRS 18.1 Profile, with its hard rules, soft preferences and likes. The API never returns another household's profiles. Sensitive as a whole because it embeds the member's hard rules. */
        Profile: {
            id: components["schemas"]["Id"];
            name: components["schemas"]["ProfileName"];
            avatar: components["schemas"]["Avatar"];
            ageGroup: components["schemas"]["AgeGroup"];
            /** @description Derived from `ageGroup` (infant, child or teen): stricter data handling applies, health data is off by default and the profile is never used for marketing (PRF-18, SET-10). Read-only. */
            isChild: boolean;
            /** @description True for the manager's own profile. Read-only. */
            isManager: boolean;
            /** @description Present for child profiles; null for adults. */
            guardianConfirmation: components["schemas"]["GuardianConfirmation"] | null;
            portions: components["schemas"]["Portions"];
            rules: components["schemas"]["ProfileRules"];
            preferences: components["schemas"]["SoftPreferences"];
            likesDislikes: components["schemas"]["LikesDislikes"];
            /** Format: date-time */
            createdAt: string;
            /** Format: date-time */
            updatedAt: string;
        };
        ProfileList: {
            /** @description Manager's profile first. */
            items: components["schemas"]["Profile"][];
            /** @description Configured profile limit (PRF-02, at least 12, target). */
            maxProfiles: number;
        };
        /** @description `guardianConfirmation` is required when `ageGroup` is infant, child or teen (SET-10). */
        ProfileCreate: {
            name: components["schemas"]["ProfileName"];
            ageGroup: components["schemas"]["AgeGroup"];
            avatar?: components["schemas"]["Avatar"];
            guardianConfirmation?: components["schemas"]["GuardianConfirmationInput"];
        };
        /** @description Fields present are changed. Null `portionSize` or `ricePortion` resets it to the age-group default. */
        ProfileUpdate: {
            name?: components["schemas"]["ProfileName"];
            avatar?: components["schemas"]["Avatar"];
            ageGroup?: components["schemas"]["AgeGroup"];
            portionSize?: components["schemas"]["PortionSize"] | null;
            ricePortion?: components["schemas"]["PortionSize"] | null;
            guardianConfirmation?: components["schemas"]["GuardianConfirmationInput"];
        };
        /** @enum {string} */
        SpiceLevel: "not_spicy" | "medium" | "spicy";
        /**
         * @description "Kurangi" preferences: less fried food, sugar, salt or santan (PRF-05).
         * @enum {string}
         */
        LessOf: "fried" | "sugar" | "salt" | "santan";
        /**
         * @description Liked textures (PRF-05).
         * @enum {string}
         */
        TexturePreference: "soft" | "crunchy" | "soupy";
        /** @description SRS 18.1 Soft preference. Not health data. */
        SoftPreferencesInput: {
            /** @description Null when not chosen (ranked as `medium`). */
            spiceLevel: components["schemas"]["SpiceLevel"] | null;
            lessOf: components["schemas"]["LessOf"][];
            textures: components["schemas"]["TexturePreference"][];
        };
        SoftPreferences: {
            spiceLevel: components["schemas"]["SpiceLevel"] | null;
            lessOf: components["schemas"]["LessOf"][];
            textures: components["schemas"]["TexturePreference"][];
            /**
             * Format: date-time
             * @description Null until first saved.
             */
            updatedAt: string | null;
        };
        /** @enum {string} */
        FoodRefKind: "ingredient" | "dish";
        /** @description An ingredient or a library dish picked by search (PRF-06). */
        FoodRefInput: {
            kind: components["schemas"]["FoodRefKind"];
            refId: components["schemas"]["ReferenceId"];
        };
        FoodRef: {
            kind: components["schemas"]["FoodRefKind"];
            refId: components["schemas"]["ReferenceId"];
            /** @description Reference display name, filled by the server. */
            displayName: components["schemas"]["LocalizedText"];
        };
        /** @description An item may not be both liked and disliked. */
        LikesDislikesInput: {
            likes: components["schemas"]["FoodRefInput"][];
            dislikes: components["schemas"]["FoodRefInput"][];
        };
        LikesDislikes: {
            likes: components["schemas"]["FoodRef"][];
            dislikes: components["schemas"]["FoodRef"][];
            /**
             * Format: date-time
             * @description Null until first saved.
             */
            updatedAt: string | null;
        };
        /**
         * @description PRF-03 hard rule types, matching the Cek Aman vocabulary.
         * @enum {string}
         */
        HardRuleType: "allergy" | "halal" | "vegetarian" | "vegan" | "medical_exclusion" | "free_text";
        /**
         * @description PRF-04 standard allergen codes, matching the Cek Aman vocabulary. Shellfish and shrimp, and wheat and gluten, are separate codes.
         * @enum {string}
         */
        StandardAllergen: "peanut" | "tree_nut" | "shellfish" | "shrimp" | "fish" | "egg" | "milk" | "soy" | "wheat" | "gluten" | "sesame";
        /**
         * @description PRF-08 mapping state. Only `mapped` is evaluated as a mapping; `proposed` and `unmapped` make Cek Aman return "Check the label" for related recipes (SAF-09).
         * @enum {string}
         */
        MappingStatus: "mapped" | "proposed" | "unmapped";
        /** @enum {string} */
        MappingConfirmer: "content_team" | "manager";
        MappedIngredient: {
            ingredientId: components["schemas"]["ReferenceId"];
            displayName: components["schemas"]["LocalizedText"];
        };
        /** @description How a free-text or medical-exclusion rule maps to reference ingredients. `ingredients` is empty when `unmapped`. `confirmedBy` is set only when `mapped`. */
        HardRuleMapping: {
            status: components["schemas"]["MappingStatus"];
            ingredients: components["schemas"]["MappedIngredient"][];
            confirmedBy: components["schemas"]["MappingConfirmer"] | null;
            /** Format: date-time */
            updatedAt: string;
        };
        /** @description SRS 18.1 Hard rule, never overridden (PRF-03, SAF-12). `allergen` is set only for `allergy`; `freeText` is required for `free_text` and optional for `medical_exclusion`; `mapping` is set only for those two types. Stored encrypted with the health-data key (DAT-02). */
        HardRule: {
            id: components["schemas"]["Id"];
            type: components["schemas"]["HardRuleType"];
            allergen: components["schemas"]["StandardAllergen"] | null;
            freeText: string | null;
            mapping: components["schemas"]["HardRuleMapping"] | null;
            /** Format: date-time */
            createdAt: string;
        };
        /** @description `allergen` is required for `allergy` and not allowed otherwise. `freeText` is required for `free_text`, optional for `medical_exclusion` and not allowed otherwise. No condition names are asked for a medical exclusion. `mappedIngredientIds` (free text and medical exclusion only) records the manager's confirmed match at entry. When it is absent or null the rule is saved as `unmapped` (PRF-08); it is nullable so generated clients leave it out by default instead of sending an empty list. */
        HardRuleCreate: {
            type: components["schemas"]["HardRuleType"];
            allergen?: components["schemas"]["StandardAllergen"];
            freeText?: string;
            /** @description Absent or null for an unmapped rule. When present, at least one reference ingredient ID; an empty list is rejected. */
            mappedIngredientIds?: components["schemas"]["MappedIngredientIds"] | null;
        };
        /** @description Reference ingredients a free-text or medical-exclusion rule maps to (PRF-08). */
        MappedIngredientIds: components["schemas"]["ReferenceId"][];
        HardRuleMappingConfirmation: {
            ingredientIds: components["schemas"]["ReferenceId"][];
        };
        /**
         * @description Health-data consent state for the member's hard rules (QUESTIONS #36). Only `given` allows rules; for every other state there are no rules and clients show "rules not saved", never "Safe".
         * @enum {string}
         */
        RulesConsentStatus: "none" | "given" | "declined" | "withdrawn";
        RulesConsentState: {
            /** @description True when the consent was given on the other audience's text (the member changed between adult and child, QUESTIONS #62). The stored rules are still returned and still checked by Cek Aman, but no new health data is saved (409 `consent_required`) until a new decision is recorded on the current text for the member's audience. */
            renewalRequired: boolean;
            status: components["schemas"]["RulesConsentStatus"];
            /** @description The latest health-data consent record, or null for `none`. */
            consentRecordId: components["schemas"]["Id"] | null;
            /** Format: date-time */
            decidedAt: string | null;
            textVersion: components["schemas"]["ConsentTextVersion"] | null;
            /**
             * Format: date-time
             * @description For `withdrawn`, when stored rules will have been deleted (SET-04).
             */
            deletionDueBy: string | null;
        };
        /** @description A member's hard rules and consent state. `consent.status: given` with empty `items` means the member has no hard rules. When rules cannot be read the server fails the request instead (QUESTIONS #39). */
        ProfileRules: {
            consent: components["schemas"]["RulesConsentState"];
            /** @description Empty unless `consent.status` is `given`. */
            items: components["schemas"]["HardRule"][];
        };
        StandardAllergenList: {
            /** @description Cek Aman rule-set version the list comes from (DAT-06). */
            ruleSetVersion: string;
            /** @description Display order (PRF-04). */
            items: components["schemas"]["StandardAllergen"][];
        };
        /**
         * @description `health_data` covers all hard rules (QUESTIONS #13). `guardian_confirmation` records the manager's confirmation as parent or guardian of a child profile (SET-10).
         * @enum {string}
         */
        ConsentPurpose: "health_data" | "guardian_confirmation";
        /**
         * @description Which health-data consent text applies: `child` for infant, child and teen profiles (the manager decides as parent or guardian, SET-10), `adult` otherwise.
         * @enum {string}
         */
        ConsentAudience: "adult" | "child";
        /** @enum {string} */
        ConsentDecision: "given" | "declined";
        /** @example health-data-draft-1 */
        ConsentTextVersion: string;
        ConsentTextSection: {
            heading: string;
            /** @description Plain text; paragraphs separated by blank lines. */
            body: string;
        };
        ConsentText: {
            purpose: components["schemas"]["ConsentPurpose"];
            version: components["schemas"]["ConsentTextVersion"];
            language: components["schemas"]["Language"];
            title: string;
            sections: components["schemas"]["ConsentTextSection"][];
            /** Format: date */
            effectiveDate: string;
            /** @description True until the text is approved by legal review. */
            isDraft: boolean;
        };
        HealthDataConsentDecision: {
            decision: components["schemas"]["ConsentDecision"];
            textVersion: components["schemas"]["ConsentTextVersion"];
            /** @description Language of the text the manager was shown. */
            language: components["schemas"]["Language"];
            expectedConsent: components["schemas"]["ExpectedConsentState"];
        };
        HealthDataConsentWithdrawal: {
            expectedConsent: components["schemas"]["ExpectedConsentState"];
        };
        /** @description Precondition for a consent write (security review T-019 M1): the `status` and `consentRecordId` of the member's `rules.consent` as the manager was shown it. `{status: none, consentRecordId: null}` for a member with no decision yet. */
        ExpectedConsentState: {
            status: components["schemas"]["RulesConsentStatus"];
            consentRecordId: components["schemas"]["Id"] | null;
        };
        /** @description SRS 18.1 Consent record (SET-03). */
        ConsentRecord: {
            id: components["schemas"]["Id"];
            profileId: components["schemas"]["Id"];
            purpose: components["schemas"]["ConsentPurpose"];
            decision: components["schemas"]["ConsentDecision"];
            textVersion: components["schemas"]["ConsentTextVersion"];
            language: components["schemas"]["Language"];
            /** Format: date-time */
            decidedAt: string;
            /** @description The manager account that recorded the decision. */
            recordedByAccountId: components["schemas"]["Id"];
            /** Format: date-time */
            withdrawnAt: string | null;
            /**
             * Format: date-time
             * @description Set on withdrawal of `health_data` consent (SET-04).
             */
            deletionDueBy: string | null;
        };
        ConsentRecordList: {
            /** @description Newest first. */
            items: components["schemas"]["ConsentRecord"][];
        };
        /**
         * @description KIT-03 categories in display order: protein, vegetables, fruit, spices and aromatics, staples, sauces and condiments, dairy, frozen and leftovers. The app shows its own Bahasa Indonesia or English label for each code. Leftovers holds custom items in V1; saved leftovers (KIT-13) use the same code later.
         * @enum {string}
         */
        KitchenCategory: "protein" | "vegetables" | "fruit" | "spices_aromatics" | "staples" | "sauces_condiments" | "dairy" | "frozen" | "leftovers";
        /**
         * @description KIT-02: available ("Ada") or out ("Habis"). Clients show an unknown state as out, never as available.
         * @enum {string}
         */
        KitchenItemState: "available" | "out";
        /**
         * @description KIT-09 optional amount.
         * @enum {string}
         */
        KitchenQuantity: "a_little" | "some" | "plenty";
        /** @description A custom ingredient's name as the user typed it (KIT-05), stored in Unicode NFC with surrounding spaces removed. Text with control, format or private-use characters is refused. Names that differ only in case, accents, punctuation or spacing are the same ingredient. */
        KitchenCustomName: string;
        /** @description The brand recorded for an item (KIT-09, SAF-07). `brandId` is one of the ingredient's reference brands, or null for a brand typed as text, for which Cek Aman keeps "Check the label" on brand-varying components. A brand is never shown as safe or verified. */
        KitchenBrand: {
            brandId: components["schemas"]["ReferenceId"] | null;
            /** @description The reference brand name, or the text as typed. */
            name: string;
        };
        /** @description Exactly one of `brandId` (from the ingredient's catalog `brands`) or `customName` (a brand not in the list). Only reference ingredients take a `brandId`. */
        KitchenBrandInput: {
            brandId?: components["schemas"]["ReferenceId"];
            customName?: string;
        };
        /** @description SRS 18.1 Kitchen item. A reference ingredient has `ingredientId` and its reference `displayName` (null while the reference data is not available or no longer lists the ingredient). A custom ingredient (KIT-05) has `ingredientId: null`, `isCustom: true` and `customName`; Cek Aman gives "Check the label" for it to every member with a hard rule (SAF-09). `changedAt` is the server time of the last accepted change (KIT-16). */
        KitchenItem: {
            id: components["schemas"]["Id"];
            ingredientId: components["schemas"]["ReferenceId"] | null;
            /** @description True exactly when `ingredientId` is null (KIT-05 flag). */
            isCustom: boolean;
            displayName: components["schemas"]["LocalizedText"] | null;
            customName: components["schemas"]["KitchenCustomName"] | null;
            category: components["schemas"]["KitchenCategory"];
            state: components["schemas"]["KitchenItemState"];
            quantity: components["schemas"]["KitchenQuantity"] | null;
            brand: components["schemas"]["KitchenBrand"] | null;
            /** @description Created with the household as a default staple (KIT-07, ACC-05). */
            isDefaultStaple: boolean;
            /** @description KIT-06: 1 is the most used item in its category. Null until use is recorded; clients then fall back to their own order. */
            usageRank: number | null;
            /** Format: date-time */
            changedAt: string;
            /** Format: date-time */
            createdAt: string;
        };
        KitchenItemList: {
            /** @description In KIT-03 category order. */
            items: components["schemas"]["KitchenItem"][];
            /** @description The configured limit of items per household. */
            maxItems: number;
            /** @description DAT-06 version of the reference data the names come from, or null when it is not available. */
            referenceVersion: string | null;
        };
        /** @description Exactly one of `ingredientId` (a reference ingredient, KIT-04) or `customName` (KIT-05). `category` is required for a custom ingredient and for a reference ingredient whose catalog `category` is null; otherwise the catalog category is used. `state` defaults to `available`. */
        KitchenItemCreate: {
            ingredientId?: components["schemas"]["ReferenceId"];
            customName?: components["schemas"]["KitchenCustomName"];
            category?: components["schemas"]["KitchenCategory"];
            state?: components["schemas"]["KitchenItemState"];
        };
        /** @description Only the fields present change. `quantity` and `brand` may be null to clear them (KIT-09). */
        KitchenItemUpdate: {
            state?: components["schemas"]["KitchenItemState"];
            category?: components["schemas"]["KitchenCategory"];
            quantity?: components["schemas"]["KitchenQuantity"] | null;
            brand?: components["schemas"]["KitchenBrandInput"] | null;
        };
        /** @example Belanja mingguan */
        IngredientSetName: string;
        /** @description SRS 18.1 Ingredient set (KIT-08). */
        IngredientSet: {
            id: components["schemas"]["Id"];
            name: components["schemas"]["IngredientSetName"];
            /** @description Kitchen items in the set; a removed item leaves the set. */
            itemIds: components["schemas"]["Id"][];
            /** Format: date-time */
            createdAt: string;
            /** Format: date-time */
            updatedAt: string;
        };
        IngredientSetList: {
            items: components["schemas"]["IngredientSet"][];
            /** @description The configured limit of sets per household. */
            maxSets: number;
        };
        IngredientSetInput: {
            name: components["schemas"]["IngredientSetName"];
            itemIds: components["schemas"]["Id"][];
        };
        /** @description The ingredient a sync change is for (KIT-16: the latest change wins per ingredient): exactly one of `ingredientId` or `customName`. Custom names are compared ignoring case, accents, punctuation and spacing. */
        KitchenIngredientKey: {
            ingredientId?: components["schemas"]["ReferenceId"];
            customName?: components["schemas"]["KitchenCustomName"];
        };
        /**
         * @description `upsert` adds the ingredient if needed and sets the fields present; `remove` takes it out of the kitchen.
         * @enum {string}
         */
        KitchenChangeOperation: "upsert" | "remove";
        /** @description One change queued on the phone. For `upsert`, `category` is needed when the ingredient is new and has no catalog category; `quantity` and `brand` may be null to clear them. */
        KitchenChange: {
            /**
             * Format: uuid
             * @description Random UUID made with the change; a repeat returns the first result.
             */
            changeId: string;
            ingredient: components["schemas"]["KitchenIngredientKey"];
            operation: components["schemas"]["KitchenChangeOperation"];
            /** @description Milliseconds from the edit to sending this request, measured on the phone. The server dates the change at its own time minus this age (KIT-16), so the phone's clock setting does not matter. Changes older than the server's limit are superseded by any later change. */
            ageMs: number;
            category?: components["schemas"]["KitchenCategory"];
            state?: components["schemas"]["KitchenItemState"];
            quantity?: components["schemas"]["KitchenQuantity"] | null;
            brand?: components["schemas"]["KitchenBrandInput"] | null;
        };
        KitchenSyncRequest: {
            /** @description The `cursor` of the last sync response, or null for a first sync. */
            cursor: string | null;
            /** @description Oldest first. */
            changes: components["schemas"]["KitchenChange"][];
        };
        /**
         * @description `applied`: the change is the latest for its ingredient (also for a repeat of an applied change). `superseded`: a later change to the ingredient was already stored; the stored item is in `items`. `rejected`: the change cannot be applied (see `errorCode`); nothing changed.
         * @enum {string}
         */
        KitchenChangeOutcome: "applied" | "superseded" | "rejected";
        KitchenChangeResult: {
            /** Format: uuid */
            changeId: string;
            outcome: components["schemas"]["KitchenChangeOutcome"];
            /** @description The server's item for the ingredient, or null when there is none. */
            itemId: components["schemas"]["Id"] | null;
            /** @description Why a change was rejected, for example `validation_failed` or `kitchen_item_limit_reached`. */
            errorCode: components["schemas"]["ErrorCode"] | null;
        };
        KitchenSyncResponse: {
            /** @description Opaque; send it with the next sync. */
            cursor: string;
            /** @description True when `items` is the whole kitchen (first sync, or a cursor too old to continue from); the phone then replaces its copy, keeping only changes still queued. */
            full: boolean;
            /** @description Items changed since the cursor, in KIT-03 category order. */
            items: components["schemas"]["KitchenItem"][];
            /** @description Items removed since the cursor (empty when `full`). */
            removedItemIds: components["schemas"]["Id"][];
            /** @description One result per sent change, in the same order. */
            results: components["schemas"]["KitchenChangeResult"][];
            maxItems: number;
            referenceVersion: string | null;
        };
        /** @description A reference brand of an ingredient (KIT-09, SAF-07). Not a safety result. */
        CatalogBrand: {
            brandId: components["schemas"]["ReferenceId"];
            name: string;
        };
        /** @description A reference ingredient as the kitchen and search use it (SRS 18.1 Ingredient: names, local names, category, brands). It carries no components, allergens or halal data: only Cek Aman reads those. */
        CatalogIngredient: {
            ingredientId: components["schemas"]["ReferenceId"];
            displayName: components["schemas"]["LocalizedText"];
            /** @description Local, regional and alternative names (KIT-04). */
            localNames: string[];
            /** @description The kitchen category, or null when the reference data gives none; the app then asks for one when the ingredient is added. */
            category: components["schemas"]["KitchenCategory"] | null;
            /** @description SAF-07: what the ingredient contains can differ by brand, so the app offers to record a brand (KIT-09). This is not a safety result. */
            brandVaries: boolean;
            brands: components["schemas"]["CatalogBrand"][];
        };
        ReferenceIngredientCatalog: {
            /** @description DAT-06 version and content hash of the verified dataset. */
            referenceVersion: string;
            /** @description Sorted by Indonesian display name. */
            items: components["schemas"]["CatalogIngredient"][];
        };
        IngredientSearchRequest: {
            /** @description What the user typed. Hidden or control characters are refused (400). The query is never stored or logged. */
            query: string;
            /** @description At most this many results (default and upper limit from configuration). */
            limit?: number;
        };
        IngredientSearchHit: {
            ingredient: components["schemas"]["CatalogIngredient"];
            /** @description The local or regional name that matched, shown next to the display name; null when a display name matched. */
            matchedName: string | null;
        };
        IngredientSearchResult: {
            referenceVersion: string;
            /** @description Best match first. Empty only when nothing matched. */
            items: components["schemas"]["IngredientSearchHit"][];
        };
        /**
         * @description Confirm-and-Save session (REC-01 to REC-04). `collecting`: photos are being added; `processing`: they are being read; `ready`: a result waits for confirmation; `failed`: see `failureReason`; `confirmed` and `discarded`: closed by the user; `expired`: the result was not confirmed in time and was dropped. Clients treat an unknown status like `failed` and offer manual entry.
         * @enum {string}
         */
        PhotoSessionStatus: "collecting" | "processing" | "ready" | "failed" | "confirmed" | "discarded" | "expired";
        /**
         * @description `ai_not_enabled`: the household has not turned on AI features (SET-09); `ai_unavailable`: the recognizer is down, out of quota or too slow (INT-06 fallback: manual entry); `photos_unreadable`: the photos could not be read; `processing_failed`: any other failure.
         * @enum {string}
         */
        RecognitionFailureReason: "ai_not_enabled" | "ai_unavailable" | "photos_unreadable" | "processing_failed";
        /**
         * @description REC-02. `high` and `medium` items start ticked; `low` items are asked as a question with likely options and nothing preselected (REC-03). Clients treat an unknown value like `low`.
         * @enum {string}
         */
        RecognitionConfidence: "high" | "medium" | "low";
        /** @description A likely reference ingredient for a low-confidence item (REC-03). */
        RecognitionOption: {
            ingredientId: components["schemas"]["ReferenceId"];
            displayName: components["schemas"]["LocalizedText"];
        };
        /** @description One line of the checklist (REC-02). It carries no safety, allergen or halal field: a photo is never evidence for Cek Aman (REC-06, SAF-10). */
        RecognizedItem: {
            id: components["schemas"]["Id"];
            /** @description The name as read from the photo, shown when there is no reference match. */
            label: string;
            /** @description The reference ingredient the API matched by name, or null. A name that does not match is never guessed into an ID (AI-06). */
            ingredientId: components["schemas"]["ReferenceId"] | null;
            displayName: components["schemas"]["LocalizedText"] | null;
            confidence: components["schemas"]["RecognitionConfidence"];
            /** @description Likely options for a low-confidence item, for example tempe or tofu (REC-03). */
            options: components["schemas"]["RecognitionOption"][];
            /** @description The saved kitchen item this matches, preferred over new ones (REC-05). */
            kitchenItemId: components["schemas"]["Id"] | null;
        };
        /** @description The checklist. Nothing in it is saved until the user confirms (REC-04), and an unconfirmed result never reaches suggestions. */
        RecognitionResult: {
            /** @description Items matching saved kitchen items first (REC-05). Empty when nothing was recognized. */
            items: components["schemas"]["RecognizedItem"][];
            referenceVersion: string;
        };
        /** @description A photo setup session (REC-01). Photos are kept only in temporary storage and deleted as soon as they are processed (REC-07, SET-05, DAT-03); no response ever carries a photo or a link to one. */
        PhotoSession: {
            id: components["schemas"]["Id"];
            status: components["schemas"]["PhotoSessionStatus"];
            photoCount: number;
            /** @description Photos allowed per session, from configuration (REC-01, 5 target). */
            maxPhotos: number;
            failureReason: components["schemas"]["RecognitionFailureReason"] | null;
            /** @description Set when `status` is `ready`. */
            result: components["schemas"]["RecognitionResult"] | null;
            /** Format: date-time */
            createdAt: string;
            /**
             * Format: date-time
             * @description When an unconfirmed result is dropped (configuration, QUESTIONS
             */
            expiresAt: string;
        };
        /** @description One ticked line, as the user left it: exactly one of `ingredientId` (a recognized, chosen or searched reference ingredient) or `customName` (a free-text rename, saved as a flagged custom item, KIT-05). `category` follows the `KitchenItemCreate` rules. */
        RecognitionConfirmationItem: {
            /** @description The checklist line it came from; absent for an item the user added. */
            recognizedItemId?: components["schemas"]["Id"];
            ingredientId?: components["schemas"]["ReferenceId"];
            customName?: components["schemas"]["KitchenCustomName"];
            category?: components["schemas"]["KitchenCategory"];
        };
        /** @description "Simpan" (REC-04): only these items become available. Unticked lines are ignored, and no other kitchen item is removed or marked out. */
        RecognitionConfirmation: {
            items: components["schemas"]["RecognitionConfirmationItem"][];
        };
        RecognitionConfirmationResult: {
            /** @description The confirmed items, each now available. */
            items: components["schemas"]["KitchenItem"][];
        };
    };
    responses: {
        /** @description The request is malformed or fails validation. */
        BadRequest: {
            headers: {
                [name: string]: unknown;
            };
            content: {
                "application/problem+json": components["schemas"]["Problem"];
            };
        };
        /** @description Missing, invalid or expired credentials. */
        Unauthorized: {
            headers: {
                [name: string]: unknown;
            };
            content: {
                "application/problem+json": components["schemas"]["Problem"];
            };
        };
        /** @description The resource does not exist in the caller's household. */
        NotFound: {
            headers: {
                [name: string]: unknown;
            };
            content: {
                "application/problem+json": components["schemas"]["Problem"];
            };
        };
        /** @description The request conflicts with the current state; see `code`. */
        Conflict: {
            headers: {
                [name: string]: unknown;
            };
            content: {
                "application/problem+json": components["schemas"]["Problem"];
            };
        };
        /** @description Rate limit reached. */
        TooManyRequests: {
            headers: {
                "Retry-After": components["headers"]["RetryAfter"];
                [name: string]: unknown;
            };
            content: {
                "application/problem+json": components["schemas"]["Problem"];
            };
        };
        /** @description A dependency is unavailable; see `code`. */
        ServiceUnavailable: {
            headers: {
                "Retry-After": components["headers"]["RetryAfter"];
                [name: string]: unknown;
            };
            content: {
                "application/problem+json": components["schemas"]["Problem"];
            };
        };
        /** @description Any other error, including 403 and 5xx. */
        UnexpectedError: {
            headers: {
                [name: string]: unknown;
            };
            content: {
                "application/problem+json": components["schemas"]["Problem"];
            };
        };
    };
    parameters: {
        ProfileId: components["schemas"]["Id"];
        RuleId: components["schemas"]["Id"];
        /** @description A kitchen item in the session's household. */
        ItemId: components["schemas"]["Id"];
        /** @description An ingredient set in the session's household. */
        SetId: components["schemas"]["Id"];
        /** @description A client-generated UUID. Repeating a request with the same key returns the first result instead of creating a duplicate, so an offline queue can replay safely. Reusing a key with a different body returns 409 `idempotency_key_reused`. Keys are kept for a configured period. */
        IdempotencyKey: string;
    };
    requestBodies: never;
    headers: {
        /** @description Seconds to wait before retrying. */
        RetryAfter: number;
        /** @description Opaque entity tag of the served data (RFC 9110); changes whenever the data changes. */
        ETag: string;
        /** @description `private, no-cache`: only the phone may keep a copy, and it checks with `If-None-Match` before using it. */
        CacheControl: string;
    };
    pathItems: never;
}
export type $defs = Record<string, never>;
export interface operations {
    requestSignInCode: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["SignInCodeRequest"];
            };
        };
        responses: {
            /** @description Code sent (or silently not sent, see description). */
            202: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SignInCodeChallenge"];
                };
            };
            400: components["responses"]["BadRequest"];
            429: components["responses"]["TooManyRequests"];
            503: components["responses"]["ServiceUnavailable"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    verifySignInCode: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["SignInCodeVerification"];
            };
        };
        responses: {
            /** @description Signed in. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["Session"];
                };
            };
            400: components["responses"]["BadRequest"];
            429: components["responses"]["TooManyRequests"];
            503: components["responses"]["ServiceUnavailable"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    signInWithGoogle: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["GoogleSignIn"];
            };
        };
        responses: {
            /** @description Signed in. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["Session"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            429: components["responses"]["TooManyRequests"];
            503: components["responses"]["ServiceUnavailable"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    refreshSession: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["SessionRefresh"];
            };
        };
        responses: {
            /** @description New tokens. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SessionTokens"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            429: components["responses"]["TooManyRequests"];
            503: components["responses"]["ServiceUnavailable"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    signOut: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Signed out. */
            204: {
                headers: {
                    [name: string]: unknown;
                };
                content?: never;
            };
            401: components["responses"]["Unauthorized"];
            503: components["responses"]["ServiceUnavailable"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    getAccount: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description The account. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["Account"];
                };
            };
            401: components["responses"]["Unauthorized"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    getHousehold: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description The household. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["Household"];
                };
            };
            401: components["responses"]["Unauthorized"];
            409: components["responses"]["Conflict"];
            503: components["responses"]["ServiceUnavailable"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    createHousehold: {
        parameters: {
            query?: never;
            header?: {
                /** @description A client-generated UUID. Repeating a request with the same key returns the first result instead of creating a duplicate, so an offline queue can replay safely. Reusing a key with a different body returns 409 `idempotency_key_reused`. Keys are kept for a configured period. */
                "Idempotency-Key"?: components["parameters"]["IdempotencyKey"];
            };
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["HouseholdCreate"];
            };
        };
        responses: {
            /** @description Household created. */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["Household"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            409: components["responses"]["Conflict"];
            503: components["responses"]["ServiceUnavailable"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    updateHousehold: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["HouseholdUpdate"];
            };
        };
        responses: {
            /** @description The updated household. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["Household"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            409: components["responses"]["Conflict"];
            503: components["responses"]["ServiceUnavailable"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    listProfiles: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description The profiles. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ProfileList"];
                };
            };
            401: components["responses"]["Unauthorized"];
            409: components["responses"]["Conflict"];
            503: components["responses"]["ServiceUnavailable"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    createProfile: {
        parameters: {
            query?: never;
            header?: {
                /** @description A client-generated UUID. Repeating a request with the same key returns the first result instead of creating a duplicate, so an offline queue can replay safely. Reusing a key with a different body returns 409 `idempotency_key_reused`. Keys are kept for a configured period. */
                "Idempotency-Key"?: components["parameters"]["IdempotencyKey"];
            };
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["ProfileCreate"];
            };
        };
        responses: {
            /** @description Profile created. */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["Profile"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            409: components["responses"]["Conflict"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    getProfile: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                profileId: components["parameters"]["ProfileId"];
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description The profile. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["Profile"];
                };
            };
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            503: components["responses"]["ServiceUnavailable"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    deleteProfile: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                profileId: components["parameters"]["ProfileId"];
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Profile deleted. */
            204: {
                headers: {
                    [name: string]: unknown;
                };
                content?: never;
            };
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            409: components["responses"]["Conflict"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    updateProfile: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                profileId: components["parameters"]["ProfileId"];
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["ProfileUpdate"];
            };
        };
        responses: {
            /** @description The updated profile. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["Profile"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            409: components["responses"]["Conflict"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    replaceSoftPreferences: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                profileId: components["parameters"]["ProfileId"];
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["SoftPreferencesInput"];
            };
        };
        responses: {
            /** @description The saved preferences. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SoftPreferences"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    replaceLikesDislikes: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                profileId: components["parameters"]["ProfileId"];
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["LikesDislikesInput"];
            };
        };
        responses: {
            /** @description The saved likes and dislikes. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["LikesDislikes"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    listHardRules: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                profileId: components["parameters"]["ProfileId"];
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description The member's rules. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ProfileRules"];
                };
            };
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            503: components["responses"]["ServiceUnavailable"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    createHardRule: {
        parameters: {
            query?: never;
            header?: {
                /** @description A client-generated UUID. Repeating a request with the same key returns the first result instead of creating a duplicate, so an offline queue can replay safely. Reusing a key with a different body returns 409 `idempotency_key_reused`. Keys are kept for a configured period. */
                "Idempotency-Key"?: components["parameters"]["IdempotencyKey"];
            };
            path: {
                profileId: components["parameters"]["ProfileId"];
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["HardRuleCreate"];
            };
        };
        responses: {
            /** @description Rule saved. */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HardRule"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            409: components["responses"]["Conflict"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    deleteHardRule: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                profileId: components["parameters"]["ProfileId"];
                ruleId: components["parameters"]["RuleId"];
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Rule removed. */
            204: {
                headers: {
                    [name: string]: unknown;
                };
                content?: never;
            };
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    confirmHardRuleMapping: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                profileId: components["parameters"]["ProfileId"];
                ruleId: components["parameters"]["RuleId"];
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["HardRuleMappingConfirmation"];
            };
        };
        responses: {
            /** @description The updated rule. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HardRule"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            409: components["responses"]["Conflict"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    rejectHardRuleMapping: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                profileId: components["parameters"]["ProfileId"];
                ruleId: components["parameters"]["RuleId"];
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description The updated rule. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HardRule"];
                };
            };
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            409: components["responses"]["Conflict"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    getConsentText: {
        parameters: {
            query: {
                language: components["schemas"]["Language"];
                /** @description For `health_data`: `child` for an infant, child or teen profile, `adult` otherwise (default). Ignored for `guardian_confirmation`. */
                audience?: components["schemas"]["ConsentAudience"];
            };
            header?: never;
            path: {
                purpose: components["schemas"]["ConsentPurpose"];
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description The consent text. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ConsentText"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    listConsentRecords: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                profileId: components["parameters"]["ProfileId"];
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description The consent records. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ConsentRecordList"];
                };
            };
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    recordHealthDataConsent: {
        parameters: {
            query?: never;
            header?: {
                /** @description A client-generated UUID. Repeating a request with the same key returns the first result instead of creating a duplicate, so an offline queue can replay safely. Reusing a key with a different body returns 409 `idempotency_key_reused`. Keys are kept for a configured period. */
                "Idempotency-Key"?: components["parameters"]["IdempotencyKey"];
            };
            path: {
                profileId: components["parameters"]["ProfileId"];
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["HealthDataConsentDecision"];
            };
        };
        responses: {
            /** @description Decision recorded. */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ConsentRecord"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            409: components["responses"]["Conflict"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    withdrawHealthDataConsent: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                profileId: components["parameters"]["ProfileId"];
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["HealthDataConsentWithdrawal"];
            };
        };
        responses: {
            /** @description The withdrawn consent record. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ConsentRecord"];
                };
            };
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            409: components["responses"]["Conflict"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    listKitchenItems: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description The saved ingredients. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["KitchenItemList"];
                };
            };
            401: components["responses"]["Unauthorized"];
            409: components["responses"]["Conflict"];
            503: components["responses"]["ServiceUnavailable"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    addKitchenItem: {
        parameters: {
            query?: never;
            header?: {
                /** @description A client-generated UUID. Repeating a request with the same key returns the first result instead of creating a duplicate, so an offline queue can replay safely. Reusing a key with a different body returns 409 `idempotency_key_reused`. Keys are kept for a configured period. */
                "Idempotency-Key"?: components["parameters"]["IdempotencyKey"];
            };
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["KitchenItemCreate"];
            };
        };
        responses: {
            /** @description The ingredient was already in the kitchen; its updated item. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["KitchenItem"];
                };
            };
            /** @description Added. */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["KitchenItem"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            409: components["responses"]["Conflict"];
            503: components["responses"]["ServiceUnavailable"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    removeKitchenItem: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description A kitchen item in the session's household. */
                itemId: components["parameters"]["ItemId"];
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Removed. */
            204: {
                headers: {
                    [name: string]: unknown;
                };
                content?: never;
            };
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    updateKitchenItem: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description A kitchen item in the session's household. */
                itemId: components["parameters"]["ItemId"];
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["KitchenItemUpdate"];
            };
        };
        responses: {
            /** @description The updated item. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["KitchenItem"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            409: components["responses"]["Conflict"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    listIngredientSets: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description The ingredient sets. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["IngredientSetList"];
                };
            };
            401: components["responses"]["Unauthorized"];
            409: components["responses"]["Conflict"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    createIngredientSet: {
        parameters: {
            query?: never;
            header?: {
                /** @description A client-generated UUID. Repeating a request with the same key returns the first result instead of creating a duplicate, so an offline queue can replay safely. Reusing a key with a different body returns 409 `idempotency_key_reused`. Keys are kept for a configured period. */
                "Idempotency-Key"?: components["parameters"]["IdempotencyKey"];
            };
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["IngredientSetInput"];
            };
        };
        responses: {
            /** @description Created. */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["IngredientSet"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            409: components["responses"]["Conflict"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    replaceIngredientSet: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description An ingredient set in the session's household. */
                setId: components["parameters"]["SetId"];
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["IngredientSetInput"];
            };
        };
        responses: {
            /** @description The updated set. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["IngredientSet"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    deleteIngredientSet: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description An ingredient set in the session's household. */
                setId: components["parameters"]["SetId"];
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Deleted. */
            204: {
                headers: {
                    [name: string]: unknown;
                };
                content?: never;
            };
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    markIngredientSetAvailable: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description An ingredient set in the session's household. */
                setId: components["parameters"]["SetId"];
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description The set's items after the change. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["KitchenItemList"];
                };
            };
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    syncKitchen: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["KitchenSyncRequest"];
            };
        };
        responses: {
            /** @description The outcome of each change and the changes since the cursor. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["KitchenSyncResponse"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            409: components["responses"]["Conflict"];
            503: components["responses"]["ServiceUnavailable"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    listReferenceIngredients: {
        parameters: {
            query?: never;
            header?: {
                /** @description The `ETag` of the catalog the phone already has. */
                "If-None-Match"?: string;
            };
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description The catalog. */
            200: {
                headers: {
                    ETag: components["headers"]["ETag"];
                    "Cache-Control": components["headers"]["CacheControl"];
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ReferenceIngredientCatalog"];
                };
            };
            /** @description The phone's copy is current (its `If-None-Match` matches); no body. */
            304: {
                headers: {
                    ETag: components["headers"]["ETag"];
                    "Cache-Control": components["headers"]["CacheControl"];
                    [name: string]: unknown;
                };
                content?: never;
            };
            401: components["responses"]["Unauthorized"];
            503: components["responses"]["ServiceUnavailable"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    searchReferenceIngredients: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["IngredientSearchRequest"];
            };
        };
        responses: {
            /** @description The matching ingredients, best first. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["IngredientSearchResult"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            503: components["responses"]["ServiceUnavailable"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    listStandardAllergens: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description The standard allergens. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["StandardAllergenList"];
                };
            };
            401: components["responses"]["Unauthorized"];
            default: components["responses"]["UnexpectedError"];
        };
    };
}
