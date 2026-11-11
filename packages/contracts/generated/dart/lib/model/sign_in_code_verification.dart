//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class SignInCodeVerification {
  /// Returns a new [SignInCodeVerification] instance.
  SignInCodeVerification({
    required this.challengeId,
    required this.code,
    required this.device,
  });

  final String challengeId;

  final String code;

  final DeviceInfo device;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SignInCodeVerification &&
    other.challengeId == challengeId &&
    other.code == code &&
    other.device == device;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (challengeId.hashCode) +
    (code.hashCode) +
    (device.hashCode);

  @override
  String toString() => 'SignInCodeVerification[challengeId=$challengeId, code=$code, device=$device]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'challengeId'] = this.challengeId;
      json[r'code'] = this.code;
      json[r'device'] = this.device;
    return json;
  }

  /// Clones this instance of [SignInCodeVerification] and returns a new one where some of the
  /// properties have changed.
  SignInCodeVerification copyWith({
    String? challengeId,
    String? code,
    DeviceInfo? device,
  }) => SignInCodeVerification(
    challengeId: challengeId ?? this.challengeId,
    code: code ?? this.code,
    device: device ?? this.device,
  );

  /// Returns a new [SignInCodeVerification] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SignInCodeVerification? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'challengeId'), 'Required key "SignInCodeVerification[challengeId]" is missing from JSON.');
        assert(json[r'challengeId'] != null, 'Required key "SignInCodeVerification[challengeId]" has a null value in JSON.');
        assert(json.containsKey(r'code'), 'Required key "SignInCodeVerification[code]" is missing from JSON.');
        assert(json[r'code'] != null, 'Required key "SignInCodeVerification[code]" has a null value in JSON.');
        assert(json.containsKey(r'device'), 'Required key "SignInCodeVerification[device]" is missing from JSON.');
        assert(json[r'device'] != null, 'Required key "SignInCodeVerification[device]" has a null value in JSON.');
        return true;
      }());

      return SignInCodeVerification(
        challengeId: mapValueOfType<String>(json, r'challengeId')!,
        code: mapValueOfType<String>(json, r'code')!,
        device: DeviceInfo.fromJson(json[r'device'])!,
      );
    }
    return null;
  }

  static List<SignInCodeVerification> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SignInCodeVerification>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SignInCodeVerification.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SignInCodeVerification> mapFromJson(dynamic json) {
    final map = <String, SignInCodeVerification>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SignInCodeVerification.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SignInCodeVerification-objects as value to a dart map
  static Map<String, List<SignInCodeVerification>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SignInCodeVerification>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SignInCodeVerification.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'challengeId',
    'code',
    'device',
  };
}

