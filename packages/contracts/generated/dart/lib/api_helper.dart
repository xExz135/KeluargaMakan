//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class QueryParam {
  const QueryParam(this.name, this.value);

  final String name;
  final String value;

  @override
  String toString() => '${Uri.encodeQueryComponent(name)}=${Uri.encodeQueryComponent(value)}';
}

// Ported from the Java version.
Iterable<QueryParam> _queryParams(String collectionFormat, String name, dynamic value,) {
  // Assertions to run in debug mode only.
  assert(name.isNotEmpty, 'Parameter cannot be an empty string.');

  final params = <QueryParam>[];

  if (value is List) {
    if (collectionFormat == 'multi') {
      return value.map((dynamic v) => QueryParam(name, parameterToString(v)),);
    }

    // Default collection format is 'csv'.
    if (collectionFormat.isEmpty) {
      collectionFormat = 'csv'; // ignore: parameter_assignments
    }

    final delimiter = _delimiters[collectionFormat] ?? ',';

    params.add(QueryParam(name, value.map<dynamic>(parameterToString).join(delimiter),));
  } else if (value != null) {
    params.add(QueryParam(name, parameterToString(value)));
  }

  return params;
}

/// Format the given parameter object into a [String].
String parameterToString(dynamic value) {
  if (value == null) {
    return '';
  }
  if (value is DateTime) {
    return value.toUtc().toIso8601String();
  }
  if (value is AccountRole) {
    return AccountRoleTypeTransformer().encode(value).toString();
  }
  if (value is AgeGroup) {
    return AgeGroupTypeTransformer().encode(value).toString();
  }
  if (value is AiAvailability) {
    return AiAvailabilityTypeTransformer().encode(value).toString();
  }
  if (value is AvatarStyle) {
    return AvatarStyleTypeTransformer().encode(value).toString();
  }
  if (value is ConsentAudience) {
    return ConsentAudienceTypeTransformer().encode(value).toString();
  }
  if (value is ConsentDecision) {
    return ConsentDecisionTypeTransformer().encode(value).toString();
  }
  if (value is ConsentPurpose) {
    return ConsentPurposeTypeTransformer().encode(value).toString();
  }
  if (value is Cuisine) {
    return CuisineTypeTransformer().encode(value).toString();
  }
  if (value is DevicePlatform) {
    return DevicePlatformTypeTransformer().encode(value).toString();
  }
  if (value is DraftDecision) {
    return DraftDecisionTypeTransformer().encode(value).toString();
  }
  if (value is DraftOperation) {
    return DraftOperationTypeTransformer().encode(value).toString();
  }
  if (value is DraftStatus) {
    return DraftStatusTypeTransformer().encode(value).toString();
  }
  if (value is EaterMode) {
    return EaterModeTypeTransformer().encode(value).toString();
  }
  if (value is ErrorCode) {
    return ErrorCodeTypeTransformer().encode(value).toString();
  }
  if (value is FieldErrorCode) {
    return FieldErrorCodeTypeTransformer().encode(value).toString();
  }
  if (value is FoodRefKind) {
    return FoodRefKindTypeTransformer().encode(value).toString();
  }
  if (value is HalalStatus) {
    return HalalStatusTypeTransformer().encode(value).toString();
  }
  if (value is HardRuleType) {
    return HardRuleTypeTypeTransformer().encode(value).toString();
  }
  if (value is KitchenAvailability) {
    return KitchenAvailabilityTypeTransformer().encode(value).toString();
  }
  if (value is KitchenCategory) {
    return KitchenCategoryTypeTransformer().encode(value).toString();
  }
  if (value is KitchenChangeOperation) {
    return KitchenChangeOperationTypeTransformer().encode(value).toString();
  }
  if (value is KitchenChangeOutcome) {
    return KitchenChangeOutcomeTypeTransformer().encode(value).toString();
  }
  if (value is KitchenItemState) {
    return KitchenItemStateTypeTransformer().encode(value).toString();
  }
  if (value is KitchenQuantity) {
    return KitchenQuantityTypeTransformer().encode(value).toString();
  }
  if (value is Language) {
    return LanguageTypeTransformer().encode(value).toString();
  }
  if (value is LessOf) {
    return LessOfTypeTransformer().encode(value).toString();
  }
  if (value is MappingConfirmer) {
    return MappingConfirmerTypeTransformer().encode(value).toString();
  }
  if (value is MappingStatus) {
    return MappingStatusTypeTransformer().encode(value).toString();
  }
  if (value is MealRating) {
    return MealRatingTypeTransformer().encode(value).toString();
  }
  if (value is MealType) {
    return MealTypeTypeTransformer().encode(value).toString();
  }
  if (value is MemberMealRating) {
    return MemberMealRatingTypeTransformer().encode(value).toString();
  }
  if (value is NutrientCode) {
    return NutrientCodeTypeTransformer().encode(value).toString();
  }
  if (value is NutrientUnit) {
    return NutrientUnitTypeTransformer().encode(value).toString();
  }
  if (value is NutritionStatus) {
    return NutritionStatusTypeTransformer().encode(value).toString();
  }
  if (value is PhotoSessionStatus) {
    return PhotoSessionStatusTypeTransformer().encode(value).toString();
  }
  if (value is PortionSize) {
    return PortionSizeTypeTransformer().encode(value).toString();
  }
  if (value is RecipeDifficulty) {
    return RecipeDifficultyTypeTransformer().encode(value).toString();
  }
  if (value is RecipeLifecycleStatus) {
    return RecipeLifecycleStatusTypeTransformer().encode(value).toString();
  }
  if (value is RecipeOrigin) {
    return RecipeOriginTypeTransformer().encode(value).toString();
  }
  if (value is RecipeSpiceLevel) {
    return RecipeSpiceLevelTypeTransformer().encode(value).toString();
  }
  if (value is RecognitionConfidence) {
    return RecognitionConfidenceTypeTransformer().encode(value).toString();
  }
  if (value is RecognitionFailureReason) {
    return RecognitionFailureReasonTypeTransformer().encode(value).toString();
  }
  if (value is RulesConsentStatus) {
    return RulesConsentStatusTypeTransformer().encode(value).toString();
  }
  if (value is SafetyReasonCode) {
    return SafetyReasonCodeTypeTransformer().encode(value).toString();
  }
  if (value is SafetyReasonKind) {
    return SafetyReasonKindTypeTransformer().encode(value).toString();
  }
  if (value is SafetyReportOutcome) {
    return SafetyReportOutcomeTypeTransformer().encode(value).toString();
  }
  if (value is SafetyReportStatus) {
    return SafetyReportStatusTypeTransformer().encode(value).toString();
  }
  if (value is SafetyReportType) {
    return SafetyReportTypeTypeTransformer().encode(value).toString();
  }
  if (value is SafetyStatus) {
    return SafetyStatusTypeTransformer().encode(value).toString();
  }
  if (value is SafetySubjectKind) {
    return SafetySubjectKindTypeTransformer().encode(value).toString();
  }
  if (value is SignInChannel) {
    return SignInChannelTypeTransformer().encode(value).toString();
  }
  if (value is SignInMethod) {
    return SignInMethodTypeTransformer().encode(value).toString();
  }
  if (value is SpiceLevel) {
    return SpiceLevelTypeTransformer().encode(value).toString();
  }
  if (value is StaffRole) {
    return StaffRoleTypeTransformer().encode(value).toString();
  }
  if (value is StandardAllergen) {
    return StandardAllergenTypeTransformer().encode(value).toString();
  }
  if (value is SubstitutionSource) {
    return SubstitutionSourceTypeTransformer().encode(value).toString();
  }
  if (value is TexturePreference) {
    return TexturePreferenceTypeTransformer().encode(value).toString();
  }
  if (value is TimeAvailable) {
    return TimeAvailableTypeTransformer().encode(value).toString();
  }
  if (value is TradeOffKind) {
    return TradeOffKindTypeTransformer().encode(value).toString();
  }
  return value.toString();
}

/// Returns the decoded body as UTF-8 if the given headers indicate an 'application/json'
/// content type. Otherwise, returns the decoded body as decoded by dart:http package.
Future<String> _decodeBodyBytes(Response response) async {
  final contentType = response.headers['content-type'];
  return contentType != null && contentType.toLowerCase().startsWith('application/json')
    ? response.bodyBytes.isEmpty ? '' : utf8.decode(response.bodyBytes)
    : response.body;
}

/// Returns a valid [T] value found at the specified Map [key], null otherwise.
T? mapValueOfType<T>(dynamic map, String key) {
  final dynamic value = map is Map ? map[key] : null;
  if (T == double && value is int) {
    return value.toDouble() as T;
  }
  return value is T ? value : null;
}

/// Returns a valid Map<K, V> found at the specified Map [key], null otherwise.
Map<K, V>? mapCastOfType<K, V>(dynamic map, String key) {
  final dynamic value = map is Map ? map[key] : null;
  return value is Map ? value.cast<K, V>() : null;
}

/// Returns a valid [DateTime] found at the specified Map [key], null otherwise.
DateTime? mapDateTime(dynamic map, String key, [String? pattern]) {
  final dynamic value = map is Map ? map[key] : null;
  if (value != null) {
    int? millis;
    if (value is int) {
      millis = value;
    } else if (value is String) {
      if (_isEpochMarker(pattern)) {
        millis = int.tryParse(value);
      } else {
        return DateTime.tryParse(value);
      }
    }
    if (millis != null) {
      return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    }
  }
  return null;
}
