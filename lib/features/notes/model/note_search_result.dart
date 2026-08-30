import 'note.dart';

/// Where inside a note the search term matched.
enum SearchMatchLocation { title, content, attachment }

/// A single search hit: the note plus the exact place the term matched,
/// ready for the WhatsApp-style results list (name + snippet below).
class NoteSearchMatch {
  const NoteSearchMatch({
    required this.note,
    required this.location,
    required this.preview,
    this.fileName,
  });

  final Note note;
  final SearchMatchLocation location;

  /// Text shown under the note title. It always contains [Note.title]'s term
  /// match context: for a content/file match this is the text around the term,
  /// for a title match it is the first content line as a preview.
  final String preview;

  /// File name of the attachment when [location] is [SearchMatchLocation.attachment].
  final String? fileName;

  bool get matchedInTitle => location == SearchMatchLocation.title;
  bool get matchedInContent => location == SearchMatchLocation.content;
  bool get matchedInFile => location == SearchMatchLocation.attachment;

  /// The actual text we searched against (used for highlighting).
  String get matchSource => switch (location) {
    SearchMatchLocation.title => note.title,
    SearchMatchLocation.content => note.content,
    SearchMatchLocation.attachment => preview,
  };
}

/// Builds a compact snippet centered on the first (case-insensitive)
/// occurrence of [term] inside [text], with ellipses on both sides.
String searchSnippetAround(String text, String term, {int padding = 32}) {
  if (text.isEmpty || term.isEmpty) return text;
  final lower = text.toLowerCase();
  final idx = lower.indexOf(term.toLowerCase());
  if (idx < 0) return text;
  var start = idx - padding;
  if (start < 0) start = 0;
  var end = idx + term.length + padding;
  if (end > text.length) end = text.length;
  var snippet = text.substring(start, end);
  if (start > 0) snippet = '… $snippet';
  if (end < text.length) snippet = '$snippet …';
  return snippet;
}

/// First non-empty content line, trimmed to a reasonable preview length.
String firstContentLine(String content) {
  for (final line in content.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isNotEmpty) {
      return trimmed.length > 120 ? '${trimmed.substring(0, 120)}…' : trimmed;
    }
  }
  return '';
}
