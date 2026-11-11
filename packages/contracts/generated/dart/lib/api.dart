//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

library keluargamakan_api;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

part 'api_client.dart';
part 'api_helper.dart';
part 'api_exception.dart';
part 'auth/authentication.dart';
part 'auth/api_key_auth.dart';
part 'auth/oauth.dart';
part 'auth/http_basic_auth.dart';
part 'auth/http_bearer_auth.dart';
part 'optional.dart';

part 'api/account_api.dart';
part 'api/auth_api.dart';
part 'api/consent_api.dart';
part 'api/hard_rules_api.dart';
part 'api/household_api.dart';
part 'api/preferences_api.dart';
part 'api/profiles_api.dart';
part 'api/reference_api.dart';

part 'model/account.dart';
part 'model/account_role.dart';
part 'model/age_group.dart';
part 'model/avatar.dart';
part 'model/avatar_style.dart';
part 'model/consent_decision.dart';
part 'model/consent_purpose.dart';
part 'model/consent_record.dart';
part 'model/consent_record_list.dart';
part 'model/consent_text.dart';
part 'model/consent_text_section.dart';
part 'model/device_info.dart';
part 'model/device_platform.dart';
part 'model/error_code.dart';
part 'model/field_error.dart';
part 'model/field_error_code.dart';
part 'model/food_ref.dart';
part 'model/food_ref_input.dart';
part 'model/food_ref_kind.dart';
part 'model/google_sign_in.dart';
part 'model/guardian_confirmation.dart';
part 'model/guardian_confirmation_input.dart';
part 'model/hard_rule.dart';
part 'model/hard_rule_create.dart';
part 'model/hard_rule_mapping.dart';
part 'model/hard_rule_mapping_confirmation.dart';
part 'model/hard_rule_type.dart';
part 'model/health_data_consent_decision.dart';
part 'model/household.dart';
part 'model/household_create.dart';
part 'model/household_update.dart';
part 'model/language.dart';
part 'model/less_of.dart';
part 'model/likes_dislikes.dart';
part 'model/likes_dislikes_input.dart';
part 'model/localized_text.dart';
part 'model/manager_profile_create.dart';
part 'model/mapped_ingredient.dart';
part 'model/mapping_confirmer.dart';
part 'model/mapping_status.dart';
part 'model/portion_size.dart';
part 'model/portions.dart';
part 'model/problem.dart';
part 'model/profile.dart';
part 'model/profile_create.dart';
part 'model/profile_list.dart';
part 'model/profile_rules.dart';
part 'model/profile_update.dart';
part 'model/rules_consent_state.dart';
part 'model/rules_consent_status.dart';
part 'model/session.dart';
part 'model/session_refresh.dart';
part 'model/session_tokens.dart';
part 'model/sign_in_channel.dart';
part 'model/sign_in_code_challenge.dart';
part 'model/sign_in_code_request.dart';
part 'model/sign_in_code_verification.dart';
part 'model/sign_in_method.dart';
part 'model/soft_preferences.dart';
part 'model/soft_preferences_input.dart';
part 'model/spice_level.dart';
part 'model/standard_allergen.dart';
part 'model/standard_allergen_list.dart';
part 'model/texture_preference.dart';


/// An [ApiClient] instance that uses the default values obtained from
/// the OpenAPI specification file.
var defaultApiClient = ApiClient();

const _delimiters = {'csv': ',', 'ssv': ' ', 'tsv': '\t', 'pipes': '|'};
const _dateEpochMarker = 'epoch';
const _deepEquality = DeepCollectionEquality();
final _dateFormatter = DateFormat('yyyy-MM-dd');
final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

bool _isEpochMarker(String? pattern) => pattern == _dateEpochMarker || pattern == '/$_dateEpochMarker/';
