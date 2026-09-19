import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Resolves the trait chain from root to leaf for a given trait.
class ResolveTraitChain {
  /// Creates a [ResolveTraitChain] use case.
  const ResolveTraitChain(this._traitRepository);

  final ITraitRepository _traitRepository;

  /// Returns the trait chain from root ancestor to [traitId].
  TaskEither<DomainFailure, List<Trait>> call(String traitId) =>
      _traitRepository.fetchAll().map((traits) {
        final traitMap = {for (final t in traits) t.meta.id: t};
        final chain = <Trait>[];
        final visited = <String>{};
        var currentId = traitId;

        while (currentId.isNotEmpty && visited.add(currentId)) {
          final trait = traitMap[currentId];
          if (trait == null) break;
          chain.add(trait);
          currentId = trait.parentTraitId ?? '';
        }

        return chain.reversed.toList();
      });
}
