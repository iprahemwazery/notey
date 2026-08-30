import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/l10n/generated/app_localizations.dart';

/// Full-screen, pinch-to-zoom image viewer with swipe between images.
class ImageViewerScreen extends StatefulWidget {
  const ImageViewerScreen({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  final List<String> images;
  final int initialIndex;

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;
  final Set<int> _precacheTargets = <int>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _precacheAround(widget.initialIndex);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Bounded decode target for a full-screen page: the physical screen size.
  /// Caps memory usage for very large images without visible quality loss.
  int get _decodeWidth {
    final size = MediaQuery.sizeOf(context);
    return (size.shortestSide * MediaQuery.devicePixelRatioOf(context)).round();
  }

  void _precacheAround(int center) {
    final cap = _decodeWidth;
    for (final offset in const <int>[-1, 0, 1, 2]) {
      final i = center + offset;
      if (i >= 0 && i < widget.images.length && !_precacheTargets.contains(i)) {
        _precacheTargets.add(i);
        final file = File(widget.images[i]);
        if (file.existsSync()) {
          precacheImage(
            ResizeImage(FileImage(file), width: cap),
            context,
            onError: (_, _) {},
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          AppLocalizations.of(
            context,
          ).imageOfTotal(_index + 1, widget.images.length),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() => _index = index);
          _precacheAround(index);
        },
        itemBuilder: (context, index) {
          final path = widget.images[index];
          final file = File(path);
          if (!file.existsSync()) {
            return Center(
              child: Icon(Icons.broken_image_outlined, size: 72.w, color: Colors.white38),
            );
          }
          return InteractiveViewer(
            maxScale: 5,
            minScale: 0.5,
            child: Center(
              child: Image.file(
                file,
                fit: BoxFit.contain,
                cacheWidth: _decodeWidth,
                errorBuilder: (_, _, _) => Icon(
                  Icons.broken_image_outlined,
                  size: 72.w,
                  color: Colors.white38,
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (var i = 0; i < widget.images.length; i++)
                Container(
                  width: 8.w,
                  height: 8.h,
                  margin: EdgeInsets.symmetric(horizontal: 3.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _index ? scheme.primary : Colors.white30,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
