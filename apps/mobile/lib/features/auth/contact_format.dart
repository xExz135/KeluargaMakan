// Phone and email input for sign-in (ACC-01, screens.md O2a and O2b).
//
// The app does a light check so obvious typos get a message before a code is
// requested; the server canonicalizes and decides (services/api
// destination.ts). Phones are Indonesian only (+62, QUESTIONS #61).
//
// Nothing here logs or stores what the user typed.

/// An Indonesian mobile number as the user typed it: "0812 3456 7890",
/// "812-3456-7890", "+62 812 3456 7890" or "62812…".
abstract final class IndonesianPhone {
  /// Shown before the field. A dialling code, not translatable text.
  static const countryPrefix = '+62';

  static final _separators = RegExp(r'[\s().-]');

  /// Mobile numbers start with 8 after the country code and have 9 to 12
  /// digits without the trunk 0 (0812 3456 7890 is 11 digits with it).
  static final _national = RegExp(r'^8\d{8,11}$');

  /// The national number without the trunk 0 ("81234567890"), or null when
  /// [input] is not an Indonesian mobile number.
  static String? national(String input) {
    var value = input.replaceAll(_separators, '');
    if (value.startsWith('+62')) {
      value = value.substring(3);
    } else if (value.startsWith('62') && value.length > 2 && value[2] == '8') {
      value = value.substring(2);
    }
    if (value.startsWith('0')) value = value.substring(1);
    return _national.hasMatch(value) ? value : null;
  }

  /// E.164 ("+6281234567890"), as `SignInCodeRequest.destination` expects.
  static String? e164(String input) {
    final n = national(input);
    return n == null ? null : '$countryPrefix$n';
  }

  /// "0812 •••• 7890": the first four and last four digits of the local form.
  static String masked(String national) {
    final local = '0$national';
    if (local.length <= 8) return '${local.substring(0, 2)}••••';
    return '${local.substring(0, 4)} •••• '
        '${local.substring(local.length - 4)}';
  }
}

abstract final class EmailAddress {
  static final _shape = RegExp(r'^[^\s@]+@[^\s@.]+(\.[^\s@.]+)+$');

  /// The trimmed address, or null when it is clearly not an email address.
  static String? normalized(String input) {
    final value = input.trim();
    if (value.length < 3 || value.length > 254) return null;
    return _shape.hasMatch(value) ? value : null;
  }

  /// "r•••@contoh.com": the first character of the local part, then dots.
  static String masked(String email) {
    final at = email.lastIndexOf('@');
    if (at <= 0) return '•••';
    return '${email.substring(0, 1)}•••${email.substring(at)}';
  }
}
