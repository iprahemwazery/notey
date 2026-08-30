import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/services/haptics.dart';

import 'package:notey/core/services/ui_prefs.dart';

import 'package:notey/core/theme/app_theme.dart';

import 'package:notey/l10n/generated/app_localizations.dart';

/// First-run welcome carousel. Shown once, before the lock-method setup.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;
  static const int _count = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await Haptics.light();
    await UiPrefs.setOnboardingDone();
    widget.onDone();
  }

  Future<void> _next() async {
    if (_page == _count - 1) {
      await _finish();
      return;
    }
    await Haptics.tap();
    await _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0, 4.h, 16.w, 0),
                  child: TextButton(
                    onPressed: _finish,
                    child: Text(
                      l10n.onbSkip,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .8),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (int i) => setState(() => _page = i),
                  children: <Widget>[
                    _Slide(
                      icon: Icons.sticky_note_2_rounded,
                      title: l10n.onbTitle1,
                      body: l10n.onbBody1,
                    ),
                    _Slide(
                      icon: Icons.dashboard_customize_rounded,
                      title: l10n.onbTitle2,
                      body: l10n.onbBody2,
                    ),
                    _Slide(
                      icon: Icons.lock_rounded,
                      title: l10n.onbTitle3,
                      body: l10n.onbBody3,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (int i = 0; i < _count; i++) ...<Widget>[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      width: i == _page ? 28.w : 8.w,
                      height: 8.h,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? Colors.white
                            : Colors.white.withValues(alpha: .3),
                        borderRadius: BorderRadius.circular(4.r),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: i == _page
                                ? Colors.white.withValues(alpha: .3)
                                : Colors.transparent,
                            blurRadius: i == _page ? 8.r : 0.r,
                            spreadRadius: i == _page ? 1.r : 0.r,
                          ),
                        ],
                      ),
                    ),
                    if (i != _count - 1) SizedBox(width: 8.w),
                  ],
                ],
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 20.h),
                child: SizedBox(
                  width: double.infinity,
                  height: 54.h,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: scheme.primary,
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    onPressed: _next,
                    child: Text(
                      _page == _count - 1 ? l10n.onbStart : l10n.onbNext,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Outer glow halo
          Container(
            width: 140.w,
            height: 140.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: <Color>[
                  Colors.white.withValues(alpha: .08),
                  Colors.white.withValues(alpha: .0),
                ],
              ),
            ),
            alignment: Alignment.center,
            child: Container(
              width: 112.w,
              height: 112.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Colors.white.withValues(alpha: .18),
                    Colors.white.withValues(alpha: .06),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .15),
                  width: 1.5,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.white.withValues(alpha: .06),
                    blurRadius: 24.r,
                    spreadRadius: 4.r,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 50.w, color: Colors.white),
            ),
          ),
          SizedBox(height: 36.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: .85),
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}
