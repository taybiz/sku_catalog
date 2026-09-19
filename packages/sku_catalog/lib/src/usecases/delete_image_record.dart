import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Delete an image record by id.
class DeleteImageRecord {
  /// Creates a [DeleteImageRecord] use case.
  const DeleteImageRecord(this._repository);

  final IImageRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, void> call(String id) => _repository.delete(id);
}
