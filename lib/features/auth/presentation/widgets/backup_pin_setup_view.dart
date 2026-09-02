import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/theme/app_theme.dart';
import 'package:notey/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:notey/features/auth/presentation/cubits/auth_state.dart';
import 'package:notey/l10n/generated/app_localizations.dart';

import 'package:notey/widgets/auth/auth_widgets.dart';

/// Backup-PIN create/confirm screen in the first-run lock flow.
class BackupPinSetupView extends StatelessWidget {
  const BackupPinSetupView({super.key});

  static const int _pinLength = 4;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final confirming = state.phase == AuthPhase.backupPinConfirm;
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 28.w,
                    vertical: 16.h,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      AuthLogoBadge(icon: Icons.pin_rounded, size: 72),
                      SizedBox(height: 20.h),
                      Text(
                        confirming ? l10n.pinConfirmTitle : l10n.pinBackupTitle,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        confirming ? l10n.pinReenterPrompt : l10n.backupPinBody,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                      SizedBox(height: 36.h),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 400.w),
                        child: PinEntryCardWidget(
                          pinLength: _pinLength,
                          entered: state.backupPin.length,
                          error: state.error,
                          onDigit: (d) =>
                              context.read<AuthCubit>().onPinDigit(d),
                          onBackspace: () =>
                              context.read<AuthCubit>().onPinBackspace(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
