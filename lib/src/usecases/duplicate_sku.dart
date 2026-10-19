import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Duplicates a SKU: fresh meta and the next free "(copy)" model number.
///
/// The copy goes through no rule, because it cannot break one: a model number is
/// unique per manufacturer, so the copy takes the next number that maker's
/// numbering leaves free (`uniqueCopyModelNumber`) rather than the original's. That
/// is the same choice `DuplicateInstance` makes with a unique attribute value — a
/// copy is a new thing, and must never be refused for inheriting an identity.
class DuplicateSku {
  /// Creates a [DuplicateSku] use case.
  const DuplicateSku(this._skuRepository, {this.idGenerator});

  final ISkuRepository _skuRepository;

  /// Mints the copy's id; defaults to a random UUID v4 when null.
  final IdGenerator? idGenerator;

  /// Executes the use case.
  TaskEither<DomainFailure, Sku> call({required String id}) => _skuRepository
      .fetchById(id: id)
      .flatMap(
        (current) => _skuRepository.fetchAll().flatMap((all) {
          final copy = current.copyWith(
            meta: newMeta(idGenerator: idGenerator),
            modelNumber: uniqueCopyModelNumber(
              baseNumber: current.modelNumber,
              manufacturerId: current.manufacturerId,
              all: all,
            ),
          );
          return _skuRepository.create(sku: copy);
        }),
      );
}
