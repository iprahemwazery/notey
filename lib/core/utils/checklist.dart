/// Parses lightweight task syntax inside note content.
///
/// A line starting with `- [ ] ` is an open task and `- [x] ` a done one
/// (`X`/`x` both accepted). Everything else renders as normal text.
abstract final class Checklist {
  static final RegExp _taskPattern = RegExp(r'^\s*-\s\[( |x|X)\]\s?');

  static bool isTaskLine(String line) => _taskPattern.hasMatch(line);

  /// Whether [content] contains at least one task line.
  static bool hasTasks(String content) => content.split('\n').any(isTaskLine);

  /// Total number of task lines in [content].
  static int taskCount(String content) =>
      content.split('\n').where(isTaskLine).length;

  /// Flips the checked state of the task at zero-based [taskIndex]
  /// (index among task lines only). Returns the updated content.
  static String toggle(String content, int taskIndex) {
    final lines = content.split('\n');
    var seen = -1;
    for (var i = 0; i < lines.length; i++) {
      final match = _taskPattern.firstMatch(lines[i]);
      if (match == null) continue;
      seen++;
      if (seen != taskIndex) continue;
      final wasChecked = match.group(1)!.toLowerCase() == 'x';
      final box = wasChecked ? ' ' : 'x';
      lines[i] =
          '${lines[i].substring(0, match.start)}- [$box] ${lines[i].substring(match.end)}';
      break;
    }
    return lines.join('\n');
  }
}
