//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class SignInCodeRequest {
  /// Returns a new [SignInCodeRequest] instance.
  SignInCodeRequest({
    required this.channel,
    required this.destination,
    required this.language,
  });

  final SignInChannel channel;

  final String destination;

  /// Language of the message that carries the code.
  final Language language;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SignInCodeRequest &&
    other.channel == channel &&
    other.destination == destination &&
    other.language == language;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (channel.hashCode) +
    (destination.hashCode) +
    (language.hashCode);

  @override
  String toString() => 'SignInCodeRequest[channel=$channel, destination=$destination, language=$language]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'channel'] = this.channel;
      json[r'destination'] = this.destination;
      json[r'language'] = this.language;
    return json;
  }

  /// Clones this instance of [SignInCodeRequest] and returns a new one where some of the
  /// properties have changed.
  SignInCodeRequest copyWith({
    SignInChannel? channel,
    String? destination,
    Language? language,
  }) => SignInCodeRequest(
    channel: channel ?? this.channel,
    destination: destination ?? this.destination,
    language: language ?? this.language,
  );

  /// Returns a new [SignInCodeRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SignInCodeRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'channel'), 'Required key "SignInCodeRequest[channel]" is missing from JSON.');
        assert(json[r'channel'] != null, 'Required key "SignInCodeRequest[channel]" has a null value in JSON.');
        assert(json.containsKey(r'destination'), 'Required key "SignInCodeRequest[destination]" is missing from JSON.');
        assert(json[r'destination'] != null, 'Required key "SignInCodeRequest[destination]" has a null value in JSON.');
        assert(json.containsKey(r'language'), 'Required key "SignInCodeRequest[language]" is missing from JSON.');
        assert(json[r'language'] != null, 'Required key "SignInCodeRequest[language]" has a null value in JSON.');
        return true;
      }());

      return SignInCodeRequest(
        channel: SignInChannel.fromJson(json[r'channel'])!,
        destination: mapValueOfType<String>(json, r'destination')!,
        language: Language.fromJson(json[r'language'])!,
      );
    }
    return null;
  }

  static List<SignInCodeRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SignInCodeRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SignInCodeRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SignInCodeRequest> mapFromJson(dynamic json) {
    final map = <String, SignInCodeRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SignInCodeRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SignInCodeRequest-objects as value to a dart map
  static Map<String, List<SignInCodeRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SignInCodeRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SignInCodeRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'channel',
    'destination',
    'language',
  };
}

