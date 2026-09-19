import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Create a new image record (device/locate/SKU image).
class CreateImageRecord {
  /// Creates a [CreateImageRecord] use case.
  const CreateImageRecord(this._repository);

  final IImageRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, ImageRecord> call(ImageRecord image) =>
      _repository.create(image);
}
