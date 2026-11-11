//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class Session {
  /// Returns a new [Session] instance.
  Session({
    required this.tokens,
    required this.account,
    required this.isNewAccount,
  });

  final SessionTokens tokens;

  final Account account;

  /// True when this sign-in created the account.
  final bool isNewAccount;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Session &&
    other.tokens == tokens &&
    other.account == account &&
    other.isNewAccount == isNewAccount;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (tokens.hashCode) +
    (account.hashCode) +
    (isNewAccount.hashCode);

  @override
  String toString() => 'Session[tokens=$tokens, account=$account, isNewAccount=$isNewAccount]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'tokens'] = this.tokens;
      json[r'account'] = this.account;
      json[r'isNewAccount'] = this.isNewAccount;
    return json;
  }

  /// Clones this instance of [Session] and returns a new one where some of the
  /// properties have changed.
  Session copyWith({
    SessionTokens? tokens,
    Account? account,
    bool? isNewAccount,
  }) => Session(
    tokens: tokens ?? this.tokens,
    account: account ?? this.account,
    isNewAccount: isNewAccount ?? this.isNewAccount,
  );

  /// Returns a new [Session] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Session? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'tokens'), 'Required key "Session[tokens]" is missing from JSON.');
        assert(json[r'tokens'] != null, 'Required key "Session[tokens]" has a null value in JSON.');
        assert(json.containsKey(r'account'), 'Required key "Session[account]" is missing from JSON.');
        assert(json[r'account'] != null, 'Required key "Session[account]" has a null value in JSON.');
        assert(json.containsKey(r'isNewAccount'), 'Required key "Session[isNewAccount]" is missing from JSON.');
        assert(json[r'isNewAccount'] != null, 'Required key "Session[isNewAccount]" has a null value in JSON.');
        return true;
      }());

      return Session(
        tokens: SessionTokens.fromJson(json[r'tokens'])!,
        account: Account.fromJson(json[r'account'])!,
        isNewAccount: mapValueOfType<bool>(json, r'isNewAccount')!,
      );
    }
    return null;
  }

  static List<Session> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Session>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Session.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Session> mapFromJson(dynamic json) {
    final map = <String, Session>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Session.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Session-objects as value to a dart map
  static Map<String, List<Session>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Session>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Session.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'tokens',
    'account',
    'isNewAccount',
  };
}

