import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';
import 'id_generator.dart';
import 'new_meta.dart';

/// Adds a labeled relationship edge from [sourceSkuId] to [targetSkuId]
/// in the role [kind]. Refuses when either SKU does not exist or [kind] is
/// blank.
///
/// Unlike [AddSkuComponent] there is no cycle guard: a relationship graph may
/// legitimately cycle ([sourceSkuId] editing a work that [targetSkuId]
/// contributed to).
class AddSkuAssociation {
  /// Creates an [AddSkuAssociation] use case.
  const AddSkuAssociation({
    required ISkuAssociationRepository repository,
    required ISkuRepository skuRepository,
    this.idGenerator,
  }) : _repository = repository,
       _skuRepository = skuRepository;

  final ISkuAssociationRepository _repository;
  final ISkuRepository _skuRepository;

  /// Mints the new edge's id; defaults to a random UUID v4 when null.
  final IdGenerator? idGenerator;

  /// Executes the use case.
  TaskEither<DomainFailure, SkuAssociation> call({
    required String sourceSkuId,
    required String targetSkuId,
    required String kind,
  }) {
    if (kind.trim().isEmpty) {
      return TaskEither.left(
        const InvalidInputFailure('A SKU association needs a non-empty kind'),
      );
    }

    return _skuRepository
        .fetchById(id: sourceSkuId)
        .andThen(() => _skuRepository.fetchById(id: targetSkuId))
        .flatMap(
          (_) => _repository.create(
            association: SkuAssociation(
              meta: newMeta(idGenerator: idGenerator),
              sourceSkuId: sourceSkuId,
              targetSkuId: targetSkuId,
              kind: kind,
            ),
          ),
        );
  }
}
