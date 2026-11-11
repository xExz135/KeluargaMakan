//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class GoogleSignIn {
  /// Returns a new [GoogleSignIn] instance.
  GoogleSignIn({
    required this.idToken,
    required this.device,
  });

  /// Google ID token from Credential Manager on Android.
  final String idToken;

  final DeviceInfo device;

  @override
  bool operator ==(Object other) => identical(this, other) || other is GoogleSignIn &&
    other.idToken == idToken &&
    other.device == device;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (idToken.hashCode) +
    (device.hashCode);

  @override
  String toString() => 'GoogleSignIn[idToken=$idToken, device=$device]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'idToken'] = this.idToken;
      json[r'device'] = this.device;
    return json;
  }

  /// Clones this instance of [GoogleSignIn] and returns a new one where some of the
  /// properties have changed.
  GoogleSignIn copyWith({
    String? idToken,
    DeviceInfo? device,
  }) => GoogleSignIn(
    idToken: idToken ?? this.idToken,
    device: device ?? this.device,
  );

  /// Returns a new [GoogleSignIn] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GoogleSignIn? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'idToken'), 'Required key "GoogleSignIn[idToken]" is missing from JSON.');
        assert(json[r'idToken'] != null, 'Required key "GoogleSignIn[idToken]" has a null value in JSON.');
        assert(json.containsKey(r'device'), 'Required key "GoogleSignIn[device]" is missing from JSON.');
        assert(json[r'device'] != null, 'Required key "GoogleSignIn[device]" has a null value in JSON.');
        return true;
      }());

      return GoogleSignIn(
        idToken: mapValueOfType<String>(json, r'idToken')!,
        device: DeviceInfo.fromJson(json[r'device'])!,
      );
    }
    return null;
  }

  static List<GoogleSignIn> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <GoogleSignIn>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GoogleSignIn.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GoogleSignIn> mapFromJson(dynamic json) {
    final map = <String, GoogleSignIn>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GoogleSignIn.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GoogleSignIn-objects as value to a dart map
  static Map<String, List<GoogleSignIn>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<GoogleSignIn>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GoogleSignIn.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'idToken',
    'device',
  };
}

