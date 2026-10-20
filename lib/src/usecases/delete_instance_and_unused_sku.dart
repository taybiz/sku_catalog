import 'package:fpdart/fpdart.dart';

import '../domain/domain.dart';
import 'delete_instance.dart';
import 'delete_sku.dart';

/// Deletes an article and, when it was its model's last one, the model too.
///
/// For a model that exists only for its articles — nobody's catalog entry, just the
/// thing its copies instantiate. **Choosing this operation is the assertion**: the
/// model carries no flag saying it is unmanaged, because such a flag would be a
/// second copy of a fact the call site already states, and two articles of one model
/// could then disagree about it.
///
/// The article always goes. The model goes **only when nothing else names it**, which
/// is the case that decides the rule: two copies of one book share one SKU, so
/// deleting the first copy leaves the edition standing and deleting the second takes
/// it. That is deliberately not [DeleteSku]'s behaviour — that use case refuses with
/// [InUseFailure] while articles use the model, where this one lets the article's
/// delete succeed and keeps the model. A copy must always be deletable.
///
/// Both halves are the existing use cases, composed in one transaction rather than
/// re-implemented: [DeleteInstance] takes the article's images and the association
/// edges that name it, and [DeleteSku] takes the model's own assembly edges. So a
/// model that nobody else references is not removed alone — everything that hung off
/// it goes too.
class DeleteInstanceAndUnusedSku {
  /// Creates a [DeleteInstanceAndUnusedSku] use case.
  const DeleteInstanceAndUnusedSku({
    required DeleteInstance deleteInstance,
    required DeleteSku deleteSku,
    required IInstanceRepository instanceRepository,
    UnitOfWork? unitOfWork,
  }) : _deleteInstance = deleteInstance,
       _deleteSku = deleteSku,
       _instanceRepository = instanceRepository,
       _unitOfWork = unitOfWork ?? noOpUnitOfWork;

  final DeleteInstance _deleteInstance;
  final DeleteSku _deleteSku;
  final IInstanceRepository _instanceRepository;
  final UnitOfWork _unitOfWork;

  /// Executes the use case.
  TaskEither<DomainFailure, void> call({required String id}) =>
      _instanceRepository.fetchById(id: id).flatMap((article) {
        return _instanceRepository.fetchAll().flatMap((all) {
          final isLastArticle = !all.any(
            (other) => other.meta.id != id && other.skuId == article.skuId,
          );
          return TaskEither<DomainFailure, void>(
            () => _unitOfWork<DomainFailure, void>(
              body: () async {
                final removed = await _deleteInstance(id: id).run();
                if (removed.isLeft() || !isLastArticle) return removed;
                return await _deleteSku(id: article.skuId).run();
              },
            ),
          );
        });
      });
}
