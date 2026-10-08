import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'support/memory_backends.dart';
import 'package:test/test.dart';

/// The backend is shipped, so it is tested: round-trip, not-found, delete and
/// clear, over each contract a consumer is most likely to reach for first.
void main() {
  Meta meta(String id) => Meta(
    id: id,
    notes: 'note',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  );

  test('a SKU round-trips through create, fetch and update', () async {
    final repo = MemorySkuRepository();
    await repo
        .create(
          sku: Sku(
            meta: meta('qo120'),
            manufacturerId: 'square-d',
            modelNumber: 'QO120',
          ),
        )
        .run();

    (await repo.fetchAll().run())
        .getOrElse((_) => fail('expected Right'))
        .should
        .haveCount(1);
    (await repo.fetchById(id: 'qo120').run())
        .getOrElse((_) => fail('expected Right'))
        .modelNumber
        .should
        .be('QO120');

    await repo
        .update(
          sku: Sku(
            meta: meta('qo120'),
            manufacturerId: 'square-d',
            modelNumber: 'QO120-2',
          ),
        )
        .run();
    (await repo.fetchById(id: 'qo120').run())
        .getOrElse((_) => fail('expected Right'))
        .modelNumber
        .should
        .be('QO120-2');
  });

  test('a missing record fails as a value, not an exception', () async {
    final repo = MemorySkuRepository();
    final result = await repo.fetchById(id: 'nope').run();

    result.isLeft().should.beTrue();
    result
        .fold((f) => f, (_) => fail('expected Left'))
        .should
        .beAssignableTo<NotFoundFailure>();
  });

  test('delete removes, and delete of a missing record fails', () async {
    final repo = MemoryLocateRepository();
    await repo
        .create(
          locate: Locate(meta: meta('rack-1'), name: 'Rack 1'),
        )
        .run();

    (await repo.delete(id: 'rack-1').run()).isRight().should.beTrue();
    (await repo.fetchAll().run()).getOrElse((_) => []).should.beEmpty();
    (await repo.delete(id: 'rack-1').run()).isLeft().should.beTrue();
  });

  test('clearAll empties the store', () async {
    final repo = MemoryTraitRepository();
    await repo
        .create(
          trait: Trait(meta: meta('t'), name: 'T'),
        )
        .run();

    (await repo.clearAll().run()).isRight().should.beTrue();
    (await repo.fetchAll().run()).getOrElse((_) => []).should.beEmpty();
  });

  test('the assembly edge repository filters by parent SKU', () async {
    final repo = MemorySkuComponentRepository();
    await repo
        .create(
          component: SkuComponent(
            meta: meta('e1'),
            parentSkuId: 'rack',
            childSkuId: 'card',
            quantity: 4,
          ),
        )
        .run();
    await repo
        .create(
          component: SkuComponent(
            meta: meta('e2'),
            parentSkuId: 'other',
            childSkuId: 'card',
            quantity: 1,
          ),
        )
        .run();

    final rows = await repo.fetchBySku(skuId: 'rack').run();
    rows.getOrElse((_) => fail('expected Right')).single.quantity.should.be(4);
  });
}
