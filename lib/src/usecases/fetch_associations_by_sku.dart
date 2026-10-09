import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Fetch associations for a SKU (row's source **or** target), optionally
/// filtered by role [kind].
class FetchAssociationsBySku {
  /// Creates a [FetchAssociationsBySku] use case.
  const FetchAssociationsBySku(this._repository);

  final ISkuAssociationRepository _repository;

  /// Executes the use case.
  TaskEither<DomainFailure, List<SkuAssociation>> call({
    required String skuId,
    String? kind,
  }) => _repository.fetchBySku(skuId: skuId, kind: kind);
}
