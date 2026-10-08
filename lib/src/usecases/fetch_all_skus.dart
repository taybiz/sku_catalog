import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Fetch all SKUs.
class FetchAllSkus {
  /// Creates a [FetchAllSkus] use case.
  const FetchAllSkus(this._repository);

  final ISkuRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, List<Sku>> call() => _repository.fetchAll();
}
