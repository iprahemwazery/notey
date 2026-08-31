import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/theme/app_theme.dart';
import 'package:notey/features/auth/cubit/auth_cubit.dart';
import 'package:notey/features/auth/cubit/auth_state.dart';
import 'package:notey/l10n/generated/app_localizations.dart';

import '../../../../../widgets/auth/auth_widgets.dart';

/// Primary PIN create/confirm screen in the first-run lock flow.
class PinSetupView extends StatefulWidget {
  const PinSetupView({super.key});

  @override
  State<PinSetupView> createState() => _PinSetupViewState();
}

class _PinSetupViewState extends State<PinSetupView> {
  static const int _pinLength = 4;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final confirming = state.phase == AuthPhase.passwordConfirm;
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
                      AuthLogoBadge(icon: Icons.lock_outline_rounded, size: 72),
                      SizedBox(height: 20.h),
                      Text(
                        confirming ? l10n.pinConfirmTitle : l10n.pinCreateTitle,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        confirming ? l10n.pinReenterPrompt : l10n.pinEnterLength(_pinLength),
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
                          entered: state.pin.length,
                          error: state.error,
                          onDigit: (d) =>
                              context.read<AuthCubit>().onPinDigit(d),
                          onBackspace: () =>
                              context.read<AuthCubit>().onPinBackspace(),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      TextButton(
                        onPressed: () {
                          context.read<AuthCubit>().goBackToChoosing();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withValues(alpha: 0.8),
                        ),
                        child: Text(l10n.chooseAnotherMethod),
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
