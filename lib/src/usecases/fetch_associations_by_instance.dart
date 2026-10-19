import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Fetch associations for an article (row's source **or** target), optionally
/// filtered by role [kind].
class FetchAssociationsByInstance {
  /// Creates a [FetchAssociationsByInstance] use case.
  const FetchAssociationsByInstance(this._repository);

  final IInstanceAssociationRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, List<InstanceAssociation>> call({
    required String instanceId,
    String? kind,
  }) => _repository.fetchByInstance(instanceId: instanceId, kind: kind);
}
