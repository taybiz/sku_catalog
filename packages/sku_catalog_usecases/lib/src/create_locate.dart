import 'package:sku_catalog_domain/sku_catalog_domain.dart';
import 'package:fpdart/fpdart.dart';

/// Create a new locate.
class CreateLocate {
  /// Creates a [CreateLocate] use case.
  const CreateLocate(this._repository);

  final ILocateRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, Locate> call(Locate locate) =>
      _repository.create(locate);
}
