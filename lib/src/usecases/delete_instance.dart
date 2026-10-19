import 'package:fpdart/fpdart.dart';
import '../domain/domain.dart';

/// Deletes an instance, the images attached to it, and the association edges
/// that name it.
///
/// Everything the catalog itself stores *about* an article goes with it: the
/// images it owns and both ends of any `InstanceAssociation` it is part of, so a
/// deleted article leaves no row pointing at an id nothing holds. Three writes
/// happen, so pass a [unitOfWork] when your store can roll back.
///
/// Anything *outside* the catalog that references an instance — a wiring graph, a
/// bill of materials, a harness — is that consumer's to cascade. Deleting
/// through this use case leaves those references dangling by design: the
/// catalog does not know they exist. Compose your own deletion around this one.
class DeleteInstance {
  /// Creates a [DeleteInstance] use case.
  const DeleteInstance({
    required IInstanceRepository instanceRepository,
    required IImageRepository imageRepository,
    required IInstanceAssociationRepository instanceAssociationRepository,
    IUnitOfWork? unitOfWork,
  }) : _instanceRepository = instanceRepository,
       _imageRepository = imageRepository,
       _instanceAssociationRepository = instanceAssociationRepository,
       _unitOfWork = unitOfWork ?? const NoOpUnitOfWork();

  final IInstanceRepository _instanceRepository;
  final IImageRepository _imageRepository;
  final IInstanceAssociationRepository _instanceAssociationRepository;
  final IUnitOfWork _unitOfWork;

  /// Executes the use case.
  TaskEither<DomainFailure, void> call({required String id}) =>
      _imageRepository.fetchAll().flatMap((images) {
        final mine = images
            .where((i) => i.owner == ImageOwner.instance && i.ownerId == id)
            .toList();
        return _instanceAssociationRepository.fetchAll().flatMap((edges) {
          final touching = edges
              .where(
                (edge) =>
                    edge.sourceInstanceId == id || edge.targetInstanceId == id,
              )
              .toList();
          return TaskEither<DomainFailure, void>(
            () => _unitOfWork.runEither<DomainFailure, void>(
              body: () => sequenceTaskEither(
                tasks: [
                  for (final img in mine) _imageRepository.delete(id: img.id),
                  for (final edge in touching)
                    _instanceAssociationRepository.delete(id: edge.meta.id),
                ],
              ).flatMap((_) => _instanceRepository.delete(id: id)).run(),
            ),
          );
        });
      });
}
