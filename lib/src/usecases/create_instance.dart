import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Create a new instance.
class CreateInstance {
  /// Creates a [CreateInstance] use case.
  const CreateInstance(this._repository);

  final IInstanceRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, Instance> call({required Instance instance}) =>
      _repository.create(instance: instance);
}
