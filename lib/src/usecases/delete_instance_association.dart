import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Deletes an instance association by id.
class DeleteInstanceAssociation {
  /// Creates a [DeleteInstanceAssociation] use case.
  const DeleteInstanceAssociation(this._repository);

  final IInstanceAssociationRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, void> call({required String id}) =>
      _repository.delete(id: id);
}
