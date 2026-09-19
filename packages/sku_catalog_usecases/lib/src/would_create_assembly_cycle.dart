import 'package:sku_catalog_domain/sku_catalog_domain.dart';
import 'package:fpdart/fpdart.dart';

/// Checks if adding an assembly edge would create a cycle.
class WouldCreateAssemblyCycle {
  /// Creates a [WouldCreateAssemblyCycle] use case.
  const WouldCreateAssemblyCycle(this._repository);

  final ISkuComponentRepository _repository;

  /// Returns `true` if adding an edge from [parentDeviceTypeId] to
  /// [childDeviceTypeId] would create a cycle.
  TaskEither<DomainFailure, bool> call(
    String parentDeviceTypeId,
    String childDeviceTypeId,
  ) {
    if (parentDeviceTypeId == childDeviceTypeId) return TaskEither.of(true);

    return _repository.fetchAll().map((components) {
      final adj = <String, List<String>>{};
      for (final comp in components) {
        adj
            .putIfAbsent(comp.parentDeviceTypeId, () => [])
            .add(comp.childDeviceTypeId);
      }

      final visited = <String>{};
      final queue = [childDeviceTypeId];
      while (queue.isNotEmpty) {
        final current = queue.removeLast();
        if (current == parentDeviceTypeId) return true;
        if (!visited.add(current)) continue;
        for (final neighbor in (adj[current] ?? [])) {
          queue.add(neighbor);
        }
      }
      return false;
    });
  }
}
