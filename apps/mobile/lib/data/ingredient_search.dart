// KIT-04 search over the catalog kept on the phone, used when the API
// cannot be reached (and for the "did you mean" hint of K3). The server's
// search (NFKC folding) stays the reference; this is a close approximation:
// case, common Latin accents, punctuation and spacing are ignored. Exact
// matches come first, then names that start with the query, then names
// with a word that starts with it, then names that contain it.

import 'models/kitchen.dart';

const _accents = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'ā': 'a', //
  'ç': 'c',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e', //
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ī': 'i', //
  'ñ': 'n',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ō': 'o', //
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ū': 'u', //
  'ý': 'y', 'ÿ': 'y',
};

final _separators = RegExp(r'[\s\p{P}\p{S}]+', unicode: true);

/// The comparison form of [text]: lower case, without common accents,
/// punctuation or repeated spaces.
String foldIngredientName(String text) {
  final lower = text.toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_accents[char] ?? char);
  }
  return buffer.toString().replaceAll(_separators, ' ').trim();
}

/// 0 exact, 1 starts with, 2 a word starts with, 3 contains; null: no match.
int? _score(String name, String query) {
  final folded = foldIngredientName(name);
  if (folded.isEmpty) return null;
  if (folded == query) return 0;
  if (folded.startsWith(query)) return 1;
  if (folded.split(' ').any((w) => w.startsWith(query))) return 2;
  if (folded.contains(query)) return 3;
  return null;
}

/// The best matches for [query] in [catalog], best first.
List<IngredientHit> searchCatalog(
  IngredientCatalog catalog,
  String query, {
  int limit = 20,
}) {
  final q = foldIngredientName(query);
  if (q.isEmpty) return const [];
  final scored = <(int, int, IngredientHit)>[];
  for (final (index, item) in catalog.items.indexed) {
    int? best;
    String? matched;
    for (final name in [item.displayName.id, item.displayName.en]) {
      final s = _score(name, q);
      if (s != null && (best == null || s < best)) best = s;
    }
    for (final local in item.localNames) {
      final s = _score(local, q);
      if (s != null && (best == null || s < best)) {
        best = s;
        matched = local;
      }
    }
    if (best != null) {
      scored.add((best, index, IngredientHit(item, matchedName: matched)));
    }
  }
  scored.sort((a, b) {
    final byScore = a.$1.compareTo(b.$1);
    return byScore != 0 ? byScore : a.$2.compareTo(b.$2);
  });
  return [for (final s in scored.take(limit)) s.$3];
}

/// K3 "did you mean": a catalog ingredient whose name or local name is
/// [name], or starts with it (at least 3 letters typed), else null. Offered
/// first, never forced (screens.md K3).
IngredientHit? closestCatalogMatch(IngredientCatalog catalog, String name) {
  final q = foldIngredientName(name);
  if (q.length < 3) return null;
  final hit = searchCatalog(catalog, name, limit: 1).firstOrNull;
  if (hit == null) return null;
  final names = [
    hit.ingredient.displayName.id,
    hit.ingredient.displayName.en,
    ...hit.ingredient.localNames,
  ].map(foldIngredientName);
  return names.any((n) => n == q || n.startsWith(q)) ? hit : null;
}
