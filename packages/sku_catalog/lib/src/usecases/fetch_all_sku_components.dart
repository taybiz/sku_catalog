import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Fetch all SKU components.
class FetchAllSkuComponents {
  /// Creates a [FetchAllSkuComponents] use case.
  const FetchAllSkuComponents(this._repository);

  final ISkuComponentRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, List<SkuComponent>> call() =>
      _repository.fetchAll();
}
