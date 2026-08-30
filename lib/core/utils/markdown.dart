import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Ultra-light Markdown subset renderer tuned for RTL note text:
/// headings, bold, italic, inline code, fenced code blocks,
/// bullet lists, checkboxes and horizontal rules.
///
/// Chosen over the markdown packages because it keeps full control
/// of text direction and styling while covering exactly what the
/// editor toolbar produces — nothing more.
class MarkdownText extends StatelessWidget {
  const MarkdownText({
    super.key,
    required this.data,
    this.fontSize = 16,
    this.color,
    this.codeBackground,
    this.height = 1.7,
  });

  final String data;
  final double fontSize;
  final Color? color;
  final Color? codeBackground;
  final double height;

  bool get _isCodeFence => data.trimLeft().startsWith('```');

  @override
  Widget build(BuildContext context) {
    if (_isCodeFence) {
      final body = data.trim().replaceAll(RegExp(r'^```.*$'), '').trim();
      return _codeBlock(context, body);
    }

    final spans = <Widget>[];
    final lines = data.split('\n');
    var buffer = <String>[];

    void flushParagraph() {
      if (buffer.isEmpty) return;
      spans.add(_richText(buffer.join('\n')));
      buffer = <String>[];
    }

    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      final trimmed = line.trimLeft();

      final heading = RegExp(r'^(#{1,3})\s+(.*)$').firstMatch(trimmed);
      if (heading != null) {
        flushParagraph();
        spans.add(
          _heading(context, heading.group(2)!, heading.group(1)!.length),
        );
        continue;
      }
      if (RegExp(r'^(---+|\*\*\*+)$').hasMatch(trimmed)) {
        flushParagraph();
        spans.add(SizedBox(height: 6.h));
        spans.add(Divider(height: 8.h));
        spans.add(SizedBox(height: 6.h));
        continue;
      }
      final bullet = RegExp(r'^[-*]\s+\[( |x|X)\]\s+(.*)$').firstMatch(trimmed);
      if (bullet != null) {
        flushParagraph();
        final done = bullet.group(1)!.toLowerCase() == 'x';
        spans.add(_checkboxRow(bullet.group(2)!, done));
        continue;
      }
      final dot = RegExp(r'^[-*]\s+(.*)$').firstMatch(trimmed);
      if (dot != null && !dot.group(1)!.startsWith('[')) {
        flushParagraph();
        spans.add(
          Padding(
            padding: EdgeInsetsDirectional.only(start: 14.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '•  ',
                  style: TextStyle(
                    fontSize: fontSize,
                    height: height,
                    color: color,
                  ),
                ),
                Expanded(child: _richText(dot.group(1)!)),
              ],
            ),
          ),
        );
        continue;
      }
      if (trimmed.isEmpty) {
        flushParagraph();
        spans.add(SizedBox(height: fontSize * .5));
        continue;
      }
      buffer.add(line);
    }
    flushParagraph();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: spans,
    );
  }

  Widget _heading(BuildContext context, String text, int level) {
    final theme = Theme.of(context);
    final style = switch (level) {
      1 => theme.textTheme.titleLarge,
      2 => theme.textTheme.titleMedium,
      _ => theme.textTheme.titleSmall,
    };
    return Padding(
      padding: EdgeInsets.only(top: 4.h),
      child: Text.rich(
        _spans(text),
        style: style?.copyWith(
          fontWeight: FontWeight.w800,
          color: color,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _checkboxRow(String text, bool done) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: fontSize * 1.4,
          child: Icon(
            done
                ? Icons.check_box_rounded
                : Icons.check_box_outline_blank_rounded,
            size: fontSize * 1.25,
            color: done ? const Color(0xFF2FA36B) : color,
          ),
        ),
        Expanded(child: _richText(text, strike: done)),
      ],
    );
  }

  Widget _richText(String text, {bool strike = false}) => Text.rich(
    _spans(text, strike: strike),
    style: TextStyle(fontSize: fontSize, height: height, color: color),
  );

  InlineSpan _spans(String text, {bool strike = false}) {
    final pattern = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*|`(.+?)`');
    final children = <InlineSpan>[];
    var cursor = 0;

    void plain(String chunk) {
      if (chunk.isEmpty) return;
      children.add(TextSpan(text: chunk));
    }

    for (final match in pattern.allMatches(text)) {
      plain(text.substring(cursor, match.start));
      if (match.group(1) != null) {
        children.add(
          TextSpan(
            text: match.group(1),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              decoration: _strike(strike),
            ),
          ),
        );
      } else if (match.group(2) != null) {
        children.add(
          TextSpan(
            text: match.group(2),
            style: TextStyle(
              fontStyle: FontStyle.italic,
              decoration: _strike(strike),
            ),
          ),
        );
      } else {
        children.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: codeBackground ?? Colors.black.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(5.r),
              ),
              child: Text(
                match.group(3)!,
                style: TextStyle(
                  fontSize: fontSize * .88,
                  fontFamily: 'monospace',
                  color: color,
                ),
              ),
            ),
          ),
        );
      }
      cursor = match.end;
    }
    plain(text.substring(cursor));
    return TextSpan(children: children);
  }

  TextDecoration? _strike(bool base) =>
      base ? TextDecoration.lineThrough : null;

  Widget _codeBlock(BuildContext context, String body) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        body,
        style: TextStyle(
          fontSize: fontSize * .88,
          fontFamily: 'monospace',
          height: 1.6,
          color: color ?? scheme.onSurface,
        ),
      ),
    );
  }
}
