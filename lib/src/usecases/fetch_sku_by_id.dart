import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Fetch a single SKU by id.
class FetchSkuById {
  /// Creates a [FetchSkuById] use case.
  const FetchSkuById(this._repository);

  final ISkuRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, Sku> call(String id) => _repository.fetchById(id);
}
