import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart' as aw;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:notey/core/services/haptics.dart';

import 'package:notey/core/widgets/note_snackbar.dart';

import 'package:notey/l10n/generated/app_localizations.dart';

/// Modal voice recorder. Pops with the recorded file path, or null when
/// cancelled / permission denied.
///
/// While recording, live input amplitude is drawn as animated bars via
/// [AudioRecorder.getAmplitude]. After stopping, the sheet flips to a preview
/// stage showing the extracted waveform (audio_waveforms) with play/pause,
/// re-record and attach actions.
Future<String?> showVoiceRecorderSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
    ),
    builder: (_) => const _VoiceRecorderSheet(),
  );
}

enum _SheetPhase { recording, preview }

class _VoiceRecorderSheet extends StatefulWidget {
  const _VoiceRecorderSheet();

  @override
  State<_VoiceRecorderSheet> createState() => _VoiceRecorderSheetState();
}

class _VoiceRecorderSheetState extends State<_VoiceRecorderSheet> {
  final AudioRecorder _recorder = AudioRecorder();
  final List<double> _bars = <double>[];
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  bool _recording = false;
  bool _denied = false;
  bool _disposed = false;

  _SheetPhase _phase = _SheetPhase.recording;
  String? _recordedPath;
  aw.PlayerController? _previewController;
  bool _playing = false;
  bool _previewReady = false;
  StreamSubscription<aw.PlayerState>? _playerSubscription;

  static const int _maxBars = 44;

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    _playerSubscription?.cancel();
    _previewController?.dispose();
    if (_recording) {
      _recorder.stop().catchError((_) => null as String?).then((_) {
        if (!_disposed) _recorder.dispose();
      });
    } else {
      _recorder.dispose();
    }
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_recording) {
      await _stopRecording();
      return;
    }
    await _startRecording();
  }

  Future<void> _startRecording() async {
    await Haptics.tap();
    try {
      if (!await _recorder.hasPermission()) {
        if (!mounted) return;
        setState(() {
          _denied = true;
          _phase = _SheetPhase.recording;
        });
        return;
      }
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      if (!mounted) return;
      setState(() {
        _recording = true;
        _denied = false;
        _phase = _SheetPhase.recording;
        _bars.clear();
      });
      _ticker = Timer.periodic(const Duration(milliseconds: 120), (_) async {
        final double level;
        try {
          final amplitude = await _recorder.getAmplitude();
          level = (((amplitude.current + 60) / 60).clamp(0.0, 1.0)).toDouble();
        } catch (_) {
          return;
        }
        if (!mounted) return;
        setState(() {
          _elapsed += const Duration(milliseconds: 120);
          _bars.add(level);
          if (_bars.length > _maxBars) _bars.removeAt(0);
        });
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _denied = true);
    }
  }

  Future<void> _stopRecording() async {
    await Haptics.heavy();
    _ticker?.cancel();
    _ticker = null;
    try {
      final String? path = await _recorder.stop();
      if (!mounted) return;
      setState(() {
        _recording = false;
        _denied = false;
      });
      if (path != null && await File(path).exists()) {
        await _enterPreview(path);
      } else {
        // Discard silently and let the user try again.
        _resetToRecording();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recording = false;
        _denied = false;
      });
      _resetToRecording();
    }
  }

  Future<void> _enterPreview(String path) async {
    try {
      final controller = aw.PlayerController();
      await controller.preparePlayer(
        path: path,
        shouldExtractWaveform: true,
        noOfSamples: _maxBars * 2,
      );
      _playerSubscription = controller.onPlayerStateChanged.listen((state) {
        if (_disposed) return;
        setState(() {
          _playing = state == aw.PlayerState.playing;
        });
      });
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _recordedPath = path;
        _previewController = controller;
        _previewReady = true;
        _phase = _SheetPhase.preview;
        _playing = false;
      });
    } on Exception {
      if (!mounted) return;
      GlassSnackbar.show(
        message: AppLocalizations.of(context).audioUnavailable,
        isError: true,
      );
      _resetToRecording();
    }
  }

  Future<void> _togglePlayback() async {
    final controller = _previewController;
    if (controller == null || !_previewReady) return;
    await Haptics.tap();
    if (_playing) {
      await controller.pausePlayer();
    } else {
      await controller.startPlayer();
    }
  }

  Future<void> _reRecord() async {
    await Haptics.tap();
    _playerSubscription?.cancel();
    _playerSubscription = null;
    _previewController?.dispose();
    setState(() {
      _previewController = null;
      _previewReady = false;
      _playing = false;
      _recordedPath = null;
      _phase = _SheetPhase.recording;
    });
    await _startRecording();
  }

  Future<void> _attach() async {
    final path = _recordedPath;
    if (path != null) {
      await Haptics.heavy();
      if (mounted) Navigator.pop(context, path);
    }
  }

  void _resetToRecording() {
    if (_disposed) return;
    setState(() {
      _phase = _SheetPhase.recording;
      _recordedPath = null;
      _previewController = null;
      _previewReady = false;
      _playing = false;
    });
    _playerSubscription?.cancel();
    _playerSubscription = null;
  }

  String get _elapsedLabel {
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              l10n.voiceNoteOption,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 18.h),
            if (_phase == _SheetPhase.recording) ..._recordingBody(l10n),
            if (_phase == _SheetPhase.preview) ..._previewBody(),
          ],
        ),
      ),
    );
  }

  List<Widget> _recordingBody(AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    return <Widget>[
      Text(
        _denied ? l10n.micDeniedToast : _elapsedLabel,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          color: _denied ? scheme.error : scheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
      ),
      SizedBox(height: 14.h),
      if (_recording)
        _LiveAmplitudeBars(values: _bars, color: scheme.primary)
      else
        SizedBox(
          height: 64.h,
          child: Center(
            child: Text(l10n.voiceNoteRecHint, textAlign: TextAlign.center),
          ),
        ),
      SizedBox(height: 18.h),
      GestureDetector(
        onTap: _toggle,
        child: Container(
          width: 84.w,
          height: 84.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _recording ? scheme.errorContainer : scheme.primaryContainer,
            border: Border.all(color: scheme.primary.withValues(alpha: .4)),
          ),
          child: Icon(
            _recording ? Icons.stop_rounded : Icons.mic_rounded,
            size: 38.w,
            color: _recording ? scheme.error : scheme.primary,
          ),
        ),
      ),
      SizedBox(height: 10.h),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(l10n.cancel),
      ),
    ];
  }

  List<Widget> _previewBody() {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final controller = _previewController;
    return <Widget>[
      SizedBox(
        height: 72.h,
        width: double.infinity,
        child: controller != null && _previewReady
            ? aw.AudioFileWaveforms(
                size: Size(double.infinity, 72.h),
                playerController: controller,
                playerWaveStyle: aw.PlayerWaveStyle(
                  scaleFactor: 0.7,
                  fixedWaveColor: scheme.primary.withValues(alpha: .3),
                  liveWaveColor: scheme.primary,
                ),
                enableSeekGesture: true,
              )
            : const Center(child: CircularProgressIndicator()),
      ),
      SizedBox(height: 14.h),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          IconButton.filled(
            tooltip: _playing ? l10n.audioPause : l10n.audioPlay,
            iconSize: 30.w,
            onPressed: _togglePlayback,
            icon: Icon(
              _playing
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
            ),
          ),
          SizedBox(width: 20.w),
          TextButton.icon(
            onPressed: _reRecord,
            icon: const Icon(Icons.replay_rounded),
            label: Text(l10n.reRecord),
          ),
        ],
      ),
      SizedBox(height: 8.h),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _recordedPath == null ? null : _attach,
          icon: const Icon(Icons.attach_file_rounded),
          label: Text(l10n.attach),
        ),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(l10n.cancel),
      ),
    ];
  }
}

/// Draws the latest [values] (0..1) as rounded vertical bars, growing from the
/// baseline, while recording.
class _LiveAmplitudeBars extends StatelessWidget {
  const _LiveAmplitudeBars({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64.h,
      child: CustomPaint(
        painter: _BarsPainter(values: values, color: color),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const gap = 3.0;
    final barCount = values.length;
    final barWidth =
        ((size.width - gap * (barCount - 1)) / barCount).clamp(2.0, 14.0);
    final midY = size.height / 2;
    final maxHalf = size.height / 2 - 6;

    final paint = Paint()..color = color;
    for (var i = 0; i < barCount; i++) {
      final level = values[i].clamp(0.0, 1.0);
      final half = (0.15 + 0.85 * level) * maxHalf;
      final left = i * (barWidth + gap);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, midY - half, barWidth, half * 2),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}