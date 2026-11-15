// Checks on text the user types into Dapur Saya (custom ingredient names,
// typed brands, set names) before it is queued, mirroring the server's rules
// (contract `KitchenCustomName`, `KitchenBrandInput`, `IngredientSetName`):
// trimmed, not empty, within the length, and without control, format
// (including bidirectional controls), private-use or lone surrogate
// characters. A change the server would refuse outright is never queued,
// so it cannot hold up the sync. The server stays the judge: it also
// normalizes to NFC, which this app does not.

/// Why [text] cannot be stored, or null when it can.
enum TextProblem { empty, tooLong, hiddenCharacters }

final _hidden = RegExp(r'[\p{Cc}\p{Cf}\p{Co}\p{Cs}]', unicode: true);

TextProblem? textProblem(String text, {required int maxLength}) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return TextProblem.empty;
  if (trimmed.length > maxLength) return TextProblem.tooLong;
  if (_hidden.hasMatch(trimmed) || _hasLoneSurrogate(trimmed)) {
    return TextProblem.hiddenCharacters;
  }
  return null;
}

bool _hasLoneSurrogate(String text) {
  final units = text.codeUnits;
  for (var i = 0; i < units.length; i++) {
    final u = units[i];
    if (u >= 0xD800 && u <= 0xDBFF) {
      if (i + 1 >= units.length) return true;
      final next = units[i + 1];
      if (next < 0xDC00 || next > 0xDFFF) return true;
      i++;
    } else if (u >= 0xDC00 && u <= 0xDFFF) {
      return true;
    }
  }
  return false;
}

/// The contract's `KitchenCustomName` and `KitchenBrandInput.customName`
/// limit.
const kitchenTextMaxLength = 60;

/// The contract's `IngredientSetName` limit.
const setNameMaxLength = 40;
