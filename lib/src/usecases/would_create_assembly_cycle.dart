import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Checks if adding an assembly edge would create a cycle.
class WouldCreateAssemblyCycle {
  /// Creates a [WouldCreateAssemblyCycle] use case.
  const WouldCreateAssemblyCycle(this._repository);

  final ISkuComponentRepository _repository;

  /// Returns `true` if adding an edge from [parentSkuId] to
  /// [childSkuId] would create a cycle.
  TaskEither<DomainFailure, bool> call(String parentSkuId, String childSkuId) {
    if (parentSkuId == childSkuId) return TaskEither.of(true);

    return _repository.fetchAll().map((components) {
      final adj = <String, List<String>>{};
      for (final comp in components) {
        adj.putIfAbsent(comp.parentSkuId, () => []).add(comp.childSkuId);
      }

      final visited = <String>{};
      final queue = [childSkuId];
      while (queue.isNotEmpty) {
        final current = queue.removeLast();
        if (current == parentSkuId) return true;
        if (!visited.add(current)) continue;
        for (final neighbor in (adj[current] ?? [])) {
          queue.add(neighbor);
        }
      }
      return false;
    });
  }
}
