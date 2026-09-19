import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Fetch the current meta.
class FetchMeta {
  /// Creates a [FetchMeta] use case.
  const FetchMeta(this._repository);

  final IMetaRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, Meta> call() => _repository.fetch();
}
