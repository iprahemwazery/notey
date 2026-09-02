import 'package:notey/features/shell/domain/repositories/shell_repository.dart';

/// Persists the currently selected tab index so the app can restore it
/// on the next cold start.
class SetActiveTab {
  SetActiveTab(this._repository);

  final ShellRepository _repository;

  Future<void> call(int index) => _repository.setActiveTab(index);
}
