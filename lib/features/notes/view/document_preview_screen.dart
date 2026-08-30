import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';
import 'package:photo_view/photo_view.dart';

import 'package:notey/core/services/haptics.dart';

import 'package:notey/core/services/share_service.dart';

import 'package:notey/l10n/generated/app_localizations.dart';

/// Rich-media reader for a single file path.
///
/// - PDFs render inside a zoomable [PdfViewer].
/// - Images render inside a zoomable, swipe-dismissable [PhotoView].
/// - Audio files get an in-app [AudioPreview] (audioplayers).
/// - Everything else is handed to the OS via [OpenFilex] in [initState], and
///   this widget degrades to a "share / open externally" card.
class DocumentPreviewScreen extends StatefulWidget {
  const DocumentPreviewScreen({super.key, required this.path});

  final String path;

  @override
  State<DocumentPreviewScreen> createState() => _DocumentPreviewScreenState();
}

enum _DocumentKind { pdf, image, audio, unknown }

_DocumentKind _kindFor(String path) {
  final ext = p.extension(path).toLowerCase();
  if (ext == '.pdf') return _DocumentKind.pdf;
  if (const <String>[
    '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.heic',
  ].contains(ext)) {
    return _DocumentKind.image;
  }
  if (const <String>[
    '.mp3', '.m4a', '.aac', '.wav', '.ogg', '.opus', '.flac', '.amr', '.aiff',
  ].contains(ext)) {
    return _DocumentKind.audio;
  }
  return _DocumentKind.unknown;
}

class _DocumentPreviewScreenState extends State<DocumentPreviewScreen> {
  late final _DocumentKind _kind = _kindFor(widget.path);
  bool _openedExternally = false;

  @override
  void initState() {
    super.initState();
    if (_kind == _DocumentKind.unknown) {
      _openEnum(widget.path);
    }
  }

  Future<void> _openEnum(String path) async {
    final result = await OpenFilex.open(path);
    if (!mounted) return;
    setState(() => _openedExternally = _resultSucceeded(result));
  }

  bool _resultSucceeded(OpenResult result) => result.type == ResultType.done;

  AppLocalizations get l10n => AppLocalizations.of(context);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(p.basename(widget.path), overflow: TextOverflow.ellipsis),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.vaultShareLabel,
            onPressed: _shareCurrent,
            icon: const Icon(Icons.share_rounded),
          ),
        ],
      ),
      body: switch (_kind) {
        _DocumentKind.pdf => PdfViewer.file(
          widget.path,
          params: const PdfViewerParams(
            margin: 0,
            backgroundColor: Colors.transparent,
          ),
        ),
        _DocumentKind.image => _readableImage(),
        _DocumentKind.audio => AudioPreview(path: widget.path),
        _DocumentKind.unknown => _externalFallback(),
      },
    );
  }

  Future<void> _shareCurrent() async {
    await Haptics.tap();
    await ShareService.shareFiles(<String>[widget.path]);
  }

  Future<void> _retryExternal() async {
    await Haptics.tap();
    await _openEnum(widget.path);
  }

  Widget _readableImage() {
    return PhotoView(
      imageProvider: FileImage(File(widget.path)),
      backgroundDecoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 4,
    );
  }

  Widget _externalFallback() {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.description_outlined, size: 72.w, color: scheme.primary),
            SizedBox(height: 16.h),
            Text(
              _openedExternally
                  ? l10n.documentHandedToExternal
                  : l10n.documentNoAppHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 20.h),
            Wrap(
              spacing: 8.w,
              alignment: WrapAlignment.center,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: _retryExternal,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(l10n.documentOpenExternal),
                ),
                OutlinedButton.icon(
                  onPressed: _shareCurrent,
                  icon: const Icon(Icons.share_rounded),
                  label: Text(l10n.vaultShareLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// In-app audio player with progress bar and play/pause (audioplayers).
class AudioPreview extends StatefulWidget {
  const AudioPreview({super.key, required this.path});

  final String path;

  @override
  State<AudioPreview> createState() => _AudioPreviewState();
}

class _AudioPreviewState extends State<AudioPreview> {
  AudioPlayer? _player;
  bool _initializing = true;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration? _duration;
  bool _faulted = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final player = AudioPlayer()
        ..onPositionChanged.listen(_onPosition)
        ..onDurationChanged.listen(_onDuration)
        ..onPlayerComplete.listen((_) => _onComplete());
      await player.play(DeviceFileSource(widget.path));
      if (!mounted) {
        await player.dispose();
        return;
      }
      setState(() {
        _player = player;
        _playing = true;
        _initializing = false;
      });
    } on Exception {
      if (mounted) {
        setState(() {
          _faulted = true;
          _initializing = false;
        });
      }
    }
  }

  void _onPosition(Duration position) {
    if (mounted) setState(() => _position = position);
  }

  void _onDuration(Duration duration) {
    if (mounted) setState(() => _duration = duration);
  }

  void _onComplete() {
    if (mounted) {
      setState(() {
        _playing = false;
        _position = _duration ?? Duration.zero;
      });
    }
  }

  Future<void> _toggle() async {
    final player = _player;
    if (player == null) return;
    if (_playing) {
      await player.pause();
      if (mounted) setState(() => _playing = false);
    } else {
      await player.resume();
      if (mounted) setState(() => _playing = true);
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    if (_initializing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_faulted) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Text(
            l10n.documentPlaybackFailed,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final duration = _duration ?? Duration.zero;
    final remaining = duration > _position ? duration - _position : Duration.zero;
    final progress = duration.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircleAvatar(
            radius: 56.r,
            backgroundColor: scheme.primary.withValues(alpha: .12),
            child: Icon(
              Icons.graphic_eq_rounded,
              size: 48.w,
              color: scheme.primary,
            ),
          ),
          SizedBox(height: 32.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6.h,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(_two(_position.inMinutes, _position.inSeconds.remainder(60))),
              Text(_two(remaining.inMinutes, remaining.inSeconds.remainder(60))),
            ],
          ),
          SizedBox(height: 16.h),
          IconButton.filled(
            iconSize: 40.w,
            onPressed: _toggle,
            icon: Icon(
              _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
          ),
        ],
      ),
    );
  }

  String _two(int minutes, int seconds) {
    final m = minutes.toString().padLeft(2, '0');
    final s = seconds.toString().padLeft(2, '0');
    return '$m:$s';
  }
}