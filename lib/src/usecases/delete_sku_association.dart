import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Deletes a SKU association by id.
class DeleteSkuAssociation {
  /// Creates a [DeleteSkuAssociation] use case.
  const DeleteSkuAssociation(this._repository);

  final ISkuAssociationRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, void> call({required String id}) =>
      _repository.delete(id: id);
}
