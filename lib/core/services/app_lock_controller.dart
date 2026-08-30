import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'crypto_service.dart';

enum AppLockMethod { biometric, device, pin, none }

/// Persists and enforces the app-lock choice (first-run setup → unlock gate).
/// The PIN hash lives in secure storage; the (non-secret) method name lives
/// in SharedPreferences.
class AppLockController extends ChangeNotifier {
  AppLockController({FlutterSecureStorage? secureStorage})
    : _secure = secureStorage ?? const FlutterSecureStorage();

  static const String _methodKey = 'appLockMethod';
  static const String _pinKey = 'appPinHash';

  final FlutterSecureStorage _secure;

  SharedPreferences? _prefs;
  AppLockMethod? _method;
  bool _initialized = false;

  bool get initialized => _initialized;
  AppLockMethod? get method => _method;

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs!.getString(_methodKey);
      if (raw != null) {
        _method = AppLockMethod.values.asNameMap()[raw] ?? AppLockMethod.none;
      }
    } on Exception catch (e) {
      // Failsafe: an unreadable lock preference must never strand the app on
      // the loading screen. Fall back to opening without a lock so the app
      // always completes boot.
      debugPrint('AppLockController.init failed — falling back to no lock: $e');
      _method = AppLockMethod.none;
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> setMethod(AppLockMethod method) async {
    _method = method;
    await _prefs?.setString(_methodKey, method.name);
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    await _secure.write(key: _pinKey, value: await PinHasher.create(pin));
  }

  Future<bool> verifyPin(String pin) async {
    var stored = await _readPinHash();
    // Migration: read a legacy hash from SharedPreferences once, then move it.
    stored ??= _prefs?.getString(_pinKey);
    if (stored == null) return false;
    final ok = await PinHasher.verify(pin, stored);
    if (ok && stored == (_prefs?.getString(_pinKey))) {
      await _secure.write(key: _pinKey, value: stored);
      await _prefs?.remove(_pinKey);
    }
    return ok;
  }

  Future<String?> _readPinHash() async {
    try {
      return await _secure.read(key: _pinKey);
    } on Exception {
      return null;
    }
  }

  /// For test convenience / reset.
  Future<void> reset() async {
    _method = null;
    await _prefs?.remove(_methodKey);
    await _prefs?.remove(_pinKey);
    try {
      await _secure.delete(key: _pinKey);
    } on Exception {
      // Ignore — nothing to clear.
    }
    notifyListeners();
  }
}
