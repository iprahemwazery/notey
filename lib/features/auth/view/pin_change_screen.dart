import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/services/app_lock_controller.dart';
import 'package:notey/core/services/haptics.dart';
import 'package:notey/l10n/generated/app_localizations.dart';
import 'package:notey/widgets/pin_widgets.dart';

/// Standalone screen for changing the app PIN (used from settings).
class PinChangeScreen extends StatefulWidget {
  const PinChangeScreen({super.key, required this.controller});

  final AppLockController controller;

  @override
  State<PinChangeScreen> createState() => _PinChangeScreenState();
}

class _PinChangeScreenState extends State<PinChangeScreen> {
  static const int _pinLength = 4;
  String _entered = '';
  String? _firstEntry;
  String _error = '';

  void _onDigit(String d) {
    if (_entered.length >= _pinLength) return;
    setState(() {
      _entered += d;
      _error = '';
    });
    if (_entered.length == _pinLength) {
      Future.delayed(const Duration(milliseconds: 160), _onEntered);
    }
  }

  Future<void> _onEntered() async {
    await Haptics.light();
    if (!mounted) return;
    if (_firstEntry == null) {
      setState(() {
        _firstEntry = _entered;
        _entered = '';
      });
      return;
    }
    if (_entered != _firstEntry) {
      await Haptics.heavy();
      if (!mounted) return;
      setState(() {
        _entered = '';
        _firstEntry = null;
        _error = AppLocalizations.of(context).pinMismatchError;
      });
      return;
    }
    await widget.controller.setPin(_entered);
    if (mounted) Navigator.of(context).pop(true);
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final confirming = _firstEntry != null;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(confirming ? l10n.pinConfirmTitle : l10n.changePin),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth =
                constraints.maxWidth > 520 ? 520.0 : constraints.maxWidth;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 28.w,
                    vertical: 16.h,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SizedBox(height: 24.h),
                      Container(
                        width: 64.w,
                        height: 64.h,
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
                          Icons.lock_outline_rounded,
                          size: 30.w,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        confirming
                            ? l10n.pinReenterPrompt
                            : l10n.pinEnterLength(_pinLength),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 24.h),
                      SizedBox(
                        height: 36.h,
                        child: PinDots(
                          length: _pinLength,
                          entered: _entered.length,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      SizedBox(
                        height: 22.h,
                        child: _error.isEmpty
                            ? null
                            : Text(
                                _error,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: scheme.error,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                      ),
                      SizedBox(height: 24.h),
                      PinKeypad(onDigit: _onDigit, onBackspace: _onBackspace),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
