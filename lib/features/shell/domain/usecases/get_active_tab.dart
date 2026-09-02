import 'package:notey/features/shell/domain/repositories/shell_repository.dart';

/// Retrieves the last active tab index from persistence.
///
/// Returns 0 (Home) on first launch when no tab has been saved yet.
class GetActiveTab {
  GetActiveTab(this._repository);

  final ShellRepository _repository;

  Future<int> call() => _repository.getActiveTab();
}
