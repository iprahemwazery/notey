import 'package:notey/features/shell/domain/entities/shell_tab.dart';
import 'package:notey/features/shell/domain/repositories/shell_repository.dart';

/// Returns the full list of configured navigation tabs.
///
/// This is a pure read with no persistence — the tab definitions are
/// static and determined at compile time by the repository implementation.
class GetTabConfig {
  GetTabConfig(this._repository);

  final ShellRepository _repository;

  List<ShellTab> call() => _repository.getTabs();
}
