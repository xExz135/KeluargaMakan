// Hard rules (PRF-03, PRF-04, PRF-08). Health data: online only, never
// cached on the phone (DAT-02). A rule list that cannot be read is a
// failure, never an empty list (QUESTIONS #39).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../../core/api/api_client.dart';
import '../../core/api/api_result.dart';
import '../decoders.dart';
import '../models/family.dart';

final class HardRulesRepository {
  HardRulesRepository({required this._caller, required api.ApiClient client})
    : _api = api.HardRulesApi(client);

  final ApiCaller _caller;
  final api.HardRulesApi _api;

  Future<ApiResult<MemberRules>> listHardRules(String profileId) =>
      _caller.call(
        'listHardRules',
        () => _api.listHardRulesWithHttpInfo(profileId),
        decodeRules,
      );

  /// Needs a current health-data consent (else `consent_required`). Reuse
  /// the same [idempotencyKey] when retrying.
  Future<ApiResult<api.HardRule>> createHardRule(
    String profileId,
    api.HardRuleCreate body, {
    required String idempotencyKey,
  }) => _caller.call(
    'createHardRule',
    () => _api.createHardRuleWithHttpInfo(
      profileId,
      withoutEmptyMapping(body),
      idempotencyKey: idempotencyKey,
    ),
    decodeWith(api.HardRule.fromJson, 'hard rule'),
  );

  Future<ApiResult<void>> deleteHardRule(String profileId, String ruleId) =>
      _caller.callNoContent(
        'deleteHardRule',
        () => _api.deleteHardRuleWithHttpInfo(profileId, ruleId),
      );

  Future<ApiResult<api.HardRule>> confirmHardRuleMapping(
    String profileId,
    String ruleId,
    List<String> ingredientIds,
  ) => _caller.call(
    'confirmHardRuleMapping',
    () => _api.confirmHardRuleMappingWithHttpInfo(
      profileId,
      ruleId,
      api.HardRuleMappingConfirmation(ingredientIds: ingredientIds.toSet()),
    ),
    decodeWith(api.HardRule.fromJson, 'hard rule'),
  );

  Future<ApiResult<api.HardRule>> rejectHardRuleMapping(
    String profileId,
    String ruleId,
  ) => _caller.call(
    'rejectHardRuleMapping',
    () => _api.rejectHardRuleMappingWithHttpInfo(profileId, ruleId),
    decodeWith(api.HardRule.fromJson, 'hard rule'),
  );
}

/// The generated `HardRuleCreate` defaults `mappedIngredientIds` to an empty
/// set and sends `[]`, which the contract rejects (`minItems: 1`). An empty
/// or null match is left out, so the rule is saved as `unmapped`.
api.HardRuleCreate withoutEmptyMapping(api.HardRuleCreate body) {
  final ids = body.mappedIngredientIds;
  if (ids.isPresent && (ids.value?.isNotEmpty ?? false)) return body;
  return api.HardRuleCreate(
    type: body.type,
    allergen: body.allergen,
    freeText: body.freeText,
    mappedIngredientIds: const api.Optional.absent(),
  );
}

final hardRulesRepositoryProvider = Provider<HardRulesRepository>(
  (ref) => HardRulesRepository(
    caller: ref.watch(apiCallerProvider),
    client: ref.watch(apiClientProvider),
  ),
);
