import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Receives shares (text, links, images, files) sent from other apps.
///
/// Emits a [SharedPayload] per share event; the home screen opens the editor
/// pre-filled. All platform access is guarded so tests and unsupported
/// platforms never crash.
class ShareReceiver {
  ShareReceiver._();

  static StreamSubscription<List<SharedMediaFile>>? _subscription;
  static bool _initialized = false;

  /// Called for every incoming share (cold start included).
  static ValueChanged<SharedPayload>? onShare;

  static Future<void> init() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;
    try {
      final List<SharedMediaFile> initial = await ReceiveSharingIntent.instance
          .getInitialMedia();
      _handle(initial);
      _subscription = ReceiveSharingIntent.instance.getMediaStream().listen(
        _handle,
      );
    } on Exception {
      // Sharing stays unavailable; the app works fine without it.
    }
  }

  static Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    onShare = null;
  }

  static void _handle(List<SharedMediaFile> files) {
    if (files.isEmpty) return;
    final List<String> paths = <String>[];
    final StringBuffer text = StringBuffer();
    for (final SharedMediaFile f in files) {
      switch (f.type) {
        case SharedMediaType.text:
        case SharedMediaType.url:
          if (f.path.isNotEmpty) text.writeln(f.path);
        case SharedMediaType.image:
        case SharedMediaType.video:
        case SharedMediaType.file:
          if (f.path.isNotEmpty) paths.add(f.path);
      }
    }
    final SharedPayload payload = SharedPayload(
      text: text.isEmpty ? null : text.toString().trim(),
      paths: paths,
    );
    if (payload.isEmpty) return;
    onShare?.call(payload);
  }
}

/// A share reduced to what Notey needs.
class SharedPayload {
  SharedPayload({this.text, this.paths = const <String>[]});

  final String? text;
  final List<String> paths;

  bool get isEmpty => (text == null || text!.isEmpty) && paths.isEmpty;
}
