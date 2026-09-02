/// App-lock brute-force protection policy: how many failed attempts are
/// tolerated before the unlock flow locks out, and for how long.
class LockoutPolicy {
  const LockoutPolicy._(this.maxAttempts, this.lockoutSeconds);

  /// Default policy: 5 failed attempts then a 30s lockout.
  static const LockoutPolicy defaultPolicy = LockoutPolicy._(5, 30);

  /// Maximum consecutive failed attempts before locking out.
  final int maxAttempts;

  /// How long the unlock flow stays locked out once the limit is breached.
  final int lockoutSeconds;

  @override
  bool operator ==(Object other) =>
      other is LockoutPolicy &&
      other.maxAttempts == maxAttempts &&
      other.lockoutSeconds == lockoutSeconds;

  @override
  int get hashCode => Object.hash(maxAttempts, lockoutSeconds);

  @override
  String toString() =>
      'LockoutPolicy(maxAttempts: $maxAttempts, lockoutSeconds: $lockoutSeconds)';
}
