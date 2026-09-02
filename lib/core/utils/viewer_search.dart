/// Pure helpers for in-note search (case-insensitive substring matching), kept
/// out of the widget tree so it can be unit-tested in isolation.
class ViewerSearch {
  ViewerSearch._();

  /// Returns the start indices of every (possibly overlapping) occurrence of
  /// [query] in [text], case-insensitive.
  static List<int> findMatches(String text, String query) {
    if (query.isEmpty) return const <int>[];
    final matches = <int>[];
    final lower = text.toLowerCase();
    final qLower = query.toLowerCase();
    var start = 0;
    while (start <= lower.length) {
      final idx = lower.indexOf(qLower, start);
      if (idx < 0) break;
      matches.add(idx);
      start = idx + 1;
    }
    return matches;
  }

  /// Human-readable "current of total" match count, e.g. "1 of 3".
  static String matchCountLabel(int total, int current) =>
      '$current of $total';
}
