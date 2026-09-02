import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/constants/app_constants.dart';
import 'package:notey/core/theme/app_theme.dart';
import 'package:notey/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:notey/l10n/generated/app_localizations.dart';

import 'package:notey/widgets/auth/auth_widgets.dart';

/// "Enable biometrics?" offer screen in the first-run lock flow.
class BiometricOfferView extends StatelessWidget {
  const BiometricOfferView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
              child: AuthCardSurface(
                child: Column(
                  children: <Widget>[
                    Container(
                      width: 80.w,
                      height: 80.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[scheme.primary, scheme.tertiary],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.35),
                            blurRadius: 24.r,
                            spreadRadius: 2.r,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.fingerprint_rounded,
                        size: 40.w,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      l10n.biometricOfferTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      l10n.biometricOfferBody(AppConstants.appName),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: scheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.info_outline_rounded,
                            size: 18.w,
                            color: scheme.tertiary,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              l10n.biometricBackupNotice,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: scheme.onTertiaryContainer,
                                    height: 1.4,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),
                    SizedBox(
                      width: double.infinity,
                      height: 54.h,
                      child: FilledButton.icon(
                        onPressed: () =>
                            context.read<AuthCubit>().acceptBiometric(),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        icon: const Icon(Icons.fingerprint_rounded),
                        label: Text(l10n.enableBiometric),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => context.read<AuthCubit>().skipBiometric(),
                        child: Text(l10n.skipBiometric),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
