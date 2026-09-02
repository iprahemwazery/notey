import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/constants/app_constants.dart';
import 'package:notey/core/theme/app_theme.dart';
import 'package:notey/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:notey/l10n/generated/app_localizations.dart';

import 'package:notey/widgets/auth/auth_widgets.dart';

/// Landing "choose your lock method" screen in the first-run flow.
class ChoosingView extends StatelessWidget {
  const ChoosingView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth =
                  constraints.maxWidth > 520 ? 520.0 : constraints.maxWidth;
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 24.h,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        AuthLogoBadge(icon: Icons.lock_outline_rounded, size: 80),
                        SizedBox(height: 20.h),
                        Text(
                          l10n.welcomeTitle(AppConstants.appName),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          l10n.chooseLockSubtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.92),
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 18.h),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: <Widget>[
                            BenefitChipWidget(
                              icon: Icons.shield_rounded,
                              label: isArabic ? 'أمان' : 'Secure',
                            ),
                            BenefitChipWidget(
                              icon: Icons.speed_rounded,
                              label: isArabic ? 'سرعة' : 'Fast',
                            ),
                            BenefitChipWidget(
                              icon: Icons.backup_rounded,
                              label: isArabic ? 'نسخ احتياطي' : 'Backup',
                            ),
                          ],
                        ),
                        SizedBox(height: 28.h),
                        AuthOptionCardWidget(
                          icon: Icons.phone_iphone_rounded,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              scheme.primary,
                              scheme.primary.withValues(alpha: 0.8),
                            ],
                          ),
                          title: l10n.lockOptionDeviceTitle,
                          subtitle: l10n.lockOptionDeviceSubtitle,
                          recommended: true,
                          onTap: () => context.read<AuthCubit>().chooseDevice(),
                        ),
                        SizedBox(height: 16.h),
                        AuthOptionCardWidget(
                          icon: Icons.password_rounded,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              scheme.tertiary,
                              scheme.tertiary.withValues(alpha: 0.8),
                            ],
                          ),
                          title: l10n.lockOptionPasswordTitle,
                          subtitle: l10n.lockOptionPasswordSubtitle,
                          onTap: () => context.read<AuthCubit>().choosePassword(),
                        ),
                        SizedBox(height: 20.h),
                        const SecurityFooterWidget(),
                        SizedBox(height: 12.h),
                        const RecommendedHintWidget(),
                        SizedBox(height: 12.h),
                        const WhyThisMattersWidget(),
                        SizedBox(height: 18.h),
                        TextButton(
                          onPressed: () => context.read<AuthCubit>().chooseSkip(),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white.withValues(alpha: 0.8),
                            textStyle: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15.sp,
                            ),
                          ),
                          child: Text(l10n.lockOptionSkip),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
