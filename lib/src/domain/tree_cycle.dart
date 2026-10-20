/// One node of a self-referential tree: its id, and its parent's id.
///
/// A record rather than a JSON row, so this rule serves every tree the model grows —
/// places, traits — without a wire key deciding what it means.
typedef ParentLink = ({String id, String? parentId});

/// Whether making [parentId] the parent of [nodeId] would close a loop.
///
/// Walks up from the proposed parent: reaching [nodeId] means the node would end up
/// inside itself. A null parent is a root, which cannot loop, and a parent nobody
/// knows ends the walk — "that place does not exist" is the caller's question.
bool wouldCreateTreeCycle({
  required Iterable<ParentLink> links,
  required String nodeId,
  required String? parentId,
}) {
  final parentOf = {for (final link in links) link.id: link.parentId};
  final visited = <String>{};
  var current = parentId;

  while (current != null && visited.add(current)) {
    if (current == nodeId) return true;
    current = parentOf[current];
  }

  return false;
}
