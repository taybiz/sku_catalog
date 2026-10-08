import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Fetch components for a SKU.
class FetchComponentsBySku {
  /// Creates a [FetchComponentsBySku] use case.
  const FetchComponentsBySku(this._repository);

  final ISkuComponentRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, List<SkuComponent>> call({required String skuId}) =>
      _repository.fetchBySku(skuId: skuId);
}
