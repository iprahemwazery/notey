import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PinDots extends StatelessWidget {
  const PinDots({
    super.key,
    required this.length,
    required this.entered,
    this.color,
  });

  final int length;
  final int entered;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = color ?? scheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(length, (index) {
        final filled = index < entered;
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: filled ? 1 : 0, end: filled ? 1 : 0),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          builder: (context, value, _) {
            // The overshooting easeOutBack curve can extrapolate `value`
            // outside [0,1] (e.g. below zero when a dot shrinks back to empty),
            // which would produce a negative blurRadius and crash Flutter's
            // assertion. Clamp the derived radii to stay strictly >= 0.
            final blurRadius = (value * 10.r).clamp(0.0, double.infinity);
            final spreadRadius = (value * 1.r).clamp(0.0, double.infinity);
            return Container(
              width: 18.w,
              height: 18.h,
              margin: EdgeInsets.symmetric(horizontal: 8.w),
              decoration: BoxDecoration(
                color: filled ? active : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: filled ? active : scheme.outlineVariant,
                  width: 2,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Color.lerp(
                      Colors.transparent,
                      active.withValues(alpha: 0.35),
                      value.clamp(0.0, 1.0),
                    )!,
                    blurRadius: blurRadius,
                    spreadRadius: spreadRadius,
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}

class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.biometricIcon,
    this.onBiometric,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final IconData? biometricIcon;
  final VoidCallback? onBiometric;

  static const List<String> _keys = <String>[
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget key(String label, {VoidCallback? onTap, Widget? child}) {
      return AspectRatio(
        aspectRatio: 1,
        child: Container(
          margin: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                scheme.surfaceContainerHighest.withValues(alpha: .7),
                scheme.surfaceContainerHigh.withValues(alpha: .5),
              ],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: scheme.shadow.withValues(alpha: .06),
                blurRadius: 6.r,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Center(
                child:
                    child ??
                    Text(
                      label,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                            fontSize: 24.sp,
                            letterSpacing: 0.5.sp,
                          ),
                    ),
              ),
            ),
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final keypadWidth = (screenWidth > 480 ? 320.0 : screenWidth * 0.8).clamp(
      240.0,
      320.0,
    );

    return SizedBox(
      width: keypadWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (var row = 0; row < 3; row++) ...<Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                for (var col = 0; col < 3; col++)
                  Expanded(
                    child: key(
                      _keys[row * 3 + col],
                      onTap: () => onDigit(_keys[row * 3 + col]),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Expanded(
                child: (biometricIcon != null && onBiometric != null)
                    ? AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          margin: EdgeInsets.all(4.w),
                          child: IconButton(
                            onPressed: onBiometric,
                            iconSize: 28.w,
                            icon: Icon(biometricIcon, color: scheme.primary),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Expanded(child: key('0', onTap: () => onDigit('0'))),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    margin: EdgeInsets.all(4.w),
                    child: IconButton(
                      onPressed: onBackspace,
                      iconSize: 26.w,
                      icon: Icon(
                        Icons.backspace_outlined,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
