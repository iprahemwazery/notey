import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:flutter_drawing_board/paint_contents.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';

import 'package:notey/core/services/haptics.dart';

import 'package:notey/l10n/generated/app_localizations.dart';

/// Full-screen freehand drawing canvas built on the `flutter_drawing_board`
/// engine (smooth free-lines, eraser, undo/redo/clear, PNG export).
///
/// Pops with the saved PNG path (written to the temp directory) or null when
/// dismissed. The toolbar is custom (stroke-width slider, palette dots and an
/// eraser toggle) so the on-screen controls stay consistent with the rest of
/// the app while the board handles input, hit-testing and serialization.
class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key, this.initialPath});

  final String? initialPath;

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  final DrawingController _controller = DrawingController();

  Color _color = const Color(0xFF1C1B1F);
  double _strokeWidth = 4;
  bool _eraserMode = false;
  bool _saving = false;

  static const List<Color> _palette = <Color>[
    Color(0xFF1C1B1F),
    Color(0xFFB3261E),
    Color(0xFFE08600),
    Color(0xFF2E7D32),
    Color(0xFF1565C0),
    Color(0xFFF4F1EA),
  ];

  @override
  void initState() {
    super.initState();
    _applyStyle();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyStyle() {
    _controller.setStyle(
      color: _color,
      strokeWidth: _eraserMode ? _strokeWidth * 4 : _strokeWidth,
      strokeCap: StrokeCap.round,
      strokeJoin: StrokeJoin.round,
    );
    _controller.setPaintContent(_eraserMode ? Eraser() : SimpleLine());
  }

  void _selectColor(Color color) {
    Haptics.tap();
    setState(() {
      _eraserMode = false;
      _color = color;
    });
    _applyStyle();
  }

  void _toggleEraser() {
    Haptics.tap();
    setState(() => _eraserMode = !_eraserMode);
    _applyStyle();
  }

  void _changeWidth(double width) {
    setState(() => _strokeWidth = width);
    _applyStyle();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    if (!_controller.canClear()) {
      await Haptics.light();
      if (mounted) Navigator.pop(context);
      return;
    }
    await Haptics.light();
    final ByteData? data = await _controller.getImageData(pixelRatio: 2);
    if (data == null || !mounted) return;

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/drawing_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(data.buffer.asUint8List());
    if (!mounted) return;
    Navigator.pop(context, file.path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final backgroundImage = widget.initialPath == null
        ? null
        : File(widget.initialPath!);

    return Scaffold(
      backgroundColor: const Color(0xFF141218),
      appBar: AppBar(
        title: Text(l10n.drawTitle),
        backgroundColor: Colors.transparent,
        actions: <Widget>[
          _boardControl(
            tooltip: l10n.undoAction,
            icon: Icons.undo_rounded,
            enabled: _controller.canUndo(),
            onPressed: () {
              Haptics.tap();
              _controller.undo();
            },
          ),
          _boardControl(
            tooltip: l10n.redoAction,
            icon: Icons.redo_rounded,
            enabled: _controller.canRedo(),
            onPressed: () {
              Haptics.tap();
              _controller.redo();
            },
          ),
          IconButton(
            tooltip: l10n.delete,
            onPressed: !_controller.canClear() || _saving
                ? null
                : () {
                    Haptics.tap();
                    _controller.clear();
                  },
            icon: const Icon(Icons.delete_sweep_rounded),
          ),
          IconButton(
            tooltip: l10n.save,
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check_rounded),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => Column(
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.r),
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: DrawingBoard(
                      controller: _controller,
                      background: backgroundImage == null
                          ? const ColoredBox(
                              color: Colors.white,
                              child: SizedBox.expand(),
                            )
                          : Image.file(
                              backgroundImage,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                            ),
                      boardPanEnabled: false,
                      boardScaleEnabled: false,
                      boardConstrained: true,
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.line_weight_rounded,
                            size: 20.w,
                            color: Colors.white54,
                          ),
                          Expanded(
                            child: Slider(
                              value: _strokeWidth,
                              min: 1,
                              max: 20,
                              divisions: 19,
                              activeColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              inactiveColor: Colors.white24,
                              onChanged: _changeWidth,
                            ),
                          ),
                          Text(
                            '${_strokeWidth.round()}',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        GestureDetector(
                          onTap: _toggleEraser,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: _eraserMode ? 38.w : 32.w,
                            height: _eraserMode ? 38.h : 32.h,
                            decoration: BoxDecoration(
                              color: _eraserMode
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.white12,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _eraserMode
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.white38,
                                width: _eraserMode ? 2 : 1,
                              ),
                            ),
                            child: Icon(
                              Icons.auto_fix_high_rounded,
                              size: _eraserMode ? 20.w : 16.w,
                              color: _eraserMode
                                  ? Colors.white
                                  : Colors.white70,
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Container(
                          width: 1.w,
                          height: 28.h,
                          color: Colors.white24,
                        ),
                        SizedBox(width: 16.w),
                        for (final Color c in _palette) ...<Widget>[
                          _ColorDot(
                            color: c,
                            selected: _color == c && !_eraserMode,
                            onTap: () => _selectColor(c),
                          ),
                          SizedBox(width: 10.w),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _boardControl({
    required String tooltip,
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: _saving || !enabled ? null : onPressed,
      icon: Icon(icon),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Haptics.tap();
        onTap();
      },
      child: Container(
        width: selected ? 34.w : 28.w,
        height: selected ? 34.h : 28.h,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.white38,
            width: selected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}
