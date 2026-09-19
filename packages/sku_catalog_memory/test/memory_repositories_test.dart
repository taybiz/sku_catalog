import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog_domain/sku_catalog_domain.dart';
import 'package:sku_catalog_memory/sku_catalog_memory.dart';
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
    final repo = MemoryDeviceTypeRepository();
    await repo
        .create(
          DeviceType(
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
    (await repo.fetchById('qo120').run())
        .getOrElse((_) => fail('expected Right'))
        .modelNumber
        .should
        .be('QO120');

    await repo
        .update(
          DeviceType(
            meta: meta('qo120'),
            manufacturerId: 'square-d',
            modelNumber: 'QO120-2',
          ),
        )
        .run();
    (await repo.fetchById('qo120').run())
        .getOrElse((_) => fail('expected Right'))
        .modelNumber
        .should
        .be('QO120-2');
  });

  test('a missing record fails as a value, not an exception', () async {
    final repo = MemoryDeviceTypeRepository();
    final result = await repo.fetchById('nope').run();

    result.isLeft().should.beTrue();
    result
        .fold((f) => f, (_) => fail('expected Left'))
        .should
        .beAssignableTo<NotFoundFailure>();
  });

  test('delete removes, and delete of a missing record fails', () async {
    final repo = MemoryLocateRepository();
    await repo.create(Locate(meta: meta('rack-1'), name: 'Rack 1')).run();

    (await repo.delete('rack-1').run()).isRight().should.beTrue();
    (await repo.fetchAll().run()).getOrElse((_) => []).should.beEmpty();
    (await repo.delete('rack-1').run()).isLeft().should.beTrue();
  });

  test('clearAll empties the store', () async {
    final repo = MemoryTraitRepository();
    await repo.create(Trait(meta: meta('t'), name: 'T')).run();

    (await repo.clearAll().run()).isRight().should.beTrue();
    (await repo.fetchAll().run()).getOrElse((_) => []).should.beEmpty();
  });

  test('the assembly edge repository filters by parent SKU', () async {
    final repo = MemorySkuComponentRepository();
    await repo
        .create(
          SkuComponent(
            meta: meta('e1'),
            parentDeviceTypeId: 'rack',
            childDeviceTypeId: 'card',
            quantity: 4,
          ),
        )
        .run();
    await repo
        .create(
          SkuComponent(
            meta: meta('e2'),
            parentDeviceTypeId: 'other',
            childDeviceTypeId: 'card',
            quantity: 1,
          ),
        )
        .run();

    final rows = await repo.fetchByDeviceType('rack').run();
    rows.getOrElse((_) => fail('expected Right')).single.quantity.should.be(4);
  });
}
