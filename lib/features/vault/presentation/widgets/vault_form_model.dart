import 'dart:math';

import 'package:notey/features/vault/domain/entities/vault_entry.dart'
    show VaultCategory;

/// Describes one generated field in the vault form.
class VaultFieldSpec {
  const VaultFieldSpec(this.key, this.obscure);

  final String key;
  final bool obscure;

  /// True when this field offers a "generate password" action.
  bool get canGenerate => key == 'password';
}

/// Pure form/model logic for the vault editor: which fields each category
/// exposes, and how to generate a random password. Kept out of the widget tree
/// so it can be unit-tested and reused.
class VaultFormModel {
  VaultFormModel._();

  static const List<VaultFieldSpec> _login = <VaultFieldSpec>[
    VaultFieldSpec('username', false),
    VaultFieldSpec('password', true),
  ];

  static const List<VaultFieldSpec> _card = <VaultFieldSpec>[
    VaultFieldSpec('cardHolder', false),
    VaultFieldSpec('cardNumber', false),
    VaultFieldSpec('expiry', false),
    VaultFieldSpec('cvv', true),
    VaultFieldSpec('cardPin', true),
  ];

  static const List<VaultFieldSpec> _bank = <VaultFieldSpec>[
    VaultFieldSpec('bankName', false),
    VaultFieldSpec('accountName', false),
    VaultFieldSpec('iban', false),
    VaultFieldSpec('swift', false),
  ];

  /// Default field specs for a given category.
  static List<VaultFieldSpec> specsFor(VaultCategory category) {
    return switch (category) {
      VaultCategory.login => _login,
      VaultCategory.creditCard => _card,
      VaultCategory.bankAccount => _bank,
      VaultCategory.secureNote => const <VaultFieldSpec>[],
    };
  }

  static final Random _random = Random.secure();

  static const String _letters =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _digits = '0123456789';
  static const String _symbols = '!@#\$%^&*()-_=+';

  /// Generates a 20-character password from a mixed character pool.
  static String generatePassword() {
    final pool = _letters + _digits + _symbols;
    final buffer = StringBuffer();
    for (var i = 0; i < 20; i++) {
      buffer.write(pool[_random.nextInt(pool.length)]);
    }
    return buffer.toString();
  }
}
