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
         * @description One tap toggles available and out (KIT-02). Only the fields present are changed. The change is stamped with the server time and wins over any earlier change to the same ingredient (KIT-16); sending the same change again leaves the same result. `quantity` and `brand` are optional and may be null to clear them (KIT-09). A `brandId` must be one of the ingredient's catalog `brands` in the verified reference data (400 otherwise; 503 `reference_data_unavailable` without the data); only reference ingredients take one. A typed `customName` brand is kept as text and never counts as a recorded brand, so Cek Aman keeps "Check the label" for brand-varying ingredients (SAF-07).
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
         * @description KIT-16 offline sync. The phone sends the changes it queued while offline, oldest first, and the cursor of its last sync. Each change names its ingredient (a reference ID or a custom name), so an item added offline needs no server ID. The server places each change on its own clock at the time it was made (now minus `ageMs`, so a phone with a wrong clock still orders correctly) and keeps, per ingredient, the latest change: an older change than the stored one is `superseded` and the stored item is returned. Every change has a `changeId`; sending it again returns its first result without applying it twice, so replaying the queue is safe. Change IDs belong to the household and are kept for a configured period; the same ID with a different change is `rejected` with `idempotency_key_reused`. A change rejected for a reason that can pass (`reference_data_unavailable`, `kitchen_item_limit_reached`) is not remembered: send it again later with the same `changeId`. Each change is dated at the server's time minus its `ageMs`, never later. An `ageMs` below 0 or older than the server's limit (at most 30 days) is `rejected` with `validation_failed`, on its own. A removal is kept too: a change older than the removal is `superseded`, so an old queued change cannot bring an item back, and a change that would add an item but is older than the removals the server still keeps is `superseded` as well. The response carries every item changed or removed since the cursor and a new cursor. When `cursor` is null, not issued by this server for this household, or older than the kept removals, the response has all items and `full: true`; it never carries another household's data. A rejected change (for example an unknown ingredient, a name or brand that cannot be stored, or the item limit) never stops the rest. A request without the schema's shape is refused whole with 400.
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
    "/v1/reference/versions": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get the current rule set, reference data and library versions
         * @description The versions every safety result is computed with (DAT-06, SAF-14): the Cek Aman rule set, the verified reference ingredient data and the recipe library. The phone compares them with the versions stored on its cached safety results; a cached result made with older versions is checked again the next time the recipe is opened online, and the phone refreshes within `refreshWithinHours` (SAF-13, 24 hours target, from configuration). Content changes reach phones without an app release (NFR-20). When the reference data is not loaded or fails verification the answer is 503 `reference_data_unavailable`. Sending the `ETag` back in `If-None-Match` answers 304 with no body while the versions are unchanged.
         */
        get: operations["getReferenceVersions"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/library/recipes/search": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Browse and search the recipe library for the selected eaters
         * @description Lists published library recipes (LIB-08): with no `query` and no filters it is the browse list; `query` matches recipe names and ingredient names, local names included; `regionIds`, `mealTypes` and `timeAvailable` filter. Only published recipes with a recorded tester and test date are ever served (LIB-01). Every item carries a completed Cek Aman result for exactly the selected eaters (SAF-02, PRF-11); an item Cek Aman could not check is left out, never returned without a result. Recipes that are Not safe for a selected member are left out and counted in `hiddenNotSafe` unless `includeNotSafe` is true; when included they carry their Not safe result, never a softer one. The query travels in the body, so it never appears in a URL or an access log, and is never stored. Pages follow `nextCursor`; a cursor works only with the same request body (400 otherwise). A selected member that is not in the household answers 404 `not_found`. When a member's rules cannot be read the answer is 503 `rules_unavailable`, and without verified reference data or library it is 503 `reference_data_unavailable`, never an unchecked list. Works with every AI service down (AI-08).
         */
        post: operations["searchLibraryRecipes"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/library/regions": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * List the regions the library filters by
         * @description The regions published recipes come from, with their display names from the content team, for the region filter (LIB-08) and regional variants (LIB-04). Content data, not a fixed list in the app.
         */
        get: operations["listLibraryRegions"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/library/images/{imageId}": {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description A library recipe image. */
                imageId: components["parameters"]["ImageId"];
            };
            cookie?: never;
        };
        /**
         * Get a library recipe image
         * @description The image bytes of a published recipe image (LIB-03, SUG-09). Recipe images are food photos from the content team, never photos of people. Images are addressed by ID and never change, so the phone may keep them; `If-None-Match` answers 304. No JSON schema in this contract carries an image, a URL or a link.
         */
        get: operations["getLibraryImage"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/library/recipes/{recipeId}/detail": {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description A library recipe (stable across its versions). */
                recipeId: components["parameters"]["RecipeId"];
            };
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Open a recipe for the selected eaters
         * @description The recipe screen (CKM-01): ingredients with what is in the kitchen and what is missing, steps with timers, time, servings scaled to the eaters' portions (SUG-16), the halal status from Cek Aman's ingredient data (LIB-05) and the per-member Cek Aman result for exactly the selected eaters (SAF-02, SAF-04, SAF-05, PRF-11). It is a POST because the request names who is eating and every check is logged with its rule set and data versions (SAF-14); it changes no household data. The recipe is returned whatever its result, so the manager can see why it is Not safe; there is no way to override that result (SAF-12). `adaptationId` opens the adapted version a suggestion returned (LIB-06); the server keeps it for a configured time, then answers 409 `adaptation_expired` and the client opens the library recipe instead. `substitutionIds` and `variantId` apply checked substitutions and variants (SAF-11, CKM-09): the whole recipe is checked again with them, and one that is not offered for these eaters answers 409 `substitution_not_available`. A recipe that is not published (or retired) answers 404 `not_found`. 503 `rules_unavailable` or `reference_data_unavailable` when Cek Aman cannot run; the recipe is never returned without a result. With every AI service down the library recipe, its result and content-team substitutions still work (AI-08).
         */
        post: operations["getRecipeDetail"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/library/recipes/{recipeId}/substitutions": {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description A library recipe (stable across its versions). */
                recipeId: components["parameters"]["RecipeId"];
            };
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * List checked substitutions and variants for the selected eaters
         * @description Ingredient substitutions (CKM-09) and content-team variants such as "serve Kakak's portion before adding terasi" (SAF-11), each with its own Cek Aman result for exactly the selected eaters (SAF-02, AI-01). An option that would be Not safe for any selected member, or that could not be checked, is never listed; it is counted in `hiddenCount`. Where the content team defined none, none is offered. Options suggested by AI are only listed when AI is available and pass the same check; with AI down the content-team options still work (AI-08). Using an option re-checks the whole recipe through `getRecipeDetail`. 409 `adaptation_expired`, 404 `not_found` and the 503 codes as for `getRecipeDetail`.
         */
        post: operations["listRecipeSubstitutions"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/household/suggestions": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Get three suggestions for who is eating, the meal and the time
         * @description Masak Apa Hari Ini (SUG-01, SUG-02): up to three suggestions from the household's saved kitchen (sync queued changes first, KIT-16), the selected eaters (PRF-09, PRF-11), the meal type, the time available and the cuisine (Indonesian in V1, SUG-03). Ranking favors the most available and fewest missing ingredients (SUG-05), avoids recent dishes and repeated main proteins (SUG-07, window from configuration) and follows the eaters' likes, dislikes and feedback (SUG-08); every hard rule is met first, then soft preferences, with any trade-off in one line (PRF-12). Every suggestion passes Cek Aman for exactly the selected eaters before it is returned; one that is Not safe for any of them is replaced, not returned (SUG-04, SAF-02). An AI adaptation is made after the library pick and checked again (LIB-06, AI-01); with AI off or down the library recipes are used (AI-08, `aiAvailability`). `onlyWhatIHave` keeps recipes with zero missing ingredients (SUG-12). Fewer than three items means fewer passed. When none passes, `noSafeRecipe` says so and lists the closest checked options and the conflicts (SUG-17). Missing ingredients are a plain list to copy; there are no shopping lists (SUG-10). Answered within the SUG-13 target (5 s at p90, from configuration). 503 `rules_unavailable` or `reference_data_unavailable` when Cek Aman cannot run: no suggestion is ever returned without a completed result.
         */
        post: operations["requestSuggestions"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/household/suggestions/{suggestionSetId}/more": {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description A suggestion set of the session's household. */
                suggestionSetId: components["parameters"]["SuggestionSetId"];
            };
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Show three other suggestions for the same inputs
         * @description "Tampilkan 3 lainnya" (SUG-11): the next page for the same inputs, never repeating an item shown earlier in the set. Asking for the same `page` again returns the same items, so a retry is safe. Each page is checked by Cek Aman when it is served (SUG-04). When the pool is used up `poolExhausted` is true. A set is kept for a configured time; after that the answer is 409 `suggestion_set_expired` and the client asks again with `requestSuggestions`.
         */
        post: operations["requestMoreSuggestions"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/household/meals/{mealId}": {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description A cooked meal of the session's household. The phone makes it (a random UUID in lower case) when cooking ends, so the record can be sent again safely. */
                mealId: components["parameters"]["MealId"];
            };
            cookie?: never;
        };
        get?: never;
        /**
         * Record a cooked meal and its feedback
         * @description The cooked-meal record (QUESTIONS #19) written when cooking ends (CKM-10), with the one-tap household feedback and optional per-person feedback (PRF-13). The phone makes `mealId` (a random UUID) when cooking ends and sends the whole record each time, so the offline queue can replay it safely; the latest record replaces the earlier one. Meal IDs belong to the household. Feedback and recent meals adjust ranking for the household and the people who ate from the next request on (PRF-14, SUG-07, SUG-08). Every eater and rated member must be in the household (404 `not_found` otherwise); a rating for someone who did not eat is 400. Kept for the configured meal-history retention (DAT-04, QUESTIONS #19). No nutrition is recorded in V1.
         */
        put: operations["recordCookedMeal"];
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/household/safety-reports": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Report a wrong Cek Aman result
         * @description From the recipe screen (SAF-15). The report names the recipe, the check it is about (`checkId`, with the rule set and data versions, SAF-14), the members it concerns and what is wrong. The server stores only the members' rule types from that check, never their names, and the content team reviews it in the admin queue. A report never changes a result on any phone. It may be queued offline: send an `Idempotency-Key`. The note is optional, short, and the app asks not to put personal details in it. Rate-limited (429).
         */
        post: operations["createSafetyReport"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/admin/reference/ingredient-drafts": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * List reference ingredient drafts
         * @description Drafts of ingredient data changes, newest first, optionally by status (INT-15, SAF-13).
         */
        get: operations["listIngredientDrafts"];
        put?: never;
        /**
         * Start a draft change to the ingredient data
         * @description A content editor proposes a new ingredient, a change to one, or its retirement (SAF-06, SAF-07, SAF-13). The content is validated against the reference ingredient schema (400 `validation_failed` with pointers into `content`). Nothing reaches Cek Aman until a second person approves it and it is published in a reference release (two-step approval, QUESTIONS #20). Every change is attributed to the staff member and versioned (DAT-06). Values come from the content team; this API never fills them in.
         */
        post: operations["createIngredientDraft"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/admin/reference/ingredient-drafts/{draftId}": {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description A staff draft of reference data or of a recipe. */
                draftId: components["parameters"]["DraftId"];
            };
            cookie?: never;
        };
        /** Get an ingredient draft */
        get: operations["getIngredientDraft"];
        /**
         * Replace an ingredient draft's content
         * @description Only the author, and only while the draft is `draft` or `rejected` (409 `draft_not_editable` otherwise). `expectedRevision` is the revision the editor started from; a newer one answers 409 `draft_changed`. Editing a rejected draft returns it to `draft`.
         */
        put: operations["updateIngredientDraft"];
        post?: never;
        /**
         * Discard an ingredient draft
         * @description The author discards a draft that is not approved yet (409 `draft_not_editable` otherwise). It is kept as `discarded` for the audit trail.
         */
        delete: operations["discardIngredientDraft"];
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/admin/reference/ingredient-drafts/{draftId}/submit": {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description A staff draft of reference data or of a recipe. */
                draftId: components["parameters"]["DraftId"];
            };
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Send an ingredient draft for review
         * @description The author sends a valid draft to a safety reviewer (`in_review`). A draft with validation errors answers 400; a newer revision 409 `draft_changed`.
         */
        post: operations["submitIngredientDraft"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/admin/reference/ingredient-drafts/{draftId}/decision": {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description A staff draft of reference data or of a recipe. */
                draftId: components["parameters"]["DraftId"];
            };
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Approve or reject an ingredient draft
         * @description The second step of the two-step approval (QUESTIONS #20): a safety reviewer who is not the author approves or rejects a draft in review. The author answers 409 `second_person_required`. An approved change goes live with the next reference release, which records the new data version (SAF-13, DAT-06, T-050); a rejected one goes back to the author with the note.
         */
        post: operations["decideIngredientDraft"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/admin/library-images": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Upload a recipe image
         * @description A content editor uploads a food photo for a recipe (LIB-03, LIB-11). Never a photo of a person. The server strips metadata, stores a fixed-size copy and returns its ID for `AdminRecipeContent.imageIds`. Size and dimension limits come from configuration (400 otherwise).
         */
        post: operations["uploadLibraryImage"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/admin/recipes": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * List library recipes with their versions
         * @description Published and retired library recipes (LIB-11), newest change first.
         */
        get: operations["listAdminRecipes"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/admin/recipes/{recipeId}": {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description A library recipe (stable across its versions). */
                recipeId: components["parameters"]["RecipeId"];
            };
            cookie?: never;
        };
        /** Get a library recipe with every published version */
        get: operations["getAdminRecipe"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/admin/recipes/{recipeId}/retire": {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description A library recipe (stable across its versions). */
                recipeId: components["parameters"]["RecipeId"];
            };
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Retire a library recipe
         * @description Takes a published recipe out of the library without an app release (LIB-11): it is no longer searched, suggested or opened (404 for households). Its versions stay for the audit trail and the safety log. A newer version than `expectedVersion` answers 409 `draft_changed`.
         */
        post: operations["retireRecipe"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/admin/recipe-drafts": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * List recipe drafts
         * @description Drafts of new recipes and new recipe versions, newest first, optionally by status (LIB-11).
         */
        get: operations["listRecipeDrafts"];
        put?: never;
        /**
         * Start a new recipe or a new version of one
         * @description A content editor drafts a new library recipe, or a new version of a published one (`recipeId`), with the LIB-03 fields, regional variant link (LIB-04), and content-team substitutions and variants (SAF-11). Halal status and nutrition are never entered: halal comes from Cek Aman's ingredient data (LIB-05) and nutrition from the reviewed calculation (T-042). A draft is never served to households.
         */
        post: operations["createRecipeDraft"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/admin/recipe-drafts/{draftId}": {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description A staff draft of reference data or of a recipe. */
                draftId: components["parameters"]["DraftId"];
            };
            cookie?: never;
        };
        /** Get a recipe draft */
        get: operations["getRecipeDraft"];
        /**
         * Replace a recipe draft's content
         * @description As for ingredient drafts: author only, while `draft` or `rejected`, with `expectedRevision` (409 `draft_not_editable`, 409 `draft_changed`). Changing the content clears a recorded test, which must be recorded again for the changed recipe (LIB-01).
         */
        put: operations["updateRecipeDraft"];
        post?: never;
        /**
         * Discard a recipe draft
         * @description The author discards a draft that is not published (409 `draft_not_editable` otherwise). It is kept as `discarded` for the audit trail.
         */
        delete: operations["discardRecipeDraft"];
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/admin/recipe-drafts/{draftId}/test-record": {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description A staff draft of reference data or of a recipe. */
                draftId: components["parameters"]["DraftId"];
            };
            cookie?: never;
        };
        get?: never;
        /**
         * Record the cook's test of a recipe draft
         * @description A content editor records who tested this exact draft revision in a real kitchen and when (LIB-01, NFR-23), from the cook's sign-off. Staff accounts only: no household client, service or AI can call it, and a recipe is never published without this record and a second person's approval. It records a fact; it never marks anything safe.
         */
        put: operations["recordRecipeTest"];
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/admin/recipe-drafts/{draftId}/submit": {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description A staff draft of reference data or of a recipe. */
                draftId: components["parameters"]["DraftId"];
            };
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Send a recipe draft for review
         * @description The author sends a valid draft for approval (`in_review`). It needs a test record for the current revision (409 `recipe_not_tested`) and every ingredient line resolved to a reference ingredient (409 `recipe_ingredients_unresolved`); a newer revision answers 409 `draft_changed`.
         */
        post: operations["submitRecipeDraft"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/admin/recipe-drafts/{draftId}/decision": {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description A staff draft of reference data or of a recipe. */
                draftId: components["parameters"]["DraftId"];
            };
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Approve and publish, or reject, a recipe draft
         * @description A safety reviewer who is not the author (409 `second_person_required`, QUESTIONS #81) approves or rejects a draft in review. Approval publishes it as the recipe's next version at once, without an app release (LIB-11, NFR-20); households get it on their next request, each check recording the recipe version (DAT-06). Approval needs the test record (409 `recipe_not_tested`, LIB-01).
         */
        post: operations["decideRecipeDraft"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/admin/safety-reports": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * List wrong-result reports for review
         * @description The content team's review queue (SAF-15), oldest open report first. Reports show rule types and pseudonymous member labels, never names, household or member IDs.
         */
        get: operations["listSafetyReports"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/admin/safety-reports/{reportId}": {
        parameters: {
            query?: never;
            header?: never;
            path: {
                reportId: components["parameters"]["ReportId"];
            };
            cookie?: never;
        };
        /** Get one wrong-result report */
        get: operations["getSafetyReport"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/admin/safety-reports/{reportId}/review": {
        parameters: {
            query?: never;
            header?: never;
            path: {
                reportId: components["parameters"]["ReportId"];
            };
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Confirm or reject a wrong-result report
         * @description A safety reviewer marks an open report confirmed or rejected and may name the fix (for example an ingredient draft). A confirmed report adds a case to the Cek Aman regression suite (NFR-07). A reviewed report answers 409 `report_already_reviewed`. Reviewing changes no safety result: only a published data or rule-set change does.
         */
        post: operations["reviewSafetyReport"];
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
        ErrorCode: "validation_failed" | "code_invalid" | "code_expired" | "code_attempts_exceeded" | "unauthenticated" | "access_token_expired" | "refresh_token_invalid" | "google_token_invalid" | "forbidden" | "not_found" | "household_required" | "household_exists" | "profile_limit_reached" | "manager_profile_not_deletable" | "guardian_confirmation_required" | "consent_required" | "consent_text_outdated" | "consent_not_active" | "consent_changed" | "manager_profile_must_be_adult" | "hard_rule_duplicate" | "mapping_not_applicable" | "idempotency_key_reused" | "kitchen_item_limit_reached" | "ingredient_set_limit_reached" | "adaptation_expired" | "substitution_not_available" | "suggestion_set_expired" | "draft_changed" | "draft_not_editable" | "second_person_required" | "recipe_not_tested" | "recipe_ingredients_unresolved" | "report_already_reviewed" | "rate_limited" | "rules_unavailable" | "reference_data_unavailable" | "sign_in_method_unavailable" | "service_unavailable" | "internal_error";
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
            /** @description KIT-06: 1 is the most used item in its category. A use is a change of state (it ran out, or came back after being out), and older uses count less (configured half-life). Null when the item has no recent use; clients then fall back to their own order. */
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
            /** @description Milliseconds from the edit to sending this request, measured on the phone. The server dates the change at its own time minus this age (KIT-16), so the phone's clock setting does not matter, and never later. A negative age, or one older than the server's limit (at most 30 days, 2592000000), makes only this change `rejected` (`validation_failed`); the rest of the sync still applies. */
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
        /** @description Opaque page position issued by the server, never text a user typed. */
        PageCursor: string;
        /** @description DAT-06 versions in use now. `refreshWithinHours` is the SAF-13 target (24 hours, from configuration): phones refresh cached reference data and check cached safety results again within it. */
        ReferenceVersions: {
            /** @description Cek Aman rule-set version. */
            ruleSetVersion: string;
            /** @description Version and content hash of the verified reference ingredient data. */
            referenceVersion: string;
            /** @description Version of the published recipe library; changes whenever a recipe is published or retired. */
            libraryVersion: string;
            refreshWithinHours: number;
        };
        /**
         * @description PRF-09: `only_me` is the manager's own profile, `whole_family` every profile in the household, `selected` the profiles in `memberIds`.
         * @enum {string}
         */
        EaterMode: "only_me" | "whole_family" | "selected";
        /** @description Who is eating (PRF-09). Only these members' hard rules and preferences are used, for ranking and for Cek Aman (PRF-11). `memberIds` lists the profiles for `selected` (at least one) and is empty for the other modes. The request carries member IDs only: never rules, conditions or names. The server reads the members' rules itself. */
        EaterSelection: {
            mode: components["schemas"]["EaterMode"];
            memberIds: components["schemas"]["Id"][];
        };
        /**
         * @description SAF-04 per-member result from Cek Aman, the only component that assigns one (SAF-01). Clients render it and never compute, upgrade or default it. An unknown value means no result: the item is hidden, never shown as safe.
         * @enum {string}
         */
        SafetyStatus: "safe" | "not_safe" | "check_label";
        /**
         * @description `contains` and `component` come with `not_safe`; the other kinds with `check_label`. The member's `status` always decides the badge.
         * @enum {string}
         */
        SafetyReasonKind: "contains" | "component" | "unknown" | "brand_uncertain" | "unmapped_rule";
        /**
         * @description Reason codes from the Cek Aman engine (`packages/cek-aman`). Like `ErrorCode`, codes may be added: a client that does not know a code still renders the member's `status` and shows the generic missing-data line, and never hides a Not safe result or shows it as safe. Until the app decodes unknown codes that way, new codes come with a version bump (QUESTIONS #82).
         * @enum {string}
         */
        SafetyReasonCode: "allergen_contains" | "halal_not_halal" | "diet_not_suitable" | "excluded_ingredient" | "no_ingredients" | "ingredient_unresolved" | "ingredient_not_in_reference" | "components_unverified" | "component_not_in_reference" | "component_cycle" | "allergens_unverified" | "allergen_may_contain" | "allergen_related" | "allergen_unrecognized" | "halal_uncertain" | "diet_uncertain" | "brand_not_recorded" | "brand_unverified" | "component_brand_varies" | "rule_unmapped" | "rule_mapping_unconfirmed" | "rule_mapping_unknown_ingredient" | "rule_invalid";
        /** @description The member's hard rule a reason is about, for the rule label ("alergi udang", "aturan halal"). `freeText` is the rule's own text for `free_text` and `medical_exclusion` rules, shown only to the household. Never a member name. */
        SafetyRuleRef: {
            ruleId: components["schemas"]["Id"];
            type: components["schemas"]["HardRuleType"];
            allergen: components["schemas"]["StandardAllergen"] | null;
            freeText: string | null;
        };
        /** @description The recipe ingredient a reason is about. `displayName` is the localized reference name (QUESTIONS #44), null for an unresolved or custom ingredient, which shows `rawName`. `lineId` points at the ingredient line of the recipe, or of the replacement for a substitution; null when the reason is not about one line. */
        SafetyIngredientRef: {
            lineId: components["schemas"]["Id"] | null;
            ingredientId: components["schemas"]["ReferenceId"] | null;
            displayName: components["schemas"]["LocalizedText"] | null;
            rawName: string;
            /** @description A custom ingredient from Dapur Saya (KIT-05); shown with the custom-ingredient reason. */
            isCustom: boolean;
        };
        /** @description A hidden component, for example the shrimp inside terasi (SAF-03, SAF-06). */
        SafetyComponentRef: {
            ingredientId: components["schemas"]["ReferenceId"];
            displayName: components["schemas"]["LocalizedText"] | null;
        };
        /** @description The verified brand variant whose data Cek Aman used (SAF-07). */
        SafetyBrandRef: {
            brandId: components["schemas"]["ReferenceId"];
            name: string;
        };
        /** @description One reason from Cek Aman (SAF-04). For Not safe it names the ingredient, any hidden component (`componentPath`, from the recipe ingredient down to the one concerned) and the rule. For Check the label it gives the reason code. `ingredient` is null only for a reason about the rule itself or an empty ingredient list. `detail` is the allergen code, non-halal source, diet or excluded ingredient ID when relevant. */
        SafetyReason: {
            kind: components["schemas"]["SafetyReasonKind"];
            code: components["schemas"]["SafetyReasonCode"];
            rule: components["schemas"]["SafetyRuleRef"];
            ingredient: components["schemas"]["SafetyIngredientRef"] | null;
            componentPath: components["schemas"]["SafetyComponentRef"][];
            brand: components["schemas"]["SafetyBrandRef"] | null;
            detail: string | null;
        };
        /** @description One selected member's Cek Aman result, by member ID only, never a name (SAF-04, SAF-05). `rulesConsent` is the member's health-data consent state when the check ran (QUESTIONS #36, #48, #52): unless it is `given`, the member's rules were not checked and clients show the neutral "rules not saved" or "not filled in" chip, never Safe, whatever `status` says. A result without `rulesConsent`, or with a value the client does not know, is treated the same way. */
        MemberSafetyResult: {
            memberId: components["schemas"]["Id"];
            rulesConsent: components["schemas"]["RulesConsentStatus"];
            status: components["schemas"]["SafetyStatus"];
            /** @description Empty for `safe`; at least one for the other states. */
            reasons: components["schemas"]["SafetyReason"][];
        };
        /**
         * @description LIB-05 recipe halal status, derived by Cek Aman from its ingredient data, never from AI: `not_halal` when an ingredient or component is alcohol, pork or a non-halal animal; `check_label` when any item is uncertain or unverified (SAF-08). Not a per-member result. An unknown value hides the row; it is never shown as halal.
         * @enum {string}
         */
        HalalStatus: "halal" | "not_halal" | "check_label";
        /** @description A Cek Aman finding without a member rule: used for the recipe halal status and in the staff review queue. */
        SafetyFinding: {
            kind: components["schemas"]["SafetyReasonKind"];
            code: components["schemas"]["SafetyReasonCode"];
            ingredient: components["schemas"]["SafetyIngredientRef"] | null;
            componentPath: components["schemas"]["SafetyComponentRef"][];
            brand: components["schemas"]["SafetyBrandRef"] | null;
            detail: string | null;
        };
        RecipeHalalStatus: {
            status: components["schemas"]["HalalStatus"];
            /** @description The ingredients behind `not_halal` or `check_label`; empty for `halal`. */
            findings: components["schemas"]["SafetyFinding"][];
        };
        /** @description The completed Cek Aman result for one food item (SAF-02). Required on every food item the API returns: an item without one is never returned. `members` holds exactly the selected eaters, in the order of the selection, and nobody else (PRF-11). `checkId` names the logged check with its rule set and data versions (SAF-14, DAT-06); a wrong-result report quotes it. The phone may cache the result with the recipe (CKM-07) and must check again when any version changes or a selected member's rules or consent change. */
        RecipeSafety: {
            checkId: components["schemas"]["Id"];
            /** Format: date-time */
            checkedAt: string;
            ruleSetVersion: string;
            referenceVersion: string;
            members: components["schemas"]["MemberSafetyResult"][];
            halalStatus: components["schemas"]["RecipeHalalStatus"];
        };
        /**
         * @description SUG-02 meal types. `sahur` and `buka` are plain meal types in V1 with no Ramadan logic (QUESTIONS #25).
         * @enum {string}
         */
        MealType: "breakfast" | "lunch" | "dinner" | "snack" | "sahur" | "buka";
        /**
         * @description SUG-02 time available, in minutes. `over_60` has no upper limit.
         * @enum {string}
         */
        TimeAvailable: "up_to_15" | "up_to_30" | "up_to_60" | "over_60";
        /**
         * @description SUG-03. V1 serves `indonesian` only; a request for another cuisine answers 400 until V3 adds those collections (LIB-10).
         * @enum {string}
         */
        Cuisine: "indonesian" | "japanese" | "chinese" | "fusion";
        /** @enum {string} */
        RecipeDifficulty: "easy" | "medium" | "hard";
        /**
         * @description LIB-03 spice level tag of a recipe.
         * @enum {string}
         */
        RecipeSpiceLevel: "not_spicy" | "medium" | "spicy";
        /**
         * @description Where the recipe text comes from. `library`: a published library recipe. `adapted_library`: a library recipe adapted for these eaters (LIB-06), labeled "Diadaptasi". `family` (Resep Keluarga) and `generated` (AI-02, labeled as generated) are not served in V1. Only `library` may be presented as a tested recipe (LIB-07); clients treat an unknown value like `generated`.
         * @enum {string}
         */
        RecipeOrigin: "library" | "adapted_library" | "family" | "generated";
        /** @description A region of the library (LIB-04, LIB-08); names come from the content team. */
        RecipeRegion: {
            regionId: components["schemas"]["ReferenceId"];
            displayName: components["schemas"]["LocalizedText"];
        };
        LibraryRegionList: {
            libraryVersion: string;
            items: components["schemas"]["RecipeRegion"][];
        };
        /** @description LIB-03 tags. Not safety data and not health claims. */
        RecipeTags: {
            fried: boolean;
            santan: boolean;
            spiceLevel: components["schemas"]["RecipeSpiceLevel"];
        };
        /** @description A food photo or illustration from the content team, fetched with `getLibraryImage`. */
        RecipeImage: {
            imageId: components["schemas"]["Id"];
            width: number;
            height: number;
            alt: components["schemas"]["LocalizedText"];
        };
        /** @description LIB-01, NFR-23: the Indonesian cook's test of this recipe version, recorded by staff in the admin tool. `testedBy` is the label the content team publishes for the tester (QUESTIONS #79). Clients show "Resep teruji" only for `origin: library` with this record; it never means safe. */
        RecipeTestRecord: {
            testedBy: string;
            /** Format: date */
            testedOn: string;
        };
        /** @description LIB-03 fields of a recipe as a card or list row shows them. Content only: the API returns it only inside a food item that carries its Cek Aman result. `version` changes with every published change (LIB-11, DAT-06). `testRecord` belongs to the library version: for `adapted_library` it is the base recipe's test, not a test of the adapted text (LIB-07). `baseRecipeId` links a regional variant to its base dish (LIB-04). `totalMinutes` is prep plus cook time. */
        RecipeSummary: {
            recipeId: components["schemas"]["ReferenceId"];
            version: number;
            name: components["schemas"]["LocalizedText"];
            description: components["schemas"]["LocalizedText"];
            cuisine: components["schemas"]["Cuisine"];
            region: components["schemas"]["RecipeRegion"] | null;
            mealTypes: components["schemas"]["MealType"][];
            prepMinutes: number;
            cookMinutes: number;
            totalMinutes: number;
            difficulty: components["schemas"]["RecipeDifficulty"];
            /** @description Servings the quantities are written for. */
            baseServings: number;
            tags: components["schemas"]["RecipeTags"];
            /** @description First image first; empty when the recipe has none (the app shows an illustration). */
            images: components["schemas"]["RecipeImage"][];
            origin: components["schemas"]["RecipeOrigin"];
            testRecord: components["schemas"]["RecipeTestRecord"] | null;
            baseRecipeId: components["schemas"]["ReferenceId"] | null;
        };
        /** @description LIB-03 quantity and unit. `amount` is null for "to taste" (secukupnya). `unitCode` and `unitLabel` come from the content team's unit list (local measures follow QUESTIONS #10). Amounts scale linearly with servings on the phone (CKM-05). */
        IngredientQuantity: {
            amount: number | null;
            unitCode: string | null;
            unitLabel: components["schemas"]["LocalizedText"] | null;
        };
        /**
         * @description CKM-01: whether the household's saved kitchen has the ingredient ("Ada" or "Belum ada"). Clients treat an unknown value as `missing`.
         * @enum {string}
         */
        KitchenAvailability: "available" | "missing";
        /** @description One ingredient line, with quantities for `servings` of the item it belongs to. `ingredientId` is null for a line that does not resolve to a reference ingredient, which Cek Aman treats as unknown (Check the label, SAF-09). */
        RecipeIngredientLine: {
            lineId: components["schemas"]["Id"];
            ingredientId: components["schemas"]["ReferenceId"] | null;
            displayName: components["schemas"]["LocalizedText"] | null;
            /** @description The name as written in the recipe. */
            rawName: string;
            quantity: components["schemas"]["IngredientQuantity"];
            isOptional: boolean;
            /** @description A group heading such as "Bumbu halus", or null. */
            groupLabel: components["schemas"]["LocalizedText"] | null;
            inKitchen: components["schemas"]["KitchenAvailability"];
        };
        /** @description One step (CKM-02). `timerSeconds` offers a timer (CKM-03). `ingredientLineIds` are the lines the step uses (CKM-06). */
        RecipeStep: {
            stepId: components["schemas"]["Id"];
            text: components["schemas"]["LocalizedText"];
            timerSeconds: number | null;
            ingredientLineIds: components["schemas"]["Id"][];
        };
        /** @description SUG-10: an ingredient the kitchen does not have, for the note the user can copy as plain text. No quantity, price or shop: there are no shopping lists. */
        MissingIngredient: {
            lineId: components["schemas"]["Id"];
            ingredientId: components["schemas"]["ReferenceId"] | null;
            displayName: components["schemas"]["LocalizedText"] | null;
            rawName: string;
        };
        /** @description SUG-05, SUG-09, CKM-01: how the recipe fits the saved kitchen. Optional lines are not counted as missing. */
        KitchenMatch: {
            availableCount: number;
            missingCount: number;
            missing: components["schemas"]["MissingIngredient"][];
        };
        /**
         * @description NUT-04 nutrients.
         * @enum {string}
         */
        NutrientCode: "energy" | "protein" | "carbohydrate" | "fat" | "saturated_fat" | "fiber" | "sugar" | "sodium";
        /** @enum {string} */
        NutrientUnit: "kcal" | "g" | "mg";
        /**
         * @description `estimate`: ranges from the reviewed calculation, always labeled "perkiraan" (estimate). `unavailable`: no reviewed values, shown as "nutrition unavailable" or not at all. V1 always sends `unavailable` and the app shows no nutrition (QUESTIONS #15). Clients treat an unknown value as `unavailable`.
         * @enum {string}
         */
        NutritionStatus: "estimate" | "unavailable";
        /** @description NUT-05: a range, never a single number; `high` is greater than `low`. Values come only from the reviewed nutrition calculation (T-042), never from AI and never entered by hand in this API. */
        NutrientRange: {
            nutrient: components["schemas"]["NutrientCode"];
            low: number;
            high: number;
            unit: components["schemas"]["NutrientUnit"];
        };
        /** @description LIB-03 nutrition per serving as estimate ranges (NUT-05). `ranges` is empty when `status` is `unavailable`. No calorie targets, no per-person judgement (NUT-19, NUT-20). */
        NutritionPerServing: {
            status: components["schemas"]["NutritionStatus"];
            ranges: components["schemas"]["NutrientRange"][];
        };
        /** @description LIB-08 browse and search. All filters are optional; together they narrow the list. `query` matches names and ingredients (local names included) and is never stored or logged; hidden or control characters are refused (400). `timeAvailable` keeps recipes whose total time fits. */
        LibrarySearchRequest: {
            eaters: components["schemas"]["EaterSelection"];
            query?: string;
            regionIds?: components["schemas"]["ReferenceId"][];
            mealTypes?: components["schemas"]["MealType"][];
            timeAvailable?: components["schemas"]["TimeAvailable"];
            /** @description Also list recipes that are Not safe for a selected member, with that result ("Tampilkan"). Default false. */
            includeNotSafe?: boolean;
            cursor?: components["schemas"]["PageCursor"] | null;
            /** @description Items per page (default and upper limit from configuration). */
            limit?: number;
        };
        /** @description A library recipe with its Cek Aman result for the selected eaters. */
        LibraryRecipeListItem: {
            recipe: components["schemas"]["RecipeSummary"];
            safety: components["schemas"]["RecipeSafety"];
        };
        /** @description Recipes left out because they are Not safe for a selected member (`library.hiddenNotSafe`): how many and for whom. Zero when `includeNotSafe` was true. */
        HiddenNotSafe: {
            count: number;
            memberIds: components["schemas"]["Id"][];
        };
        LibrarySearchResult: {
            /** @description Best match first; empty when nothing matched. */
            items: components["schemas"]["LibraryRecipeListItem"][];
            nextCursor: components["schemas"]["PageCursor"] | null;
            /** @description Matching recipes that are listed (hidden ones not counted). */
            totalCount: number;
            hiddenNotSafe: components["schemas"]["HiddenNotSafe"];
            libraryVersion: string;
        };
        /** @description Who is eating, and optionally the adaptation, substitutions or variant to open the recipe with. The response quantities are for servings scaled to the eaters; the phone rescales them (CKM-05). */
        RecipeDetailRequest: {
            eaters: components["schemas"]["EaterSelection"];
            /** @description The `adaptation.adaptationId` a suggestion returned (LIB-06). */
            adaptationId?: components["schemas"]["Id"];
            /** @description Checked substitutions to use (SAF-11, CKM-09), from `listRecipeSubstitutions`. */
            substitutionIds?: components["schemas"]["Id"][];
            /** @description A checked content-team variant (SAF-11). */
            variantId?: components["schemas"]["Id"];
        };
        /** @description LIB-06: the recipe was adapted (scaled, substituted or simplified) and is labeled "Diadaptasi", with one line per change ("Disesuaikan: {change}"). `aiAdapted` is true when the AI service made the change; the adapted recipe went through Cek Aman again like any other (AI-01). Change lines never state a safety result. `adaptationId` and `expiresAt` are set for an AI adaptation the server keeps for a configured time. */
        AdaptationInfo: {
            adaptationId: components["schemas"]["Id"] | null;
            aiAdapted: boolean;
            changes: components["schemas"]["LocalizedText"][];
            /** Format: date-time */
            expiresAt: string | null;
        };
        /** @description SAF-11: a content-team variant in use, for example "Pisahkan porsi {names} sebelum menambah terasi". The app fills `{names}` from `separatedMemberIds`; those members' portion is set aside before `separateBeforeStepId`, and Cek Aman checked their portion without the ingredients added from that step on. */
        AppliedVariant: {
            variantId: components["schemas"]["Id"];
            label: components["schemas"]["LocalizedText"];
            separatedMemberIds: components["schemas"]["Id"][];
            separateBeforeStepId: components["schemas"]["Id"];
        };
        /**
         * @description PRF-12 trade-off templates (`suggest.tradeoff.*`). A hard rule is never a trade-off. Clients show no line for an unknown value.
         * @enum {string}
         */
        TradeOffKind: "spice_separate" | "less_santan" | "not_fried" | "less_salt" | "less_sugar" | "dislike_skipped" | "other";
        /** @description PRF-12: the one line explaining how the eaters' soft preferences were balanced. `memberIds` are the members the change is for (for `spice_separate`, those who get it mild) and `otherMemberIds` the others (sambal on the side). `ingredient` is set for `dislike_skipped`; `text` for `other`. Never a safety word. */
        TradeOff: {
            kind: components["schemas"]["TradeOffKind"];
            memberIds: components["schemas"]["Id"][];
            otherMemberIds: components["schemas"]["Id"][];
            ingredient: components["schemas"]["LocalizedText"] | null;
            text: components["schemas"]["LocalizedText"] | null;
        };
        /**
         * @description AI-08: `available`; `off` (the household has not turned AI features on, SET-09); `unavailable` (down, out of quota or too slow, so only library recipes and content-team options are used). Never affects a safety result. Clients treat an unknown value as `unavailable`.
         * @enum {string}
         */
        AiAvailability: "available" | "off" | "unavailable";
        /** @description The recipe screen (CKM-01) for the selected eaters. `servings` is scaled to the eaters' portion sizes (SUG-16) and the ingredient quantities are for it. `regionalVariants` are the other regional versions of the dish (LIB-04), each with its own result. `appliedSubstitutionIds` lists the substitutions in use. */
        RecipeDetail: {
            recipe: components["schemas"]["RecipeSummary"];
            ingredients: components["schemas"]["RecipeIngredientLine"][];
            steps: components["schemas"]["RecipeStep"][];
            servings: number;
            kitchenMatch: components["schemas"]["KitchenMatch"];
            safety: components["schemas"]["RecipeSafety"];
            adaptation: components["schemas"]["AdaptationInfo"] | null;
            variant: components["schemas"]["AppliedVariant"] | null;
            appliedSubstitutionIds: components["schemas"]["Id"][];
            regionalVariants: components["schemas"]["LibraryRecipeListItem"][];
            nutritionPerServing: components["schemas"]["NutritionPerServing"];
            tradeOff: components["schemas"]["TradeOff"] | null;
            aiAvailability: components["schemas"]["AiAvailability"];
        };
        SubstitutionRequest: {
            eaters: components["schemas"]["EaterSelection"];
            /** @description Substitutions for the adapted version a suggestion returned. */
            adaptationId?: components["schemas"]["Id"];
        };
        /**
         * @description `content_team`: defined and reviewed by the content team (QUESTIONS #21). `ai`: proposed by the AI service and then checked by Cek Aman like any other option (AI-01); never a safety verdict.
         * @enum {string}
         */
        SubstitutionSource: "content_team" | "ai";
        /** @description One substitution for an ingredient line (CKM-09). `safety` is the Cek Aman result of the replacement ingredients for the selected eaters; an option that is Not safe for any of them is never listed. `removesConflictFor` are the members whose Not safe result for the recipe goes away with this option, as Cek Aman found by checking the whole recipe with it (QUESTIONS #83). Quantities are for the item's servings. */
        SubstitutionOption: {
            substitutionId: components["schemas"]["Id"];
            lineId: components["schemas"]["Id"];
            source: components["schemas"]["SubstitutionSource"];
            replacements: components["schemas"]["RecipeIngredientLine"][];
            /** @description One line on how it changes the dish, from content. */
            effectNote: components["schemas"]["LocalizedText"] | null;
            removesConflictFor: components["schemas"]["Id"][];
            safety: components["schemas"]["RecipeSafety"];
        };
        SubstitutionLine: {
            lineId: components["schemas"]["Id"];
            options: components["schemas"]["SubstitutionOption"][];
        };
        /** @description SAF-11: a content-team variant ("Cara lain"), with the Cek Aman result of the whole recipe cooked that way for the selected eaters. Listed only when it is not Not safe for any of them. */
        RecipeVariant: {
            variant: components["schemas"]["AppliedVariant"];
            safety: components["schemas"]["RecipeSafety"];
        };
        SubstitutionList: {
            recipeId: components["schemas"]["ReferenceId"];
            recipeVersion: number;
            /** @description Only lines that have at least one listed option. */
            lines: components["schemas"]["SubstitutionLine"][];
            variants: components["schemas"]["RecipeVariant"][];
            /** @description Options left out because they are Not safe or could not be checked (`subs.hidden`). */
            hiddenCount: number;
            aiAvailability: components["schemas"]["AiAvailability"];
        };
        /** @description SUG-02 inputs. The available ingredients are the household's saved kitchen. `cuisine` defaults to `indonesian` (SUG-03). `onlyWhatIHave` keeps recipes with no missing ingredient (SUG-12). Member IDs only: never rules, conditions or names. */
        SuggestionRequest: {
            eaters: components["schemas"]["EaterSelection"];
            mealType: components["schemas"]["MealType"];
            timeAvailable: components["schemas"]["TimeAvailable"];
            cuisine?: components["schemas"]["Cuisine"];
            onlyWhatIHave?: boolean;
        };
        SuggestionMoreRequest: {
            /** @description The page wanted; the first "Show others" asks for page 2. */
            page: number;
        };
        /** @description A suggestion card (SUG-09): dish, image, time, servings scaled to the eaters' portions (SUG-16), kitchen match with the missing ingredients (SUG-10), the per-member Cek Aman result (SAF-05), and the trade-off line (PRF-12). `adaptation` is set for an adapted recipe (LIB-06) and `variant` when the card is the recipe cooked with a checked variant (SAF-11). `withinTimeAvailable` is false only for a closest option that needs more time (SUG-17). */
        Suggestion: {
            itemId: components["schemas"]["Id"];
            recipe: components["schemas"]["RecipeSummary"];
            servings: number;
            kitchenMatch: components["schemas"]["KitchenMatch"];
            safety: components["schemas"]["RecipeSafety"];
            tradeOff: components["schemas"]["TradeOff"] | null;
            adaptation: components["schemas"]["AdaptationInfo"] | null;
            variant: components["schemas"]["AppliedVariant"] | null;
            withinTimeAvailable: boolean;
        };
        /** @description SUG-17: why recipes were not safe, as a text line ("Udang (alergi Kakak)"), never as a recipe card (QUESTIONS #28). From the Cek Aman results of the recipes that were left out. */
        SafetyConflict: {
            memberId: components["schemas"]["Id"];
            rule: components["schemas"]["SafetyRuleRef"];
            ingredient: components["schemas"]["SafetyIngredientRef"];
            componentPath: components["schemas"]["SafetyComponentRef"][];
        };
        /** @description SUG-17: no recipe passed Cek Aman for the selected eaters with these inputs. `closestOptions` passed Cek Aman for every selected eater (Safe or Check the label) but need missing ingredients or more time, or are a checked variant; they are never Not safe recipes (QUESTIONS #28). Either list may be empty. */
        NoSafeRecipe: {
            closestOptions: components["schemas"]["Suggestion"][];
            conflicts: components["schemas"]["SafetyConflict"][];
        };
        /** @description One page of suggestions for a request (SUG-01). `items` has up to three; fewer means fewer passed Cek Aman. Empty `items` with `noSafeRecipe` set is the SUG-17 state; empty `items` without it and `onlyWhatIHave` true means nothing fits with only what the kitchen has (SUG-12). `poolExhausted` says "Show others" has nothing more. `memberIds` are the eaters the set was checked for, and `libraryVersion` the library it was ranked from (DAT-06). */
        SuggestionSet: {
            id: components["schemas"]["Id"];
            page: number;
            inputs: components["schemas"]["SuggestionRequest"];
            memberIds: components["schemas"]["Id"][];
            items: components["schemas"]["Suggestion"][];
            poolExhausted: boolean;
            noSafeRecipe: components["schemas"]["NoSafeRecipe"] | null;
            aiAvailability: components["schemas"]["AiAvailability"];
            libraryVersion: string;
            /**
             * Format: date-time
             * @description Until when "Show others" works for this set.
             */
            expiresAt: string;
        };
        /**
         * @description PRF-13 "Semua suka?": Ya, suka · Campur · Kurang suka.
         * @enum {string}
         */
        MealRating: "yes" | "mixed" | "no";
        /**
         * @description PRF-13 per person: Suka · Biasa · Kurang suka.
         * @enum {string}
         */
        MemberMealRating: "liked" | "ok" | "disliked";
        MemberMealFeedback: {
            memberId: components["schemas"]["Id"];
            rating: components["schemas"]["MemberMealRating"];
        };
        /** @description SRS 18.1 Feedback. `members` is optional per-person feedback, only for members who ate. */
        MealFeedbackInput: {
            overall: components["schemas"]["MealRating"];
            members: components["schemas"]["MemberMealFeedback"][];
        };
        /** @description SRS 18.1 Meal, minimal for V1 (QUESTIONS #19): what was cooked, when (the household's local date), for which meal, who ate and how many servings, and the feedback or null when skipped. No nutrition, no oil or santan answer in V1 (QUESTIONS #14, #15). */
        CookedMealInput: {
            recipeId: components["schemas"]["ReferenceId"];
            recipeVersion: number;
            adaptationId: components["schemas"]["Id"] | null;
            variantId: components["schemas"]["Id"] | null;
            substitutionIds: components["schemas"]["Id"][];
            /** Format: date */
            cookedOn: string;
            mealType: components["schemas"]["MealType"];
            eaterMemberIds: components["schemas"]["Id"][];
            servings: number;
            feedback: components["schemas"]["MealFeedbackInput"] | null;
        };
        CookedMeal: {
            id: components["schemas"]["Id"];
            recipeId: components["schemas"]["ReferenceId"];
            recipeVersion: number;
            adaptationId: components["schemas"]["Id"] | null;
            variantId: components["schemas"]["Id"] | null;
            substitutionIds: components["schemas"]["Id"][];
            /** Format: date */
            cookedOn: string;
            mealType: components["schemas"]["MealType"];
            eaterMemberIds: components["schemas"]["Id"][];
            servings: number;
            feedback: components["schemas"]["MealFeedbackInput"] | null;
            /** Format: date-time */
            createdAt: string;
            /** Format: date-time */
            updatedAt: string;
        };
        /**
         * @description SAF-02 kinds of food item a check is about, matching the Cek Aman safety log. V1 reports concern `library_recipe`, `suggestion` and `substitution`.
         * @enum {string}
         */
        SafetySubjectKind: "library_recipe" | "suggestion" | "substitution" | "taste_tweak_fix" | "planned_meal" | "family_recipe" | "leftover_remake";
        /**
         * @description What the user says is wrong (`report.type.*`).
         * @enum {string}
         */
        SafetyReportType: "marked_safe_wrong" | "marked_not_safe_wrong" | "check_label_wrong" | "wrong_ingredient" | "other";
        SafetyReportSubject: {
            kind: components["schemas"]["SafetySubjectKind"];
            recipeId: components["schemas"]["ReferenceId"];
            recipeVersion: number;
            adaptationId: components["schemas"]["Id"] | null;
            substitutionId: components["schemas"]["Id"] | null;
            variantId: components["schemas"]["Id"] | null;
        };
        /** @description SAF-15 with minimum data. `checkId`, `ruleSetVersion` and `referenceVersion` come from the `RecipeSafety` the user saw (cached ones included). The server keeps only the reported members' rule types from that check, never names or rule wording. `note` is optional; control characters are refused. */
        SafetyReportCreate: {
            subject: components["schemas"]["SafetyReportSubject"];
            checkId: components["schemas"]["Id"];
            ruleSetVersion: string;
            referenceVersion: string;
            /** @description The members the report is about, from the check's members. */
            memberIds: components["schemas"]["Id"][];
            reportType: components["schemas"]["SafetyReportType"];
            ingredientLineId: components["schemas"]["Id"] | null;
            note: string | null;
        };
        SafetyReportReceipt: {
            reportId: components["schemas"]["Id"];
            /** Format: date-time */
            receivedAt: string;
        };
        /**
         * @description Staff roles for the internal admin tool (INT-15, QUESTIONS #20). Operations list the roles they allow in `x-staff-roles`. Staff never read household data.
         * @enum {string}
         */
        StaffRole: "content_editor" | "safety_reviewer" | "nutrition_reviewer" | "admin";
        /**
         * @description `draft` (being edited) → `in_review` (sent for the second person) → `approved` (reference data waiting for a release) or `published` (live) · `rejected` (back to the author) · `discarded`. The admin tool treats an unknown value as not editable and not approvable.
         * @enum {string}
         */
        DraftStatus: "draft" | "in_review" | "approved" | "rejected" | "published" | "discarded";
        /** @enum {string} */
        DraftOperation: "create" | "update" | "retire";
        /** @enum {string} */
        DraftDecision: "approve" | "reject";
        /** @description The second person's decision. `reviewerStaffId` is never the author. */
        DraftReview: {
            decision: components["schemas"]["DraftDecision"];
            reviewerStaffId: components["schemas"]["Id"];
            /** Format: date-time */
            decidedAt: string;
            note: string | null;
        };
        DraftRevisionInput: {
            /** @description The draft revision the staff member was shown (409 `draft_changed` when it moved). */
            expectedRevision: number;
        };
        DraftDecisionInput: {
            expectedRevision: number;
            decision: components["schemas"]["DraftDecision"];
            /** @description Required when rejecting. */
            note: string | null;
        };
        /** @description One reference ingredient record exactly as `data/schema/ingredient.schema.json` defines it (components, allergens, halal, diet, brand variants). The server validates it against that schema; this contract does not repeat the schema, so the two cannot drift. Values are entered by the content team only. */
        IngredientDraftContent: {
            [key: string]: unknown;
        };
        /** @description `ingredientId` names the ingredient (for `create`, the new ID, which must equal `content.id`). `content` is required for `create` and `update` and absent for `retire`. */
        IngredientDraftCreate: {
            operation: components["schemas"]["DraftOperation"];
            ingredientId: components["schemas"]["ReferenceId"];
            content?: components["schemas"]["IngredientDraftContent"];
        };
        IngredientDraftUpdate: {
            expectedRevision: number;
            content: components["schemas"]["IngredientDraftContent"];
        };
        /** @description A staff draft of one ingredient change, attributed and versioned (DAT-06). `validationErrors` lists schema problems in `content` (pointers into it); a draft with errors cannot be submitted. */
        IngredientDraft: {
            id: components["schemas"]["Id"];
            operation: components["schemas"]["DraftOperation"];
            ingredientId: components["schemas"]["ReferenceId"];
            status: components["schemas"]["DraftStatus"];
            revision: number;
            content: components["schemas"]["IngredientDraftContent"] | null;
            /** @description The reference data version the draft was started from. */
            baseReferenceVersion: string;
            validationErrors: components["schemas"]["FieldError"][];
            authorStaffId: components["schemas"]["Id"];
            /** Format: date-time */
            createdAt: string;
            /** Format: date-time */
            updatedAt: string;
            /** Format: date-time */
            submittedAt: string | null;
            review: components["schemas"]["DraftReview"] | null;
            /** @description The release that published the change, once published. */
            publishedReferenceVersion: string | null;
        };
        IngredientDraftList: {
            items: components["schemas"]["IngredientDraft"][];
            nextCursor: components["schemas"]["PageCursor"] | null;
        };
        LibraryImage: {
            imageId: components["schemas"]["Id"];
            width: number;
            height: number;
        };
        /** @description A recipe ingredient line as the content team writes it. A line without `ingredientId` blocks submission (409 `recipe_ingredients_unresolved`), so every published line resolves. */
        AdminIngredientLine: {
            lineId: components["schemas"]["Id"];
            ingredientId: components["schemas"]["ReferenceId"] | null;
            rawName: string;
            quantity: components["schemas"]["IngredientQuantity"];
            isOptional: boolean;
            groupLabel: components["schemas"]["LocalizedText"] | null;
        };
        /** @description A content-team substitution for one line (SAF-11, CKM-09, QUESTIONS */
        AdminSubstitution: {
            substitutionId: components["schemas"]["Id"];
            lineId: components["schemas"]["Id"];
            replacements: components["schemas"]["AdminIngredientLine"][];
            effectNote: components["schemas"]["LocalizedText"] | null;
        };
        /** @description A content-team variant (SAF-11): a portion set aside before `separateBeforeStepId`, without `omittedLineIds`. `label` may hold a `{names}` placeholder the app fills in. */
        AdminRecipeVariant: {
            variantId: components["schemas"]["Id"];
            label: components["schemas"]["LocalizedText"];
            separateBeforeStepId: components["schemas"]["Id"];
            omittedLineIds: components["schemas"]["Id"][];
        };
        /** @description LIB-03 recipe content as the content team edits it. There is no halal field (derived by Cek Aman, LIB-05), no nutrition field (calculated and reviewed, T-042), no tested flag (only a test record, LIB-01) and no safety field. */
        AdminRecipeContent: {
            name: components["schemas"]["LocalizedText"];
            description: components["schemas"]["LocalizedText"];
            cuisine: components["schemas"]["Cuisine"];
            regionId: components["schemas"]["ReferenceId"] | null;
            mealTypes: components["schemas"]["MealType"][];
            baseServings: number;
            prepMinutes: number;
            cookMinutes: number;
            difficulty: components["schemas"]["RecipeDifficulty"];
            ingredients: components["schemas"]["AdminIngredientLine"][];
            steps: components["schemas"]["RecipeStep"][];
            tags: components["schemas"]["RecipeTags"];
            imageIds: components["schemas"]["Id"][];
            /** @description For a regional variant, the base dish (LIB-04). */
            baseRecipeId: components["schemas"]["ReferenceId"] | null;
            substitutions: components["schemas"]["AdminSubstitution"][];
            variants: components["schemas"]["AdminRecipeVariant"][];
        };
        /** @description LIB-01, NFR-23: who tested the recipe, when, and which staff member recorded it for which draft revision. */
        AdminRecipeTestRecord: {
            testedBy: string;
            /** Format: date */
            testedOn: string;
            notes: string | null;
            recordedByStaffId: components["schemas"]["Id"];
            /** Format: date-time */
            recordedAt: string;
            draftRevision: number;
        };
        /** @description The cook's test of the current draft revision. `testedOn` may not be in the future (400). */
        RecipeTestRecordInput: {
            expectedRevision: number;
            testedBy: string;
            /** Format: date */
            testedOn: string;
            notes?: string;
        };
        /** @description Omit `recipeId` for a new recipe; give it for a new version of a published one. */
        RecipeDraftCreate: {
            recipeId?: components["schemas"]["ReferenceId"];
            content: components["schemas"]["AdminRecipeContent"];
        };
        RecipeDraftUpdate: {
            expectedRevision: number;
            content: components["schemas"]["AdminRecipeContent"];
        };
        RecipeDraft: {
            id: components["schemas"]["Id"];
            /** @description The recipe this draft becomes or changes. */
            recipeId: components["schemas"]["ReferenceId"];
            /** @description The published version a new version starts from; null for a new recipe. */
            baseVersion: number | null;
            status: components["schemas"]["DraftStatus"];
            revision: number;
            content: components["schemas"]["AdminRecipeContent"];
            validationErrors: components["schemas"]["FieldError"][];
            /** @description Null until recorded, and cleared when the content changes. */
            testRecord: components["schemas"]["AdminRecipeTestRecord"] | null;
            authorStaffId: components["schemas"]["Id"];
            /** Format: date-time */
            createdAt: string;
            /** Format: date-time */
            updatedAt: string;
            /** Format: date-time */
            submittedAt: string | null;
            review: components["schemas"]["DraftReview"] | null;
            publishedVersion: number | null;
        };
        RecipeDraftList: {
            items: components["schemas"]["RecipeDraft"][];
            nextCursor: components["schemas"]["PageCursor"] | null;
        };
        /** @enum {string} */
        RecipeLifecycleStatus: "published" | "retired";
        /** @description One published version, with its test record and approval (LIB-01, LIB-11, NFR-23). */
        AdminRecipeVersion: {
            version: number;
            /** Format: date-time */
            publishedAt: string;
            authorStaffId: components["schemas"]["Id"];
            approvedByStaffId: components["schemas"]["Id"];
            testRecord: components["schemas"]["AdminRecipeTestRecord"];
            content: components["schemas"]["AdminRecipeContent"];
            nutritionPerServing: components["schemas"]["NutritionPerServing"];
        };
        AdminRecipe: {
            recipeId: components["schemas"]["ReferenceId"];
            status: components["schemas"]["RecipeLifecycleStatus"];
            currentVersion: number;
            name: components["schemas"]["LocalizedText"];
            /** @description Newest first. */
            versions: components["schemas"]["AdminRecipeVersion"][];
            /** Format: date-time */
            retiredAt: string | null;
            retiredByStaffId: components["schemas"]["Id"] | null;
        };
        AdminRecipeListItem: {
            recipeId: components["schemas"]["ReferenceId"];
            status: components["schemas"]["RecipeLifecycleStatus"];
            currentVersion: number;
            name: components["schemas"]["LocalizedText"];
            /** Format: date-time */
            updatedAt: string;
        };
        AdminRecipeList: {
            items: components["schemas"]["AdminRecipeListItem"][];
            nextCursor: components["schemas"]["PageCursor"] | null;
        };
        RecipeRetireInput: {
            expectedVersion: number;
            note: string | null;
        };
        /**
         * @description Review state of a report. The admin tool treats an unknown value as `open`.
         * @enum {string}
         */
        SafetyReportStatus: "open" | "confirmed" | "rejected";
        /** @enum {string} */
        SafetyReportOutcome: "confirmed" | "rejected";
        /** @description A rule type, without its wording (QUESTIONS */
        AdminRuleSummary: {
            type: components["schemas"]["HardRuleType"];
            allergen: components["schemas"]["StandardAllergen"] | null;
        };
        /** @description A reported member as staff see them: a label local to the report (`m1`, `m2`), the logged result, rule types and findings. Never a name, member ID or household ID. `status` is null when the logged check is past its retention (DAT-05). */
        AdminReportMember: {
            memberLabel: string;
            status: components["schemas"]["SafetyStatus"] | null;
            rules: components["schemas"]["AdminRuleSummary"][];
            findings: components["schemas"]["SafetyFinding"][];
        };
        SafetyReportReview: {
            outcome: components["schemas"]["SafetyReportOutcome"];
            reviewerStaffId: components["schemas"]["Id"];
            /** Format: date-time */
            reviewedAt: string;
            note: string | null;
            /** @description What fixed it, for example an ingredient draft ID. */
            fixReference: string | null;
        };
        AdminSafetyReport: {
            id: components["schemas"]["Id"];
            /** Format: date-time */
            receivedAt: string;
            status: components["schemas"]["SafetyReportStatus"];
            subject: components["schemas"]["SafetyReportSubject"];
            reportType: components["schemas"]["SafetyReportType"];
            ingredient: components["schemas"]["SafetyIngredientRef"] | null;
            note: string | null;
            ruleSetVersion: string;
            referenceVersion: string;
            members: components["schemas"]["AdminReportMember"][];
            review: components["schemas"]["SafetyReportReview"] | null;
        };
        AdminSafetyReportList: {
            items: components["schemas"]["AdminSafetyReport"][];
            nextCursor: components["schemas"]["PageCursor"] | null;
        };
        SafetyReportReviewInput: {
            outcome: components["schemas"]["SafetyReportOutcome"];
            note: string | null;
            fixReference: string | null;
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
        /** @description A library recipe (stable across its versions). */
        RecipeId: components["schemas"]["ReferenceId"];
        /** @description A library recipe image. */
        ImageId: components["schemas"]["Id"];
        /** @description A suggestion set of the session's household. */
        SuggestionSetId: components["schemas"]["Id"];
        /** @description A cooked meal of the session's household. The phone makes it (a random UUID in lower case) when cooking ends, so the record can be sent again safely. */
        MealId: components["schemas"]["Id"];
        /** @description A staff draft of reference data or of a recipe. */
        DraftId: components["schemas"]["Id"];
        ReportId: components["schemas"]["Id"];
        /** @description The `ETag` of the copy the client already has. */
        IfNoneMatch: string;
        /** @description `nextCursor` of the previous page; absent for the first page. Opaque and issued by the server, never text a user typed. */
        Cursor: components["schemas"]["PageCursor"];
        /** @description Items per page (default and upper limit from configuration). */
        PageLimit: number;
        /** @description Only drafts in this state. */
        DraftStatusFilter: components["schemas"]["DraftStatus"];
        /** @description Only recipes in this state. */
        RecipeStatusFilter: components["schemas"]["RecipeLifecycleStatus"];
        /** @description Only reports in this state. */
        ReportStatusFilter: components["schemas"]["SafetyReportStatus"];
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
        /** @description `private, max-age=31536000, immutable`: an image ID never changes its bytes, so the phone may keep it. */
        ImageCacheControl: string;
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
    getReferenceVersions: {
        parameters: {
            query?: never;
            header?: {
                /** @description The `ETag` of the copy the client already has. */
                "If-None-Match"?: components["parameters"]["IfNoneMatch"];
            };
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description The current versions. */
            200: {
                headers: {
                    ETag: components["headers"]["ETag"];
                    "Cache-Control": components["headers"]["CacheControl"];
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ReferenceVersions"];
                };
            };
            /** @description Unchanged since the `If-None-Match` ETag; no body. */
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
    searchLibraryRecipes: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["LibrarySearchRequest"];
            };
        };
        responses: {
            /** @description One page of recipes, each with its Cek Aman result. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["LibrarySearchResult"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            409: components["responses"]["Conflict"];
            503: components["responses"]["ServiceUnavailable"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    listLibraryRegions: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description The regions. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["LibraryRegionList"];
                };
            };
            401: components["responses"]["Unauthorized"];
            503: components["responses"]["ServiceUnavailable"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    getLibraryImage: {
        parameters: {
            query?: never;
            header?: {
                /** @description The `ETag` of the copy the client already has. */
                "If-None-Match"?: components["parameters"]["IfNoneMatch"];
            };
            path: {
                /** @description A library recipe image. */
                imageId: components["parameters"]["ImageId"];
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description The image. */
            200: {
                headers: {
                    ETag: components["headers"]["ETag"];
                    "Cache-Control": components["headers"]["ImageCacheControl"];
                    [name: string]: unknown;
                };
                content: {
                    "image/webp": string;
                    "image/jpeg": string;
                };
            };
            /** @description The phone's copy is current; no body. */
            304: {
                headers: {
                    ETag: components["headers"]["ETag"];
                    "Cache-Control": components["headers"]["ImageCacheControl"];
                    [name: string]: unknown;
                };
                content?: never;
            };
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    getRecipeDetail: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description A library recipe (stable across its versions). */
                recipeId: components["parameters"]["RecipeId"];
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["RecipeDetailRequest"];
            };
        };
        responses: {
            /** @description The recipe with its Cek Aman result. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["RecipeDetail"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            409: components["responses"]["Conflict"];
            503: components["responses"]["ServiceUnavailable"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    listRecipeSubstitutions: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description A library recipe (stable across its versions). */
                recipeId: components["parameters"]["RecipeId"];
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["SubstitutionRequest"];
            };
        };
        responses: {
            /** @description The checked options. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SubstitutionList"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            409: components["responses"]["Conflict"];
            503: components["responses"]["ServiceUnavailable"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    requestSuggestions: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["SuggestionRequest"];
            };
        };
        responses: {
            /** @description The first page of suggestions. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SuggestionSet"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            409: components["responses"]["Conflict"];
            429: components["responses"]["TooManyRequests"];
            503: components["responses"]["ServiceUnavailable"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    requestMoreSuggestions: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description A suggestion set of the session's household. */
                suggestionSetId: components["parameters"]["SuggestionSetId"];
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["SuggestionMoreRequest"];
            };
        };
        responses: {
            /** @description The requested page. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SuggestionSet"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            409: components["responses"]["Conflict"];
            429: components["responses"]["TooManyRequests"];
            503: components["responses"]["ServiceUnavailable"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    recordCookedMeal: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description A cooked meal of the session's household. The phone makes it (a random UUID in lower case) when cooking ends, so the record can be sent again safely. */
                mealId: components["parameters"]["MealId"];
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["CookedMealInput"];
            };
        };
        responses: {
            /** @description The record was replaced. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["CookedMeal"];
                };
            };
            /** @description The record was created. */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["CookedMeal"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            409: components["responses"]["Conflict"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    createSafetyReport: {
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
                "application/json": components["schemas"]["SafetyReportCreate"];
            };
        };
        responses: {
            /** @description Received for review. */
            202: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SafetyReportReceipt"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            409: components["responses"]["Conflict"];
            429: components["responses"]["TooManyRequests"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    listIngredientDrafts: {
        parameters: {
            query?: {
                /** @description Only drafts in this state. */
                status?: components["parameters"]["DraftStatusFilter"];
                /** @description `nextCursor` of the previous page; absent for the first page. Opaque and issued by the server, never text a user typed. */
                cursor?: components["parameters"]["Cursor"];
                /** @description Items per page (default and upper limit from configuration). */
                limit?: components["parameters"]["PageLimit"];
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description One page of drafts. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["IngredientDraftList"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    createIngredientDraft: {
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
                "application/json": components["schemas"]["IngredientDraftCreate"];
            };
        };
        responses: {
            /** @description Draft created. */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["IngredientDraft"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            409: components["responses"]["Conflict"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    getIngredientDraft: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description A staff draft of reference data or of a recipe. */
                draftId: components["parameters"]["DraftId"];
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description The draft. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["IngredientDraft"];
                };
            };
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    updateIngredientDraft: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description A staff draft of reference data or of a recipe. */
                draftId: components["parameters"]["DraftId"];
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["IngredientDraftUpdate"];
            };
        };
        responses: {
            /** @description The updated draft. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["IngredientDraft"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            409: components["responses"]["Conflict"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    discardIngredientDraft: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description A staff draft of reference data or of a recipe. */
                draftId: components["parameters"]["DraftId"];
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Discarded. */
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
    submitIngredientDraft: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description A staff draft of reference data or of a recipe. */
                draftId: components["parameters"]["DraftId"];
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["DraftRevisionInput"];
            };
        };
        responses: {
            /** @description The draft, now in review. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["IngredientDraft"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            409: components["responses"]["Conflict"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    decideIngredientDraft: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description A staff draft of reference data or of a recipe. */
                draftId: components["parameters"]["DraftId"];
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["DraftDecisionInput"];
            };
        };
        responses: {
            /** @description The decided draft. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["IngredientDraft"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            409: components["responses"]["Conflict"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    uploadLibraryImage: {
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
                "image/webp": string;
                "image/jpeg": string;
            };
        };
        responses: {
            /** @description Stored. */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["LibraryImage"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    listAdminRecipes: {
        parameters: {
            query?: {
                /** @description Only recipes in this state. */
                status?: components["parameters"]["RecipeStatusFilter"];
                /** @description `nextCursor` of the previous page; absent for the first page. Opaque and issued by the server, never text a user typed. */
                cursor?: components["parameters"]["Cursor"];
                /** @description Items per page (default and upper limit from configuration). */
                limit?: components["parameters"]["PageLimit"];
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description One page of recipes. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["AdminRecipeList"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    getAdminRecipe: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description A library recipe (stable across its versions). */
                recipeId: components["parameters"]["RecipeId"];
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description The recipe. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["AdminRecipe"];
                };
            };
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    retireRecipe: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description A library recipe (stable across its versions). */
                recipeId: components["parameters"]["RecipeId"];
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["RecipeRetireInput"];
            };
        };
        responses: {
            /** @description The retired recipe. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["AdminRecipe"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            409: components["responses"]["Conflict"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    listRecipeDrafts: {
        parameters: {
            query?: {
                /** @description Only drafts in this state. */
                status?: components["parameters"]["DraftStatusFilter"];
                /** @description `nextCursor` of the previous page; absent for the first page. Opaque and issued by the server, never text a user typed. */
                cursor?: components["parameters"]["Cursor"];
                /** @description Items per page (default and upper limit from configuration). */
                limit?: components["parameters"]["PageLimit"];
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description One page of drafts. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["RecipeDraftList"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    createRecipeDraft: {
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
                "application/json": components["schemas"]["RecipeDraftCreate"];
            };
        };
        responses: {
            /** @description Draft created. */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["RecipeDraft"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            409: components["responses"]["Conflict"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    getRecipeDraft: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description A staff draft of reference data or of a recipe. */
                draftId: components["parameters"]["DraftId"];
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description The draft. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["RecipeDraft"];
                };
            };
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    updateRecipeDraft: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description A staff draft of reference data or of a recipe. */
                draftId: components["parameters"]["DraftId"];
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["RecipeDraftUpdate"];
            };
        };
        responses: {
            /** @description The updated draft. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["RecipeDraft"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            409: components["responses"]["Conflict"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    discardRecipeDraft: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description A staff draft of reference data or of a recipe. */
                draftId: components["parameters"]["DraftId"];
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Discarded. */
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
    recordRecipeTest: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description A staff draft of reference data or of a recipe. */
                draftId: components["parameters"]["DraftId"];
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["RecipeTestRecordInput"];
            };
        };
        responses: {
            /** @description The draft with its test record. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["RecipeDraft"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            409: components["responses"]["Conflict"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    submitRecipeDraft: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description A staff draft of reference data or of a recipe. */
                draftId: components["parameters"]["DraftId"];
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["DraftRevisionInput"];
            };
        };
        responses: {
            /** @description The draft, now in review. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["RecipeDraft"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            409: components["responses"]["Conflict"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    decideRecipeDraft: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description A staff draft of reference data or of a recipe. */
                draftId: components["parameters"]["DraftId"];
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["DraftDecisionInput"];
            };
        };
        responses: {
            /** @description The decided draft. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["RecipeDraft"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            409: components["responses"]["Conflict"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    listSafetyReports: {
        parameters: {
            query?: {
                /** @description Only reports in this state. */
                status?: components["parameters"]["ReportStatusFilter"];
                /** @description `nextCursor` of the previous page; absent for the first page. Opaque and issued by the server, never text a user typed. */
                cursor?: components["parameters"]["Cursor"];
                /** @description Items per page (default and upper limit from configuration). */
                limit?: components["parameters"]["PageLimit"];
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description One page of reports. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["AdminSafetyReportList"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    getSafetyReport: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                reportId: components["parameters"]["ReportId"];
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description The report. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["AdminSafetyReport"];
                };
            };
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            default: components["responses"]["UnexpectedError"];
        };
    };
    reviewSafetyReport: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                reportId: components["parameters"]["ReportId"];
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["SafetyReportReviewInput"];
            };
        };
        responses: {
            /** @description The reviewed report. */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["AdminSafetyReport"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            409: components["responses"]["Conflict"];
            default: components["responses"]["UnexpectedError"];
        };
    };
}
