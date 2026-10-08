import 'package:fpdart/fpdart.dart';
import '../domain/domain.dart';

import 'sequence.dart';

/// Deletes an instance and the images attached to it.
///
/// Two writes — the images, then the instance — so pass a [unitOfWork] when your
/// store can roll back.
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
    IUnitOfWork? unitOfWork,
  }) : _instanceRepository = instanceRepository,
       _imageRepository = imageRepository,
       _unitOfWork = unitOfWork ?? const NoOpUnitOfWork();

  final IInstanceRepository _instanceRepository;
  final IImageRepository _imageRepository;
  final IUnitOfWork _unitOfWork;

  /// Executes the use case.
  TaskEither<DomainFailure, void> call({required String id}) =>
      _imageRepository.fetchAll().flatMap((images) {
        final mine = images
            .where((i) => i.owner == ImageOwner.instance && i.ownerId == id)
            .toList();
        return TaskEither<DomainFailure, void>(
          () => _unitOfWork.runEither<DomainFailure, void>(
            body: () => sequenceTaskEither(
              tasks: [
                for (final img in mine) _imageRepository.delete(id: img.id),
              ],
            ).flatMap((_) => _instanceRepository.delete(id: id)).run(),
          ),
        );
      });
}
