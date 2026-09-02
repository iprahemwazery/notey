import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/l10n/generated/app_localizations.dart';

/// One vault form field. Optionally provides a "generate password" refresh
/// action for password fields.
class VaultFieldRow extends StatelessWidget {
  const VaultFieldRow({
    super.key,
    required this.controller,
    required this.label,
    this.obscure = false,
    this.onGenerate,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback? onGenerate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: controller,
      obscureText: obscure,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r)),
        suffixIcon: onGenerate != null
            ? IconButton(
                tooltip: l10n.vaultGeneratePassword,
                onPressed: onGenerate,
                icon: const Icon(Icons.refresh_rounded),
              )
            : null,
      ),
    );
  }
}
