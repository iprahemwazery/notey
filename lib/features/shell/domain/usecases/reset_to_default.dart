import 'package:notey/features/shell/domain/repositories/shell_repository.dart';

/// Resets the active tab to the default (Home, index 0).
///
/// Useful after logout, data wipe, or any flow that should bring the
/// user back to the primary screen.
class ResetToDefault {
  ResetToDefault(this._repository);

  final ShellRepository _repository;

  Future<void> call() => _repository.resetToDefault();
}
