//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of keluargamakan_api;

class Account {
  /// Returns a new [Account] instance.
  Account({
    required this.id,
    required this.role,
    required this.householdId,
    this.signInMethods = const {},
    required this.phone,
    required this.email,
    required this.createdAt,
  });

  /// Opaque identifier (lowercase, safe for Cek Aman rule IDs).
  final String id;

  final AccountRole role;

  /// Null until the household is created.
  final String? householdId;

  final Set<SignInMethod> signInMethods;

  /// E.164 phone number, if verified.
  final String? phone;

  /// Email address, if verified or from Google.
  final String? email;

  final DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Account &&
    other.id == id &&
    other.role == role &&
    other.householdId == householdId &&
    _deepEquality.equals(other.signInMethods, signInMethods) &&
    other.phone == phone &&
    other.email == email &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (role.hashCode) +
    (householdId == null ? 0 : householdId!.hashCode) +
    (signInMethods.hashCode) +
    (phone == null ? 0 : phone!.hashCode) +
    (email == null ? 0 : email!.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'Account[id=$id, role=$role, householdId=$householdId, signInMethods=$signInMethods, phone=$phone, email=$email, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'role'] = this.role;
    if (this.householdId != null) {
      json[r'householdId'] = this.householdId;
    } else {
      json[r'householdId'] = null;
    }
      json[r'signInMethods'] = this.signInMethods.toList(growable: false);
    if (this.phone != null) {
      json[r'phone'] = this.phone;
    } else {
      json[r'phone'] = null;
    }
    if (this.email != null) {
      json[r'email'] = this.email;
    } else {
      json[r'email'] = null;
    }
      json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [Account] and returns a new one where some of the
  /// properties have changed.
  Account copyWith({
    String? id,
    AccountRole? role,
    String? householdId,
    bool householdIdSetToNull = false,
    Set<SignInMethod>? signInMethods,
    String? phone,
    bool phoneSetToNull = false,
    String? email,
    bool emailSetToNull = false,
    DateTime? createdAt,
  }) => Account(
    id: id ?? this.id,
    role: role ?? this.role,
    householdId: householdIdSetToNull ? null : householdId ?? this.householdId,
    signInMethods: signInMethods ?? this.signInMethods,
    phone: phoneSetToNull ? null : phone ?? this.phone,
    email: emailSetToNull ? null : email ?? this.email,
    createdAt: createdAt ?? this.createdAt,
  );

  /// Returns a new [Account] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Account? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "Account[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "Account[id]" has a null value in JSON.');
        assert(json.containsKey(r'role'), 'Required key "Account[role]" is missing from JSON.');
        assert(json[r'role'] != null, 'Required key "Account[role]" has a null value in JSON.');
        assert(json.containsKey(r'householdId'), 'Required key "Account[householdId]" is missing from JSON.');
        assert(json.containsKey(r'signInMethods'), 'Required key "Account[signInMethods]" is missing from JSON.');
        assert(json[r'signInMethods'] != null, 'Required key "Account[signInMethods]" has a null value in JSON.');
        assert(json.containsKey(r'phone'), 'Required key "Account[phone]" is missing from JSON.');
        assert(json.containsKey(r'email'), 'Required key "Account[email]" is missing from JSON.');
        assert(json.containsKey(r'createdAt'), 'Required key "Account[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null, 'Required key "Account[createdAt]" has a null value in JSON.');
        return true;
      }());

      return Account(
        id: mapValueOfType<String>(json, r'id')!,
        role: AccountRole.fromJson(json[r'role'])!,
        householdId: mapValueOfType<String>(json, r'householdId'),
        signInMethods: SignInMethod.listFromJson(json[r'signInMethods']).toSet(),
        phone: mapValueOfType<String>(json, r'phone'),
        email: mapValueOfType<String>(json, r'email'),
        createdAt: mapDateTime(json, r'createdAt', r'')!,
      );
    }
    return null;
  }

  static List<Account> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Account>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Account.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Account> mapFromJson(dynamic json) {
    final map = <String, Account>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Account.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Account-objects as value to a dart map
  static Map<String, List<Account>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Account>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Account.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'role',
    'householdId',
    'signInMethods',
    'phone',
    'email',
    'createdAt',
  };
}

