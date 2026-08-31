import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/l10n/generated/app_localizations.dart';
import 'package:notey/widgets/pin_widgets.dart';

/// A tappable lock-method card.
class AuthOptionCardWidget extends StatelessWidget {
  const AuthOptionCardWidget({
    super.key,
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
    this.recommended = false,
    required this.onTap,
  });

  final IconData icon;
  final Gradient gradient;
  final String title;
  final String subtitle;
  final bool recommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(24.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(24.r),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 56.w,
                height: 56.h,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12.r,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: Colors.white, size: 28.w),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        if (recommended)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999.r),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              isArabic ? 'موصى به' : 'Recommended',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.6),
                size: 18.w,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Privacy footer for the lock-method choice screen.
class SecurityFooterWidget extends StatelessWidget {
  const SecurityFooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
          width: 1,
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.privacy_tip_rounded,
            size: 18.w,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              isArabic
                  ? 'ملاحظاتك تبقى خاصة على الجهاز مع خيارات حماية متقدمة.'
                  : 'Your notes stay private on this device with advanced protection.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Best for most users" hint pill.
class RecommendedHintWidget extends StatelessWidget {
  const RecommendedHintWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999.r),
        ),
        child: Text(
          isArabic ? 'الأفضل: قفل الجهاز' : 'Best for most users: Device lock',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// "Why this is recommended" info pill that opens an explanatory dialog.
class WhyThisMattersWidget extends StatelessWidget {
  const WhyThisMattersWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        borderRadius: BorderRadius.circular(999.r),
        onTap: () {
          showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text(isArabic ? 'لماذا قفل الجهاز؟' : 'Why device lock?'),
              content: Text(
                isArabic
                    ? 'قفل الجهاز يعتمد على قفل هاتفك نفسه؛ لذلك يضمن وصولًا أسرع وأمانًا أعلى، ويقلل الحاجة إلى حفظ رقم سري إضافي في التطبيق.'
                    : 'Device lock uses your phone’s secure unlock to keep notes private with minimal friction and a simpler setup flow.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(isArabic ? 'حسنًا' : 'Okay'),
                ),
              ],
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.info_outline_rounded,
                size: 14.w,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              SizedBox(width: 6.w),
              Text(
                isArabic ? 'لماذا هذا الأفضل؟' : 'Why this is recommended?',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small pill chip (icon + label) used on the lock-method choice screen.
class BenefitChipWidget extends StatelessWidget {
  const BenefitChipWidget({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14.w, color: Colors.white),
          SizedBox(width: 6.w),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular white-glass logo badge for auth screens.
class AuthLogoBadge extends StatelessWidget {
  const AuthLogoBadge({super.key, required this.icon, this.size = 80});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size.w,
      height: size.h,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 20.r,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: (size * 0.42).w, color: scheme.primary),
    );
  }
}

/// White rounded card surface used inside auth screens.
class AuthCardSurface extends StatelessWidget {
  const AuthCardSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 30.r,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A PIN dots + error + keypad column shared by PIN-entry screens.
class PinEntryCardWidget extends StatelessWidget {
  const PinEntryCardWidget({
    super.key,
    required this.pinLength,
    required this.entered,
    required this.error,
    required this.onDigit,
    required this.onBackspace,
  });

  final int pinLength;
  final int entered;
  final String error;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return AuthCardSurface(
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 36.h,
            child: PinDots(length: pinLength, entered: entered),
          ),
          SizedBox(height: 8.h),
          SizedBox(
            height: 24.h,
            child: error.isNotEmpty
                ? Text(
                    error == 'pinMismatchError' ? l10n.pinMismatchError : error,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          SizedBox(height: 16.h),
          PinKeypad(onDigit: onDigit, onBackspace: onBackspace),
        ],
      ),
    );
  }
}
