import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/theme/app_theme.dart';
import 'package:notey/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:notey/features/auth/presentation/cubits/auth_state.dart';
import 'package:notey/l10n/generated/app_localizations.dart';

import 'package:notey/widgets/auth/auth_widgets.dart';

/// "Device lock" setup screen for the first-run lock flow.
class DeviceSetupView extends StatelessWidget {
  const DeviceSetupView({super.key});

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
                child: BlocBuilder<AuthCubit, AuthState>(
                  buildWhen: (p, c) => p.phase != c.phase || p.error != c.error,
                  builder: (context, state) {
                    if (state.phase == AuthPhase.biometricVerifying) {
                      return Column(
                        children: <Widget>[
                          SizedBox(
                            width: 48.w,
                            height: 48.h,
                            child: const CircularProgressIndicator(),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            l10n.verifying,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: <Widget>[
                        Container(
                          width: 72.w,
                          height: 72.h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: <Color>[scheme.primary, scheme.tertiary],
                            ),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.phone_iphone_rounded,
                            size: 34.w,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          l10n.deviceSetupTitle,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          l10n.deviceSetupBody,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        if (state.error.isNotEmpty) ...<Widget>[
                          Text(
                            state.error,
                            style: TextStyle(
                              color: scheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 12.h),
                        ],
                        SizedBox(
                          width: double.infinity,
                          height: 54.h,
                          child: FilledButton.icon(
                            onPressed: () =>
                                context.read<AuthCubit>().authenticateDevice(),
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                            ),
                            icon: const Icon(Icons.fingerprint_rounded),
                            label: Text(l10n.tryNowButton),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {
                              context.read<AuthCubit>().goBackToChoosing();
                            },
                            child: Text(l10n.chooseAnotherMethod),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
