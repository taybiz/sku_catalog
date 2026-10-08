import 'package:fpdart/fpdart.dart';
import '../domain/domain.dart';

import 'sequence.dart';

/// Delete a SKU by id, blocked while instances use it; its
/// component lines cascade.
///
/// Two writes happen here — the assembly lines that referenced the SKU, then the
/// SKU itself — so pass a [unitOfWork] when your store can roll back: a failed
/// delete must not leave the assembly already disassembled.
class DeleteSku {
  /// Creates a [DeleteSku] use case.
  const DeleteSku({
    required ISkuRepository skuRepository,
    required IInstanceRepository instanceRepository,
    required ISkuComponentRepository skuComponentRepository,
    IUnitOfWork? unitOfWork,
  }) : _skuRepository = skuRepository,
       _instanceRepository = instanceRepository,
       _skuComponentRepository = skuComponentRepository,
       _unitOfWork = unitOfWork ?? const NoOpUnitOfWork();

  final ISkuRepository _skuRepository;
  final IInstanceRepository _instanceRepository;
  final ISkuComponentRepository _skuComponentRepository;
  final IUnitOfWork _unitOfWork;

  /// Executes the use case.
  TaskEither<DomainFailure, void> call(String id) =>
      _instanceRepository.fetchAll().flatMap((instances) {
        if (instances.any((d) => d.skuId == id)) {
          return TaskEither.left(
            InUseFailure('This SKU is in use by one or more instances.'),
          );
        }
        return _skuComponentRepository.fetchAll().flatMap((components) {
          final touching = components
              .where((c) => c.parentSkuId == id || c.childSkuId == id)
              .toList();
          // TaskEither's raw constructor takes an async Either, which is what
          // runEither produces. TaskEither.tryCatch would take the Either as a
          // *success* value and hand back Right(Left(...)).
          return TaskEither<DomainFailure, void>(
            () => _unitOfWork.runEither<DomainFailure, void>(
              () => sequenceTaskEither([
                for (final c in touching)
                  _skuComponentRepository.delete(c.meta.id),
              ]).flatMap((_) => _skuRepository.delete(id)).run(),
            ),
          );
        });
      });
}
