import 'package:fpdart/fpdart.dart';
import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/in_memory.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'package:test/test.dart';

/// The seam is structural: an operation that needs a transaction takes one at
/// construction, so there is no way to build it without saying what its atomicity
/// is. Two things are worth pinning here, and neither is covered by the rollback
/// tests:
///
/// - a **rule-carrying** write enters its unit of work once, with the rule's reads
///   inside it — the check and the row are one step for a transactional store;
/// - the **composite** enters its unit of work exactly once. It composes
///   [DeleteInstance] and [DeleteSku], and those are wired with `noOpUnitOfWork`,
///   so the two halves run *inside* the one transaction rather than opening nested
///   ones (which no store is obliged to support).
void main() {
  Meta meta(String id) => Meta(
    id: id,
    notes: '',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  );

  /// A unit of work that counts how many times it was entered and does nothing
  /// else — no snapshots, no rollback, just the entry itself.
  (UnitOfWork, List<String>) counting() {
    final entries = <String>[];
    Future<Either<F, T>> uow<F, T>({
      required Future<Either<F, T>> Function() body,
    }) async {
      entries.add('entered');
      return body();
    }

    return (uow, entries);
  }

  test('a rule-carrying write enters its unit of work once', () async {
    final catalog = InMemoryCatalog();
    final (unitOfWork, entries) = counting();

    final createLocate = CreateLocate(
      locateRepository: catalog.locates,
      assertUniqueAttributeValues: catalog.uniqueValues,
      unitOfWork: unitOfWork,
    );

    final result = await createLocate(
      locate: Locate(meta: meta('rack'), name: 'Rack 1'),
    ).run();

    result.isRight().should.beTrue();
    // The check reads every holder store and the write lands — one entry, so the
    // store saw both as a single step.
    entries.should.haveCount(1);
    (await catalog.locates.fetchAll().run())
        .getOrElse((_) => [])
        .should
        .haveCount(1);
  });

  test('the composite enters its unit of work exactly once', () async {
    final instances = InMemoryInstanceRepository();
    final skus = InMemorySkuRepository();
    final (unitOfWork, entries) = counting();

    await skus
        .create(
          sku: Sku(
            meta: meta('book'),
            manufacturerId: 'publisher',
            modelNumber: 'ISBN-1',
          ),
        )
        .run();
    for (final id in ['copy-1', 'copy-2']) {
      await instances
          .create(
            instance: Instance(
              meta: meta(id),
              skuId: 'book',
              locateId: null,
              name: id,
            ),
          )
          .run();
    }

    final operation = DeleteInstanceAndUnusedSku(
      instanceRepository: instances,
      skuRepository: skus,
      skuComponentRepository: InMemorySkuComponentRepository(),
      imageRepository: InMemoryImageRepository(),
      instanceAssociationRepository: InMemoryInstanceAssociationRepository(),
      unitOfWork: unitOfWork,
    );

    (await operation(id: 'copy-1').run()).isRight().should.beTrue();

    // One entry for the whole operation: DeleteInstance and DeleteSku ran inside
    // it, not in units of work of their own.
    entries.should.haveCount(1);
    // ...and the shared model is still standing, which is the rule the composite
    // exists to keep.
    (await skus.fetchById(id: 'book').run()).isRight().should.beTrue();
  });
}
