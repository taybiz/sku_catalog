import 'package:sku_catalog_domain/sku_catalog_domain.dart';
import 'package:fpdart/fpdart.dart';

/// Collects all descendant locate IDs from a root.
class DescendantLocateIds {
  /// Creates a [DescendantLocateIds] use case.
  const DescendantLocateIds(this._locateRepository);

  final ILocateRepository _locateRepository;

  /// Returns all descendant locate IDs, optionally including the root.
  TaskEither<DomainFailure, List<String>> call(
    String rootId, {
    bool includeSelf = false,
  }) => _locateRepository.fetchAll().map((allLocates) {
    final adj = <String, List<String>>{};
    for (final locate in allLocates) {
      final parentId = locate.parentLocateId;
      if (parentId != null) {
        adj.putIfAbsent(parentId, () => []).add(locate.meta.id);
      }
    }

    final result = <String>[];
    final visited = <String>{};
    final queue = [rootId];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (!visited.add(current)) continue;
      if (includeSelf || current != rootId) {
        result.add(current);
      }
      for (final child in (adj[current] ?? [])) {
        queue.add(child);
      }
    }

    return result;
  });
}
