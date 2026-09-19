import 'package:sku_catalog_domain/sku_catalog_domain.dart';
import 'package:fpdart/fpdart.dart';

/// Update meta.
class UpdateMeta {
  /// Creates an [UpdateMeta] use case.
  const UpdateMeta(this._repository);

  final IMetaRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, Meta> call(Meta meta) => _repository.update(meta);
}
