import 'package:flutter/material.dart';

/// Renders [text] with every occurrence of [query] highlighted.
class HighlightedTextWidget extends StatelessWidget {
  const HighlightedTextWidget({
    super.key,
    required this.text,
    required this.query,
    required this.style,
    required this.highlightColor,
  });

  final String text;
  final String query;
  final TextStyle? style;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) return Text(text, style: style);
    final spans = <TextSpan>[];
    final lower = text.toLowerCase();
    final qLower = query.toLowerCase();
    var start = 0;
    while (start <= lower.length) {
      final idx = lower.indexOf(qLower, start);
      if (idx < 0) {
        spans.add(TextSpan(text: text.substring(start), style: style));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx), style: style));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: style?.copyWith(
          backgroundColor: highlightColor.withValues(alpha: 0.4),
          fontWeight: FontWeight.w700,
        ),
      ));
      start = idx + query.length;
    }
    return RichText(text: TextSpan(children: spans));
  }
}
