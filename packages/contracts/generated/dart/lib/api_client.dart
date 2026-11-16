//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class ApiClient {
  ApiClient({this.basePath = 'http://localhost:3000', this.authentication,});

  final String basePath;
  final Authentication? authentication;

  var _client = Client();
  final _defaultHeaderMap = <String, String>{};

  /// Returns the current HTTP [Client] instance to use in this class.
  ///
  /// The return value is guaranteed to never be null.
  Client get client => _client;

  /// Requests to use a new HTTP [Client] in this class.
  set client(Client newClient) {
    _client = newClient;
  }

  Map<String, String> get defaultHeaderMap => _defaultHeaderMap;

  void addDefaultHeader(String key, String value) {
     _defaultHeaderMap[key] = value;
  }

  // We don't use a Map<String, String> for queryParams.
  // If collectionFormat is 'multi', a key might appear multiple times.
  Future<Response> invokeAPI(
    String path,
    String method,
    List<QueryParam> queryParams,
    Object? body,
    Map<String, String> headerParams,
    Map<String, String> formParams,
    String? contentType, {
    Future<void>? abortTrigger,
  }) async {
    await authentication?.applyToParams(queryParams, headerParams);

    headerParams.addAll(_defaultHeaderMap);
    if (contentType != null) {
      headerParams['Content-Type'] = contentType;
    }

    final urlEncodedQueryParams = queryParams.map((param) => '$param');
    final queryString = urlEncodedQueryParams.isNotEmpty ? '?${urlEncodedQueryParams.join('&')}' : '';
    final uri = Uri.parse('$basePath$path$queryString');

    try {
      // Special case for uploading a single file which isn't a 'multipart/form-data'.
      if (
        body is MultipartFile && (contentType == null ||
        !contentType.toLowerCase().startsWith('multipart/form-data'))
      ) {
        final request = AbortableStreamedRequest(method, uri, abortTrigger: abortTrigger);
        request.headers.addAll(headerParams);
        request.contentLength = body.length;
        body.finalize().listen(
          request.sink.add,
          onDone: request.sink.close,
          // ignore: avoid_types_on_closure_parameters
          onError: (Object error, StackTrace trace) => request.sink.close(),
          cancelOnError: true,
        );
        final response = await _client.send(request);
        return Response.fromStream(response);
      }

      if (body is MultipartRequest) {
        final request = AbortableMultipartRequest(method, uri, abortTrigger: abortTrigger);
        request.fields.addAll(body.fields);
        request.files.addAll(body.files);
        request.headers.addAll(body.headers);
        request.headers.addAll(headerParams);
        final response = await _client.send(request);
        return Response.fromStream(response);
      }

      final msgBody = contentType == 'application/x-www-form-urlencoded'
        ? formParams
        : await serializeAsync(body);
      final nullableHeaderParams = headerParams.isEmpty ? null : headerParams;

      final request = AbortableRequest(method, uri, abortTrigger: abortTrigger);
      if (nullableHeaderParams != null) {
        request.headers.addAll(nullableHeaderParams);
      }
      if (msgBody is String && msgBody.isNotEmpty) {
        request.body = msgBody;
      } else if (msgBody is List<int> && msgBody.isNotEmpty) {
        request.bodyBytes = msgBody;
      } else if (msgBody is Map<String, String>) {
        request.bodyFields = msgBody;
      }
      final response = await _client.send(request);
      return Response.fromStream(response);
    } on SocketException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'Socket operation failed: $method $path',
        error,
        trace,
      );
    } on TlsException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'TLS/SSL communication failed: $method $path',
        error,
        trace,
      );
    } on IOException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'I/O operation failed: $method $path',
        error,
        trace,
      );
    } on ClientException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'HTTP connection failed: $method $path',
        error,
        trace,
      );
    } on Exception catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'Exception occurred: $method $path',
        error,
        trace,
      );
    }
  }

  Future<dynamic> deserializeAsync(String value, String targetType, {bool growable = false,}) async =>
    // ignore: deprecated_member_use_from_same_package
    deserialize(value, targetType, growable: growable);

  @Deprecated('Scheduled for removal in OpenAPI Generator 6.x. Use deserializeAsync() instead.')
  dynamic deserialize(String value, String targetType, {bool growable = false,}) {
    // Remove all spaces. Necessary for regular expressions as well.
    targetType = targetType.replaceAll(' ', ''); // ignore: parameter_assignments

    // If the expected target type is String, nothing to do...
    return targetType == 'String'
      ? value
      : fromJson(json.decode(value), targetType, growable: growable);
  }

  // ignore: deprecated_member_use_from_same_package
  Future<String> serializeAsync(Object? value) async => serialize(value);

  @Deprecated('Scheduled for removal in OpenAPI Generator 6.x. Use serializeAsync() instead.')
  String serialize(Object? value) => value == null ? '' : json.encode(value);

  /// Returns a native instance of an OpenAPI class matching the [specified type][targetType].
  static dynamic fromJson(dynamic value, String targetType, {bool growable = false,}) {
    try {
      switch (targetType) {
        case 'String':
          return value is String ? value : value.toString();
        case 'int':
          return value is int ? value : int.parse('$value');
        case 'double':
          return value is double ? value : double.parse('$value');
        case 'bool':
          if (value is bool) {
            return value;
          }
          final valueString = '$value'.toLowerCase();
          return valueString == 'true' || valueString == '1';
        case 'DateTime':
          return value is DateTime ? value : DateTime.tryParse(value);
        case 'Account':
          return Account.fromJson(value);
        case 'AccountRole':
          return AccountRoleTypeTransformer().decode(value);
        case 'AdaptationInfo':
          return AdaptationInfo.fromJson(value);
        case 'AgeGroup':
          return AgeGroupTypeTransformer().decode(value);
        case 'AiAvailability':
          return AiAvailabilityTypeTransformer().decode(value);
        case 'AppliedVariant':
          return AppliedVariant.fromJson(value);
        case 'Avatar':
          return Avatar.fromJson(value);
        case 'AvatarStyle':
          return AvatarStyleTypeTransformer().decode(value);
        case 'CatalogBrand':
          return CatalogBrand.fromJson(value);
        case 'CatalogIngredient':
          return CatalogIngredient.fromJson(value);
        case 'ConsentAudience':
          return ConsentAudienceTypeTransformer().decode(value);
        case 'ConsentDecision':
          return ConsentDecisionTypeTransformer().decode(value);
        case 'ConsentPurpose':
          return ConsentPurposeTypeTransformer().decode(value);
        case 'ConsentRecord':
          return ConsentRecord.fromJson(value);
        case 'ConsentRecordList':
          return ConsentRecordList.fromJson(value);
        case 'ConsentText':
          return ConsentText.fromJson(value);
        case 'ConsentTextSection':
          return ConsentTextSection.fromJson(value);
        case 'CookedMeal':
          return CookedMeal.fromJson(value);
        case 'CookedMealInput':
          return CookedMealInput.fromJson(value);
        case 'Cuisine':
          return CuisineTypeTransformer().decode(value);
        case 'DeviceInfo':
          return DeviceInfo.fromJson(value);
        case 'DevicePlatform':
          return DevicePlatformTypeTransformer().decode(value);
        case 'EaterMode':
          return EaterModeTypeTransformer().decode(value);
        case 'EaterSelection':
          return EaterSelection.fromJson(value);
        case 'ErrorCode':
          return ErrorCodeTypeTransformer().decode(value);
        case 'ExpectedConsentState':
          return ExpectedConsentState.fromJson(value);
        case 'FieldError':
          return FieldError.fromJson(value);
        case 'FieldErrorCode':
          return FieldErrorCodeTypeTransformer().decode(value);
        case 'FoodRef':
          return FoodRef.fromJson(value);
        case 'FoodRefInput':
          return FoodRefInput.fromJson(value);
        case 'FoodRefKind':
          return FoodRefKindTypeTransformer().decode(value);
        case 'GoogleSignIn':
          return GoogleSignIn.fromJson(value);
        case 'GuardianConfirmation':
          return GuardianConfirmation.fromJson(value);
        case 'GuardianConfirmationInput':
          return GuardianConfirmationInput.fromJson(value);
        case 'HalalStatus':
          return HalalStatusTypeTransformer().decode(value);
        case 'HardRule':
          return HardRule.fromJson(value);
        case 'HardRuleCreate':
          return HardRuleCreate.fromJson(value);
        case 'HardRuleMapping':
          return HardRuleMapping.fromJson(value);
        case 'HardRuleMappingConfirmation':
          return HardRuleMappingConfirmation.fromJson(value);
        case 'HardRuleType':
          return HardRuleTypeTypeTransformer().decode(value);
        case 'HealthDataConsentDecision':
          return HealthDataConsentDecision.fromJson(value);
        case 'HealthDataConsentWithdrawal':
          return HealthDataConsentWithdrawal.fromJson(value);
        case 'HiddenNotSafe':
          return HiddenNotSafe.fromJson(value);
        case 'Household':
          return Household.fromJson(value);
        case 'HouseholdCreate':
          return HouseholdCreate.fromJson(value);
        case 'HouseholdUpdate':
          return HouseholdUpdate.fromJson(value);
        case 'IngredientQuantity':
          return IngredientQuantity.fromJson(value);
        case 'IngredientSearchHit':
          return IngredientSearchHit.fromJson(value);
        case 'IngredientSearchRequest':
          return IngredientSearchRequest.fromJson(value);
        case 'IngredientSearchResult':
          return IngredientSearchResult.fromJson(value);
        case 'IngredientSet':
          return IngredientSet.fromJson(value);
        case 'IngredientSetInput':
          return IngredientSetInput.fromJson(value);
        case 'IngredientSetList':
          return IngredientSetList.fromJson(value);
        case 'KitchenAvailability':
          return KitchenAvailabilityTypeTransformer().decode(value);
        case 'KitchenBrand':
          return KitchenBrand.fromJson(value);
        case 'KitchenBrandInput':
          return KitchenBrandInput.fromJson(value);
        case 'KitchenCategory':
          return KitchenCategoryTypeTransformer().decode(value);
        case 'KitchenChange':
          return KitchenChange.fromJson(value);
        case 'KitchenChangeOperation':
          return KitchenChangeOperationTypeTransformer().decode(value);
        case 'KitchenChangeOutcome':
          return KitchenChangeOutcomeTypeTransformer().decode(value);
        case 'KitchenChangeResult':
          return KitchenChangeResult.fromJson(value);
        case 'KitchenIngredientKey':
          return KitchenIngredientKey.fromJson(value);
        case 'KitchenItem':
          return KitchenItem.fromJson(value);
        case 'KitchenItemCreate':
          return KitchenItemCreate.fromJson(value);
        case 'KitchenItemList':
          return KitchenItemList.fromJson(value);
        case 'KitchenItemState':
          return KitchenItemStateTypeTransformer().decode(value);
        case 'KitchenItemUpdate':
          return KitchenItemUpdate.fromJson(value);
        case 'KitchenMatch':
          return KitchenMatch.fromJson(value);
        case 'KitchenQuantity':
          return KitchenQuantityTypeTransformer().decode(value);
        case 'KitchenSyncRequest':
          return KitchenSyncRequest.fromJson(value);
        case 'KitchenSyncResponse':
          return KitchenSyncResponse.fromJson(value);
        case 'Language':
          return LanguageTypeTransformer().decode(value);
        case 'LessOf':
          return LessOfTypeTransformer().decode(value);
        case 'LibraryRecipeListItem':
          return LibraryRecipeListItem.fromJson(value);
        case 'LibraryRegionList':
          return LibraryRegionList.fromJson(value);
        case 'LibrarySearchRequest':
          return LibrarySearchRequest.fromJson(value);
        case 'LibrarySearchResult':
          return LibrarySearchResult.fromJson(value);
        case 'LikesDislikes':
          return LikesDislikes.fromJson(value);
        case 'LikesDislikesInput':
          return LikesDislikesInput.fromJson(value);
        case 'LocalizedText':
          return LocalizedText.fromJson(value);
        case 'ManagerProfileCreate':
          return ManagerProfileCreate.fromJson(value);
        case 'MappedIngredient':
          return MappedIngredient.fromJson(value);
        case 'MappingConfirmer':
          return MappingConfirmerTypeTransformer().decode(value);
        case 'MappingStatus':
          return MappingStatusTypeTransformer().decode(value);
        case 'MealFeedbackInput':
          return MealFeedbackInput.fromJson(value);
        case 'MealRating':
          return MealRatingTypeTransformer().decode(value);
        case 'MealType':
          return MealTypeTypeTransformer().decode(value);
        case 'MemberMealFeedback':
          return MemberMealFeedback.fromJson(value);
        case 'MemberMealRating':
          return MemberMealRatingTypeTransformer().decode(value);
        case 'MemberSafetyResult':
          return MemberSafetyResult.fromJson(value);
        case 'MissingIngredient':
          return MissingIngredient.fromJson(value);
        case 'NoSafeRecipe':
          return NoSafeRecipe.fromJson(value);
        case 'NutrientCode':
          return NutrientCodeTypeTransformer().decode(value);
        case 'NutrientRange':
          return NutrientRange.fromJson(value);
        case 'NutrientUnit':
          return NutrientUnitTypeTransformer().decode(value);
        case 'NutritionPerServing':
          return NutritionPerServing.fromJson(value);
        case 'NutritionStatus':
          return NutritionStatusTypeTransformer().decode(value);
        case 'PhotoSession':
          return PhotoSession.fromJson(value);
        case 'PhotoSessionStatus':
          return PhotoSessionStatusTypeTransformer().decode(value);
        case 'PortionSize':
          return PortionSizeTypeTransformer().decode(value);
        case 'Portions':
          return Portions.fromJson(value);
        case 'Problem':
          return Problem.fromJson(value);
        case 'Profile':
          return Profile.fromJson(value);
        case 'ProfileCreate':
          return ProfileCreate.fromJson(value);
        case 'ProfileList':
          return ProfileList.fromJson(value);
        case 'ProfileRules':
          return ProfileRules.fromJson(value);
        case 'ProfileUpdate':
          return ProfileUpdate.fromJson(value);
        case 'RecipeDetail':
          return RecipeDetail.fromJson(value);
        case 'RecipeDetailRequest':
          return RecipeDetailRequest.fromJson(value);
        case 'RecipeDifficulty':
          return RecipeDifficultyTypeTransformer().decode(value);
        case 'RecipeHalalStatus':
          return RecipeHalalStatus.fromJson(value);
        case 'RecipeImage':
          return RecipeImage.fromJson(value);
        case 'RecipeIngredientLine':
          return RecipeIngredientLine.fromJson(value);
        case 'RecipeOrigin':
          return RecipeOriginTypeTransformer().decode(value);
        case 'RecipeRegion':
          return RecipeRegion.fromJson(value);
        case 'RecipeSafety':
          return RecipeSafety.fromJson(value);
        case 'RecipeSpiceLevel':
          return RecipeSpiceLevelTypeTransformer().decode(value);
        case 'RecipeStep':
          return RecipeStep.fromJson(value);
        case 'RecipeSummary':
          return RecipeSummary.fromJson(value);
        case 'RecipeTags':
          return RecipeTags.fromJson(value);
        case 'RecipeTestRecord':
          return RecipeTestRecord.fromJson(value);
        case 'RecipeVariant':
          return RecipeVariant.fromJson(value);
        case 'RecognitionConfidence':
          return RecognitionConfidenceTypeTransformer().decode(value);
        case 'RecognitionConfirmation':
          return RecognitionConfirmation.fromJson(value);
        case 'RecognitionConfirmationItem':
          return RecognitionConfirmationItem.fromJson(value);
        case 'RecognitionConfirmationResult':
          return RecognitionConfirmationResult.fromJson(value);
        case 'RecognitionFailureReason':
          return RecognitionFailureReasonTypeTransformer().decode(value);
        case 'RecognitionOption':
          return RecognitionOption.fromJson(value);
        case 'RecognitionResult':
          return RecognitionResult.fromJson(value);
        case 'RecognizedItem':
          return RecognizedItem.fromJson(value);
        case 'ReferenceIngredientCatalog':
          return ReferenceIngredientCatalog.fromJson(value);
        case 'ReferenceVersions':
          return ReferenceVersions.fromJson(value);
        case 'RulesConsentState':
          return RulesConsentState.fromJson(value);
        case 'RulesConsentStatus':
          return RulesConsentStatusTypeTransformer().decode(value);
        case 'SafetyBrandRef':
          return SafetyBrandRef.fromJson(value);
        case 'SafetyComponentRef':
          return SafetyComponentRef.fromJson(value);
        case 'SafetyCondition':
          return SafetyCondition.fromJson(value);
        case 'SafetyConditionKind':
          return SafetyConditionKindTypeTransformer().decode(value);
        case 'SafetyConflict':
          return SafetyConflict.fromJson(value);
        case 'SafetyFinding':
          return SafetyFinding.fromJson(value);
        case 'SafetyIngredientRef':
          return SafetyIngredientRef.fromJson(value);
        case 'SafetyReason':
          return SafetyReason.fromJson(value);
        case 'SafetyReasonCode':
          return SafetyReasonCodeTypeTransformer().decode(value);
        case 'SafetyReasonKind':
          return SafetyReasonKindTypeTransformer().decode(value);
        case 'SafetyReportCreate':
          return SafetyReportCreate.fromJson(value);
        case 'SafetyReportReceipt':
          return SafetyReportReceipt.fromJson(value);
        case 'SafetyReportSubject':
          return SafetyReportSubject.fromJson(value);
        case 'SafetyReportType':
          return SafetyReportTypeTypeTransformer().decode(value);
        case 'SafetyRuleRef':
          return SafetyRuleRef.fromJson(value);
        case 'SafetyStatus':
          return SafetyStatusTypeTransformer().decode(value);
        case 'SafetySubjectKind':
          return SafetySubjectKindTypeTransformer().decode(value);
        case 'Session':
          return Session.fromJson(value);
        case 'SessionRefresh':
          return SessionRefresh.fromJson(value);
        case 'SessionTokens':
          return SessionTokens.fromJson(value);
        case 'SignInChannel':
          return SignInChannelTypeTransformer().decode(value);
        case 'SignInCodeChallenge':
          return SignInCodeChallenge.fromJson(value);
        case 'SignInCodeRequest':
          return SignInCodeRequest.fromJson(value);
        case 'SignInCodeVerification':
          return SignInCodeVerification.fromJson(value);
        case 'SignInMethod':
          return SignInMethodTypeTransformer().decode(value);
        case 'SoftPreferences':
          return SoftPreferences.fromJson(value);
        case 'SoftPreferencesInput':
          return SoftPreferencesInput.fromJson(value);
        case 'SpiceLevel':
          return SpiceLevelTypeTransformer().decode(value);
        case 'StandardAllergen':
          return StandardAllergenTypeTransformer().decode(value);
        case 'StandardAllergenList':
          return StandardAllergenList.fromJson(value);
        case 'SubstitutionLine':
          return SubstitutionLine.fromJson(value);
        case 'SubstitutionList':
          return SubstitutionList.fromJson(value);
        case 'SubstitutionOption':
          return SubstitutionOption.fromJson(value);
        case 'SubstitutionRequest':
          return SubstitutionRequest.fromJson(value);
        case 'SubstitutionSource':
          return SubstitutionSourceTypeTransformer().decode(value);
        case 'Suggestion':
          return Suggestion.fromJson(value);
        case 'SuggestionMoreRequest':
          return SuggestionMoreRequest.fromJson(value);
        case 'SuggestionRequest':
          return SuggestionRequest.fromJson(value);
        case 'SuggestionSet':
          return SuggestionSet.fromJson(value);
        case 'TexturePreference':
          return TexturePreferenceTypeTransformer().decode(value);
        case 'TimeAvailable':
          return TimeAvailableTypeTransformer().decode(value);
        case 'TradeOff':
          return TradeOff.fromJson(value);
        case 'TradeOffKind':
          return TradeOffKindTypeTransformer().decode(value);
        default:
          dynamic match;
          if (value is List && (match = _regList.firstMatch(targetType)?.group(1)) != null) {
            return value
              .map<dynamic>((dynamic v) => fromJson(v, match, growable: growable,))
              .toList(growable: growable);
          }
          if (value is Set && (match = _regSet.firstMatch(targetType)?.group(1)) != null) {
            return value
              .map<dynamic>((dynamic v) => fromJson(v, match, growable: growable,))
              .toSet();
          }
          if (value is Map && (match = _regMap.firstMatch(targetType)?.group(1)) != null) {
            return Map<String, dynamic>.fromIterables(
              value.keys.cast<String>(),
              value.values.map<dynamic>((dynamic v) => fromJson(v, match, growable: growable,)),
            );
          }
      }
    } on Exception catch (error, trace) {
      throw ApiException.withInner(HttpStatus.internalServerError, 'Exception during deserialization.', error, trace,);
    }
    throw ApiException(HttpStatus.internalServerError, 'Could not find a suitable class for deserialization',);
  }
}

/// Primarily intended for use in an isolate.
class DeserializationMessage {
  const DeserializationMessage({
    required this.json,
    required this.targetType,
    this.growable = false,
  });

  /// The JSON value to deserialize.
  final String json;

  /// Target type to deserialize to.
  final String targetType;

  /// Whether to make deserialized lists or maps growable.
  final bool growable;
}

/// Primarily intended for use in an isolate.
Future<dynamic> decodeAsync(DeserializationMessage message) async {
  // Remove all spaces. Necessary for regular expressions as well.
  final targetType = message.targetType.replaceAll(' ', '');

  // If the expected target type is String, nothing to do...
  return targetType == 'String'
    ? message.json
    : json.decode(message.json);
}

/// Primarily intended for use in an isolate.
Future<dynamic> deserializeAsync(DeserializationMessage message) async {
  // Remove all spaces. Necessary for regular expressions as well.
  final targetType = message.targetType.replaceAll(' ', '');

  // If the expected target type is String, nothing to do...
  return targetType == 'String'
    ? message.json
    : ApiClient.fromJson(
        json.decode(message.json),
        targetType,
        growable: message.growable,
      );
}

/// Primarily intended for use in an isolate.
Future<String> serializeAsync(Object? value) async => value == null ? '' : json.encode(value);
