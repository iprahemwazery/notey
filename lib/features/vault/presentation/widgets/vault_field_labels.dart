import 'package:notey/l10n/generated/app_localizations.dart';

/// Human label for a vault field key, shared by the detail + editor screens so
/// the field labels never drift apart (DRY).
String vaultFieldLabel(String key, AppLocalizations l10n) {
  return switch (key) {
    'username' => l10n.vaultFieldUsername,
    'password' => l10n.vaultFieldPassword,
    'cardHolder' => l10n.vaultFieldCardHolder,
    'cardNumber' => l10n.vaultFieldCardNumber,
    'expiry' => l10n.vaultFieldExpiry,
    'cvv' => l10n.vaultFieldCvv,
    'cardPin' => l10n.vaultFieldCardPin,
    'bankName' => l10n.vaultFieldBankName,
    'accountName' => l10n.vaultFieldAccountName,
    'iban' => l10n.vaultFieldIban,
    'swift' => l10n.vaultFieldSwift,
    _ => key,
  };
}

/// Keys whose values are considered sensitive and hidden until revealed in the
/// detail screen.
bool isSensitiveVaultField(String key) =>
    key == 'password' || key == 'cvv' || key == 'cardPin' || key == 'iban';
