import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Delete a manufacturer by id, blocked while any SKU uses it.
class DeleteManufacturer {
  /// Creates a [DeleteManufacturer] use case.
  const DeleteManufacturer({
    required IManufacturerRepository manufacturerRepository,
    required ISkuRepository skuRepository,
  }) : _manufacturerRepository = manufacturerRepository,
       _skuRepository = skuRepository;

  final IManufacturerRepository _manufacturerRepository;
  final ISkuRepository _skuRepository;

  /// Executes the use case.
  TaskEither<DomainFailure, void> call({required String id}) =>
      _skuRepository.fetchAll().flatMap((types) {
        if (types.any((t) => t.manufacturerId == id)) {
          return TaskEither.left(
            InUseFailure('This manufacturer is in use by one or more SKUs.'),
          );
        }
        return _manufacturerRepository.delete(id: id);
      });
}
