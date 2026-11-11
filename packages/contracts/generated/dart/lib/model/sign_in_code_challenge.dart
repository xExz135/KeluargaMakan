//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class SignInCodeChallenge {
  /// Returns a new [SignInCodeChallenge] instance.
  SignInCodeChallenge({
    required this.challengeId,
    required this.channel,
    required this.codeLength,
    required this.expiresAt,
    required this.resendAvailableAt,
  });

  final String challengeId;

  final SignInChannel channel;

  /// Number of digits, from configuration.
  ///
  /// Minimum value: 4
  /// Maximum value: 8
  final int codeLength;

  final DateTime expiresAt;

  /// Earliest time a new code may be requested (configuration).
  final DateTime resendAvailableAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SignInCodeChallenge &&
    other.challengeId == challengeId &&
    other.channel == channel &&
    other.codeLength == codeLength &&
    other.expiresAt == expiresAt &&
    other.resendAvailableAt == resendAvailableAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (challengeId.hashCode) +
    (channel.hashCode) +
    (codeLength.hashCode) +
    (expiresAt.hashCode) +
    (resendAvailableAt.hashCode);

  @override
  String toString() => 'SignInCodeChallenge[challengeId=$challengeId, channel=$channel, codeLength=$codeLength, expiresAt=$expiresAt, resendAvailableAt=$resendAvailableAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'challengeId'] = this.challengeId;
      json[r'channel'] = this.channel;
      json[r'codeLength'] = this.codeLength;
      json[r'expiresAt'] = this.expiresAt.toUtc().toIso8601String();
      json[r'resendAvailableAt'] = this.resendAvailableAt.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [SignInCodeChallenge] and returns a new one where some of the
  /// properties have changed.
  SignInCodeChallenge copyWith({
    String? challengeId,
    SignInChannel? channel,
    int? codeLength,
    DateTime? expiresAt,
    DateTime? resendAvailableAt,
  }) => SignInCodeChallenge(
    challengeId: challengeId ?? this.challengeId,
    channel: channel ?? this.channel,
    codeLength: codeLength ?? this.codeLength,
    expiresAt: expiresAt ?? this.expiresAt,
    resendAvailableAt: resendAvailableAt ?? this.resendAvailableAt,
  );

  /// Returns a new [SignInCodeChallenge] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SignInCodeChallenge? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'challengeId'), 'Required key "SignInCodeChallenge[challengeId]" is missing from JSON.');
        assert(json[r'challengeId'] != null, 'Required key "SignInCodeChallenge[challengeId]" has a null value in JSON.');
        assert(json.containsKey(r'channel'), 'Required key "SignInCodeChallenge[channel]" is missing from JSON.');
        assert(json[r'channel'] != null, 'Required key "SignInCodeChallenge[channel]" has a null value in JSON.');
        assert(json.containsKey(r'codeLength'), 'Required key "SignInCodeChallenge[codeLength]" is missing from JSON.');
        assert(json[r'codeLength'] != null, 'Required key "SignInCodeChallenge[codeLength]" has a null value in JSON.');
        assert(json.containsKey(r'expiresAt'), 'Required key "SignInCodeChallenge[expiresAt]" is missing from JSON.');
        assert(json[r'expiresAt'] != null, 'Required key "SignInCodeChallenge[expiresAt]" has a null value in JSON.');
        assert(json.containsKey(r'resendAvailableAt'), 'Required key "SignInCodeChallenge[resendAvailableAt]" is missing from JSON.');
        assert(json[r'resendAvailableAt'] != null, 'Required key "SignInCodeChallenge[resendAvailableAt]" has a null value in JSON.');
        return true;
      }());

      return SignInCodeChallenge(
        challengeId: mapValueOfType<String>(json, r'challengeId')!,
        channel: SignInChannel.fromJson(json[r'channel'])!,
        codeLength: mapValueOfType<int>(json, r'codeLength')!,
        expiresAt: mapDateTime(json, r'expiresAt', r'')!,
        resendAvailableAt: mapDateTime(json, r'resendAvailableAt', r'')!,
      );
    }
    return null;
  }

  static List<SignInCodeChallenge> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SignInCodeChallenge>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SignInCodeChallenge.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SignInCodeChallenge> mapFromJson(dynamic json) {
    final map = <String, SignInCodeChallenge>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SignInCodeChallenge.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SignInCodeChallenge-objects as value to a dart map
  static Map<String, List<SignInCodeChallenge>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SignInCodeChallenge>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SignInCodeChallenge.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'challengeId',
    'channel',
    'codeLength',
    'expiresAt',
    'resendAvailableAt',
  };
}

