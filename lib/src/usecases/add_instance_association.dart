import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Adds a labeled relationship edge between two articles, from
/// [sourceInstanceId] to [targetInstanceId] in the role [kind]. Refuses when
/// either article does not exist, when [kind] is blank, or when the two ends are
/// the same article.
///
/// The last of those is this edge's own rule: **an edge connects peers**, and an
/// article is not its own peer. A self-edge would say nothing ("this copy is
/// bound with itself") while occupying a row nothing can distinguish from a
/// legitimate one later.
///
/// Unlike [AddSkuComponent] there is no cycle guard: a relationship graph may
/// legitimately cycle (two copies, each annotating the other).
class AddInstanceAssociation {
  /// Creates an [AddInstanceAssociation] use case.
  const AddInstanceAssociation({
    required IInstanceAssociationRepository repository,
    required IInstanceRepository instanceRepository,
    required UnitOfWork unitOfWork,
    this.idGenerator,
  }) : _repository = repository,
       _instanceRepository = instanceRepository,
       _unitOfWork = unitOfWork;

  final IInstanceAssociationRepository _repository;
  final IInstanceRepository _instanceRepository;
  final UnitOfWork _unitOfWork;

  /// Mints the new edge's id; defaults to a random UUID v4 when null.
  final IdGenerator? idGenerator;

  /// Executes the use case.
  TaskEither<DomainFailure, InstanceAssociation> call({
    required String sourceInstanceId,
    required String targetInstanceId,
    required String kind,
  }) {
    if (kind.trim().isEmpty) {
      return TaskEither.left(
        const InvalidInputFailure(
          'An instance association needs a non-empty kind',
        ),
      );
    }
    if (sourceInstanceId == targetInstanceId) {
      return TaskEither.left(
        const InvalidInputFailure(
          'An instance association needs two distinct articles',
        ),
      );
    }

    return TaskEither(
      () => _unitOfWork<DomainFailure, InstanceAssociation>(
        body: () => _instanceRepository
            .fetchById(id: sourceInstanceId)
            .andThen(() => _instanceRepository.fetchById(id: targetInstanceId))
            .flatMap(
              (_) => _repository.create(
                association: InstanceAssociation(
                  meta: newMeta(idGenerator: idGenerator),
                  sourceInstanceId: sourceInstanceId,
                  targetInstanceId: targetInstanceId,
                  kind: kind,
                ),
              ),
            )
            .run(),
      ),
    );
  }
}
