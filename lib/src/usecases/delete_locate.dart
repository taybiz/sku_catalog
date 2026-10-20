import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Delete a locate by id, blocked while it still has sub-locates or assigned
/// instances.
class DeleteLocate {
  /// Creates a [DeleteLocate] use case.
  const DeleteLocate({
    required ILocateRepository locateRepository,
    required IInstanceRepository instanceRepository,
  }) : _locateRepository = locateRepository,
       _instanceRepository = instanceRepository;

  final ILocateRepository _locateRepository;
  final IInstanceRepository _instanceRepository;

  /// Executes the use case.
  TaskEither<DomainFailure, void> call({required String id}) =>
      _locateRepository.fetchByParentLocate(parentLocateId: id).flatMap((
        children,
      ) {
        if (children.isNotEmpty) {
          return TaskEither.left(InUseFailure('This locate has sub-locates.'));
        }
        return _instanceRepository.fetchByLocate(locateId: id).flatMap((
          instances,
        ) {
          if (instances.isNotEmpty) {
            return TaskEither.left(
              InUseFailure('This locate has assigned instances.'),
            );
          }
          return _locateRepository.delete(id: id);
        });
      });
}
