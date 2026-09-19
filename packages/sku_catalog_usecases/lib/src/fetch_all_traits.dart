import 'package:sku_catalog_domain/sku_catalog_domain.dart';
import 'package:fpdart/fpdart.dart';

/// Fetch all traits.
class FetchAllTraits {
  /// Creates a [FetchAllTraits] use case.
  const FetchAllTraits(this._repository);

  final ITraitRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, List<Trait>> call() => _repository.fetchAll();
}
