import 'package:flutter/material.dart';

import 'package:notey/l10n/generated/app_localizations.dart';
import 'package:notey/features/vault/model/vault_entry.dart';

import 'package:notey/features/vault/cubit/vault_state.dart';


/// Shared icon/color/label metadata for vault categories and filters so the
/// list, editor and detail screens stay consistent.
class VaultMeta {
  const VaultMeta._();

  static IconData iconFor(VaultCategory category) {
    return switch (category) {
      VaultCategory.login => Icons.key_rounded,
      VaultCategory.creditCard => Icons.credit_card_rounded,
      VaultCategory.bankAccount => Icons.account_balance_rounded,
      VaultCategory.secureNote => Icons.lock_rounded,
    };
  }

  static Color colorFor(VaultCategory category, ColorScheme scheme) {
    return switch (category) {
      VaultCategory.login => scheme.primary,
      VaultCategory.creditCard => scheme.tertiary,
      VaultCategory.bankAccount => scheme.secondary,
      VaultCategory.secureNote => scheme.error,
    };
  }

  static String labelFor(VaultCategory category, AppLocalizations l10n) {
    return switch (category) {
      VaultCategory.login => l10n.vaultFilterPasswords,
      VaultCategory.creditCard => l10n.vaultAddCard,
      VaultCategory.bankAccount => l10n.vaultAddBank,
      VaultCategory.secureNote => l10n.vaultAddSecureNote,
    };
  }

  /// The exact set of category chips requested for the vault: All, passwords,
  /// banking, documents, audio and canvas sketches.
  static const List<VaultFilter> filters = <VaultFilter>[
    VaultFilter.all,
    VaultFilter.passwords,
    VaultFilter.banking,
    VaultFilter.documents,
    VaultFilter.audio,
    VaultFilter.canvas,
  ];

  static IconData iconForFilter(VaultFilter filter) {
    return switch (filter) {
      VaultFilter.all => Icons.apps_rounded,
      VaultFilter.passwords => Icons.password_rounded,
      VaultFilter.banking => Icons.account_balance_rounded,
      VaultFilter.documents => Icons.description_rounded,
      VaultFilter.audio => Icons.graphic_eq_rounded,
      VaultFilter.canvas => Icons.brush_rounded,
    };
  }

  static String labelForFilter(VaultFilter filter, AppLocalizations l10n) {
    return switch (filter) {
      VaultFilter.all => l10n.vaultFilterAll,
      VaultFilter.passwords => l10n.vaultFilterPasswords,
      VaultFilter.banking => l10n.vaultFilterBanking,
      VaultFilter.documents => l10n.vaultFilterDocuments,
      VaultFilter.audio => l10n.vaultFilterAudio,
      VaultFilter.canvas => l10n.vaultFilterCanvas,
    };
  }
}

/// Visual metadata for the "add" bottom sheet options.
class VaultAddOption {
  const VaultAddOption({
    required this.category,
    required this.icon,
  });

  final VaultCategory category;
  final IconData icon;

  static const List<VaultAddOption> all = <VaultAddOption>[
    VaultAddOption(category: VaultCategory.login, icon: Icons.key_rounded),
    VaultAddOption(
      category: VaultCategory.creditCard,
      icon: Icons.credit_card_rounded,
    ),
    VaultAddOption(
      category: VaultCategory.bankAccount,
      icon: Icons.account_balance_rounded,
    ),
    VaultAddOption(
      category: VaultCategory.secureNote,
      icon: Icons.lock_rounded,
    ),
  ];
}