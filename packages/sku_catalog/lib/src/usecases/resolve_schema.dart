import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

import 'resolve_trait_chain.dart';

/// Resolves the full attribute schema for a set of trait IDs.
class ResolveSchema {
  /// Creates a [ResolveSchema] use case.
  const ResolveSchema({
    required ITraitRepository traitRepository,
    required ITraitAttributeDefinitionRepository attributeRepository,
  }) : _traitRepository = traitRepository,
       _attributeRepository = attributeRepository;

  final ITraitRepository _traitRepository;
  final ITraitAttributeDefinitionRepository _attributeRepository;

  /// Resolves the merged attribute schema for [traitIds].
  ///
  /// Trait chains are walked root to leaf, so a *child* trait's definition of a
  /// key overrides the one it inherited from its parent — the child is the more
  /// specific claim. A key keeps the position where it was first seen, so the
  /// general attributes read before the specific ones and the order is stable.
  ///
  /// Definitions only: values are not resolved here. `ResolvedAttribute.source`
  /// is `'trait'` and `value` is null for every entry.
  TaskEither<DomainFailure, List<ResolvedAttribute>> call(
    List<String> traitIds,
  ) {
    final chainResolver = ResolveTraitChain(_traitRepository);
    final indexByKey = <String, int>{};
    final result = <ResolvedAttribute>[];

    // Resolve every trait chain FIRST. TaskEither chains are lazy — a list
    // mutated inside a flatMap callback is not populated until .run(), so an
    // eager `for (final trait in allTraits)` after chain construction always
    // saw an empty list and the schema came back empty for every entity.
    var collectChains = TaskEither<DomainFailure, List<Trait>>.of(const []);
    for (final traitId in traitIds) {
      collectChains = collectChains.flatMap(
        (acc) => chainResolver(traitId).map((traits) => [...acc, ...traits]),
      );
    }

    return collectChains.flatMap((allTraits) {
      var resolveAttributes = TaskEither<DomainFailure, Unit>.of(unit);
      for (final trait in allTraits) {
        resolveAttributes = resolveAttributes.flatMap(
          (_) => _attributeRepository.fetchByTrait(trait.meta.id).map((attrs) {
            for (final attr in attrs) {
              final resolved = ResolvedAttribute(
                attributeId: attr.meta.id,
                name: attr.displayLabel,
                value: null,
                unit: attr.unit,
                source: 'trait',
                def: attr,
              );
              final existing = indexByKey[attr.key];
              if (existing == null) {
                // First time this key is seen: it keeps its position, so the
                // general traits' attributes read before the specific ones.
                indexByKey[attr.key] = result.length;
                result.add(resolved);
              } else {
                // A closer trait redeclares the key (child over parent). The
                // position stays, the definition is replaced.
                result[existing] = resolved;
              }
            }
            return unit;
          }),
        );
      }
      return resolveAttributes.map((_) => result);
    });
  }
}
