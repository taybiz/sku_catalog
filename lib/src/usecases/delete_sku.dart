import 'package:fpdart/fpdart.dart';
import '../domain/domain.dart';

/// Delete a SKU by id, blocked while instances use it; its
/// component lines cascade.
///
/// Two writes happen here — the assembly lines that referenced the SKU, then the
/// SKU itself — so the transaction is a **required** dependency: a failed delete
/// must not leave the assembly already disassembled. A store that cannot roll back
/// is wired with `noOpUnitOfWork`, which is a statement the composition root makes
/// out loud rather than a default nobody sees.
class DeleteSku {
  /// Creates a [DeleteSku] use case.
  const DeleteSku({
    required ISkuRepository skuRepository,
    required IInstanceRepository instanceRepository,
    required ISkuComponentRepository skuComponentRepository,
    required UnitOfWork unitOfWork,
  }) : _skuRepository = skuRepository,
       _instanceRepository = instanceRepository,
       _skuComponentRepository = skuComponentRepository,
       _unitOfWork = unitOfWork;

  final ISkuRepository _skuRepository;
  final IInstanceRepository _instanceRepository;
  final ISkuComponentRepository _skuComponentRepository;
  final UnitOfWork _unitOfWork;

  /// Executes the use case.
  ///
  /// The guards read inside the same unit of work as the writes, so a
  /// transactional store sees one snapshot instead of a check that can go stale
  /// before the delete lands.
  TaskEither<DomainFailure, void> call({required String id}) => TaskEither(
    () => _unitOfWork<DomainFailure, void>(
      body: () => _instanceRepository.fetchBySku(skuId: id).flatMap((
        instances,
      ) {
        if (instances.any((d) => d.skuId == id)) {
          return TaskEither<DomainFailure, void>.left(
            InUseFailure('This SKU is in use by one or more instances.'),
          );
        }
        // Both ends have to be read: `fetchBySku` on components answers for the
        // parent side only, and a row naming this SKU as its child would be left
        // dangling.
        return _skuComponentRepository.fetchAll().flatMap((components) {
          final touching = components
              .where((c) => c.parentSkuId == id || c.childSkuId == id)
              .toList();
          return sequenceTaskEither(
            tasks: [
              for (final c in touching)
                _skuComponentRepository.delete(id: c.meta.id),
            ],
          ).flatMap((_) => _skuRepository.delete(id: id));
        });
      }).run(),
    ),
  );
}
