import 'package:sku_catalog_domain/sku_catalog_domain.dart';
import 'package:fpdart/fpdart.dart';

/// Fetch all image records for a single owner entity.
class FetchImageRecords {
  /// Creates a [FetchImageRecords] use case.
  const FetchImageRecords(this._repository);

  final IImageRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, List<ImageRecord>> call(
    ImageOwner owner,
    String ownerId,
  ) => _repository.fetchByOwner(owner, ownerId);
}
