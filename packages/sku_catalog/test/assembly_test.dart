import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'package:test/test.dart';

import 'support/memory_repositories.dart';

/// SKUs assemble from SKUs. The edge carries a quantity, and the graph must
/// never close a loop — a machine cannot contain itself.
void main() {
  late MemoryDeviceTypeRepository skus;
  late MemorySkuComponentRepository components;
  late MemoryDeviceRepository devices;
  late AddSkuComponent addEdge;

  Meta meta(String id) => Meta(
    id: id,
    notes: '',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  );

  DeviceType sku(String id) => DeviceType(
    meta: meta(id),
    manufacturerId: 'm',
    modelNumber: id.toUpperCase(),
  );

  setUp(() async {
    skus = MemoryDeviceTypeRepository();
    components = MemorySkuComponentRepository();
    devices = MemoryDeviceRepository();
    addEdge = AddSkuComponent(
      repository: components,
      deviceTypeRepository: skus,
    );
    for (final id in ['base', 'card', 'rack']) {
      await CreateDeviceType(skus)(sku(id)).run();
    }
  });

  test('a SKU can contain another SKU, with a quantity', () async {
    final result = await addEdge(
      parentDeviceTypeId: 'rack',
      childDeviceTypeId: 'card',
      quantity: 8,
    ).run();

    result.isRight().should.beTrue();

    final edges = await FetchSkuComponentsByDeviceType(components)(
      'rack',
    ).run();
    final rows = edges.getOrElse((_) => fail('expected Right'));
    rows.should.haveCount(1);
    rows.single.quantity.should.be(8);
    rows.single.childDeviceTypeId.should.be('card');
  });

  test('an edge to a SKU that does not exist is refused', () async {
    final result = await addEdge(
      parentDeviceTypeId: 'rack',
      childDeviceTypeId: 'ghost',
      quantity: 1,
    ).run();

    result.isLeft().should.beTrue();
  });

  test('a two-SKU loop is refused', () async {
    (await addEdge(
      parentDeviceTypeId: 'rack',
      childDeviceTypeId: 'card',
      quantity: 1,
    ).run()).isRight().should.beTrue();

    final loop = await addEdge(
      parentDeviceTypeId: 'card',
      childDeviceTypeId: 'rack',
      quantity: 1,
    ).run();

    loop.isLeft().should.beTrue();
    loop
        .fold((f) => f, (_) => fail('expected Left'))
        .should
        .beAssignableTo<WouldCreateCycleFailure>();
  });

  test('a three-SKU loop is refused', () async {
    await addEdge(
      parentDeviceTypeId: 'rack',
      childDeviceTypeId: 'card',
      quantity: 1,
    ).run();
    await addEdge(
      parentDeviceTypeId: 'card',
      childDeviceTypeId: 'base',
      quantity: 1,
    ).run();

    final loop = await addEdge(
      parentDeviceTypeId: 'base',
      childDeviceTypeId: 'rack',
      quantity: 1,
    ).run();

    loop.isLeft().should.beTrue();
  });

  test('a SKU cannot contain itself', () async {
    (await addEdge(
      parentDeviceTypeId: 'rack',
      childDeviceTypeId: 'rack',
      quantity: 1,
    ).run()).isLeft().should.beTrue();
  });

  test('an assembly edge can be removed', () async {
    await addEdge(
      parentDeviceTypeId: 'rack',
      childDeviceTypeId: 'card',
      quantity: 8,
    ).run();
    final rows = (await FetchSkuComponentsByDeviceType(components)(
      'rack',
    ).run()).getOrElse((_) => fail('expected Right'));

    (await DeleteSkuComponent(components)(
      rows.single.meta.id,
    ).run()).isRight().should.beTrue();
    (await FetchSkuComponentsByDeviceType(components)(
      'rack',
    ).run()).getOrElse((_) => []).should.beEmpty();
  });

  test('deleting a SKU that a device instantiates is refused', () async {
    await CreateDevice(devices)(
      Device(
        meta: meta('d1'),
        deviceTypeId: 'base',
        locateId: null,
        name: 'Base 1',
      ),
    ).run();

    final result = await DeleteDeviceType(
      deviceTypeRepository: skus,
      deviceRepository: devices,
      skuComponentRepository: components,
    )('base').run();

    result.isLeft().should.beTrue();
    result
        .fold((f) => f, (_) => fail('expected Left'))
        .should
        .beAssignableTo<InUseFailure>();
  });

  test(
    'deleting a SKU cascades the assembly lines that referenced it',
    () async {
      await addEdge(
        parentDeviceTypeId: 'rack',
        childDeviceTypeId: 'card',
        quantity: 8,
      ).run();

      final deleted = await DeleteDeviceType(
        deviceTypeRepository: skus,
        deviceRepository: devices,
        skuComponentRepository: components,
      )('card').run();
      deleted.isRight().should.beTrue();

      (await FetchSkuComponentsByDeviceType(components)(
        'rack',
      ).run()).getOrElse((_) => []).should.beEmpty();
      (await FetchAllDeviceTypes(skus)().run())
          .getOrElse((_) => [])
          .map((s) => s.meta.id)
          .should
          .not
          .contain('card');
    },
  );
}
