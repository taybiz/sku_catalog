import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Checks if setting a new parent would create a cycle in a self-referential
/// tree.
class WouldCreateTreeCycle {
  /// Creates a [WouldCreateTreeCycle] use case.
  const WouldCreateTreeCycle();

  /// Returns `true` if setting [newParentId] as parent of [itemId]
  /// would create a cycle.
  TaskEither<DomainFailure, bool> call({
    required List<Map<String, dynamic>> items,
    required String itemId,
    required String newParentId,
    String parentKey = 'parent_id',
  }) {
    if (itemId == newParentId) return TaskEither.of(true);

    final itemMap = {for (final item in items) item['id'] as String: item};
    final visited = <String>{};
    var currentId = newParentId;

    while (currentId.isNotEmpty && visited.add(currentId)) {
      if (currentId == itemId) return TaskEither.of(true);
      final item = itemMap[currentId];
      if (item == null) break;
      currentId = (item[parentKey] as String?) ?? '';
    }

    return TaskEither.of(false);
  }
}
