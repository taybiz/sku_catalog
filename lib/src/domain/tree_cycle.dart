/// One node of a self-referential tree: its id, and its parent's id.
///
/// The shape a tree walk needs and nothing more, so [wouldCreateTreeCycle] serves
/// any tree the model grows — places, traits — without knowing what its nodes are.
/// A `Map<String, dynamic>` row plus a key name would do the same job and drag a
/// wire format into a rule: the field name is storage's business, and a rule that
/// reads it stops being true when the wire changes.
typedef ParentLink = ({String id, String? parentId});

/// Whether making [parentId] the parent of [nodeId] would close a loop.
///
/// Walks up from the proposed parent, holding the parents it has seen: if the walk
/// reaches [nodeId], the node would end up inside itself. A null [parentId] makes
/// the node a root, which can never loop, and a parent nobody knows ends the walk
/// — "that place does not exist" is the caller's own question, not this rule's.
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
