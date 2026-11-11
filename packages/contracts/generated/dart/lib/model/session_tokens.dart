//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class SessionTokens {
  /// Returns a new [SessionTokens] instance.
  SessionTokens({
    required this.tokenType,
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.refreshTokenExpiresAt,
  });

  final SessionTokensTokenTypeEnum tokenType;

  final String accessToken;

  final DateTime accessTokenExpiresAt;

  final String refreshToken;

  final DateTime refreshTokenExpiresAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SessionTokens &&
    other.tokenType == tokenType &&
    other.accessToken == accessToken &&
    other.accessTokenExpiresAt == accessTokenExpiresAt &&
    other.refreshToken == refreshToken &&
    other.refreshTokenExpiresAt == refreshTokenExpiresAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (tokenType.hashCode) +
    (accessToken.hashCode) +
    (accessTokenExpiresAt.hashCode) +
    (refreshToken.hashCode) +
    (refreshTokenExpiresAt.hashCode);

  @override
  String toString() => 'SessionTokens[tokenType=$tokenType, accessToken=$accessToken, accessTokenExpiresAt=$accessTokenExpiresAt, refreshToken=$refreshToken, refreshTokenExpiresAt=$refreshTokenExpiresAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'tokenType'] = this.tokenType;
      json[r'accessToken'] = this.accessToken;
      json[r'accessTokenExpiresAt'] = this.accessTokenExpiresAt.toUtc().toIso8601String();
      json[r'refreshToken'] = this.refreshToken;
      json[r'refreshTokenExpiresAt'] = this.refreshTokenExpiresAt.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [SessionTokens] and returns a new one where some of the
  /// properties have changed.
  SessionTokens copyWith({
    SessionTokensTokenTypeEnum? tokenType,
    String? accessToken,
    DateTime? accessTokenExpiresAt,
    String? refreshToken,
    DateTime? refreshTokenExpiresAt,
  }) => SessionTokens(
    tokenType: tokenType ?? this.tokenType,
    accessToken: accessToken ?? this.accessToken,
    accessTokenExpiresAt: accessTokenExpiresAt ?? this.accessTokenExpiresAt,
    refreshToken: refreshToken ?? this.refreshToken,
    refreshTokenExpiresAt: refreshTokenExpiresAt ?? this.refreshTokenExpiresAt,
  );

  /// Returns a new [SessionTokens] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SessionTokens? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'tokenType'), 'Required key "SessionTokens[tokenType]" is missing from JSON.');
        assert(json[r'tokenType'] != null, 'Required key "SessionTokens[tokenType]" has a null value in JSON.');
        assert(json.containsKey(r'accessToken'), 'Required key "SessionTokens[accessToken]" is missing from JSON.');
        assert(json[r'accessToken'] != null, 'Required key "SessionTokens[accessToken]" has a null value in JSON.');
        assert(json.containsKey(r'accessTokenExpiresAt'), 'Required key "SessionTokens[accessTokenExpiresAt]" is missing from JSON.');
        assert(json[r'accessTokenExpiresAt'] != null, 'Required key "SessionTokens[accessTokenExpiresAt]" has a null value in JSON.');
        assert(json.containsKey(r'refreshToken'), 'Required key "SessionTokens[refreshToken]" is missing from JSON.');
        assert(json[r'refreshToken'] != null, 'Required key "SessionTokens[refreshToken]" has a null value in JSON.');
        assert(json.containsKey(r'refreshTokenExpiresAt'), 'Required key "SessionTokens[refreshTokenExpiresAt]" is missing from JSON.');
        assert(json[r'refreshTokenExpiresAt'] != null, 'Required key "SessionTokens[refreshTokenExpiresAt]" has a null value in JSON.');
        return true;
      }());

      return SessionTokens(
        tokenType: SessionTokensTokenTypeEnum.fromJson(json[r'tokenType'])!,
        accessToken: mapValueOfType<String>(json, r'accessToken')!,
        accessTokenExpiresAt: mapDateTime(json, r'accessTokenExpiresAt', r'')!,
        refreshToken: mapValueOfType<String>(json, r'refreshToken')!,
        refreshTokenExpiresAt: mapDateTime(json, r'refreshTokenExpiresAt', r'')!,
      );
    }
    return null;
  }

  static List<SessionTokens> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SessionTokens>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SessionTokens.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SessionTokens> mapFromJson(dynamic json) {
    final map = <String, SessionTokens>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SessionTokens.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SessionTokens-objects as value to a dart map
  static Map<String, List<SessionTokens>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SessionTokens>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SessionTokens.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'tokenType',
    'accessToken',
    'accessTokenExpiresAt',
    'refreshToken',
    'refreshTokenExpiresAt',
  };
}


enum SessionTokensTokenTypeEnum {
  bearer._(r'Bearer'),
  ;

  /// Instantiate a new enum with the provided value.
  const SessionTokensTokenTypeEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [SessionTokensTokenTypeEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static SessionTokensTokenTypeEnum? fromJson(dynamic value) => SessionTokensTokenTypeEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [SessionTokensTokenTypeEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<SessionTokensTokenTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SessionTokensTokenTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SessionTokensTokenTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [SessionTokensTokenTypeEnum] to String,
/// and [decode] dynamic data back to [SessionTokensTokenTypeEnum].
class SessionTokensTokenTypeEnumTypeTransformer {
  factory SessionTokensTokenTypeEnumTypeTransformer() => _instance ??= const SessionTokensTokenTypeEnumTypeTransformer._();

  const SessionTokensTokenTypeEnumTypeTransformer._();

  String encode(SessionTokensTokenTypeEnum data) => data._value;

  /// Returns the instance of [SessionTokensTokenTypeEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  SessionTokensTokenTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is SessionTokensTokenTypeEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'Bearer': return SessionTokensTokenTypeEnum.bearer;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static SessionTokensTokenTypeEnumTypeTransformer? _instance;
}


