import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'support/memory_backends.dart';
import 'package:test/test.dart';

/// SKUs assemble from SKUs. The edge carries a quantity, and the graph must
/// never close a loop — a machine cannot contain itself.
void main() {
  late MemorySkuRepository skus;
  late MemorySkuComponentRepository components;
  late MemoryInstanceRepository instances;
  late AddSkuComponent addEdge;

  Meta meta(String id) => Meta(
    id: id,
    notes: '',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  );

  Sku sku(String id) =>
      Sku(meta: meta(id), manufacturerId: 'm', modelNumber: id.toUpperCase());

  setUp(() async {
    skus = MemorySkuRepository();
    components = MemorySkuComponentRepository();
    instances = MemoryInstanceRepository();
    addEdge = AddSkuComponent(repository: components, skuRepository: skus);
    for (final id in ['base', 'card', 'rack']) {
      await CreateSku(skus)(sku: sku(id)).run();
    }
  });

  test('a SKU can contain another SKU, with a quantity', () async {
    final result = await addEdge(
      parentSkuId: 'rack',
      childSkuId: 'card',
      quantity: 8,
    ).run();

    result.isRight().should.beTrue();

    final edges = await FetchComponentsBySku(components)(skuId: 'rack').run();
    final rows = edges.getOrElse((_) => fail('expected Right'));
    rows.should.haveCount(1);
    rows.single.quantity.should.be(8);
    rows.single.childSkuId.should.be('card');
  });

  test('an edge to a SKU that does not exist is refused', () async {
    final result = await addEdge(
      parentSkuId: 'rack',
      childSkuId: 'ghost',
      quantity: 1,
    ).run();

    result.isLeft().should.beTrue();
  });

  test('a two-SKU loop is refused', () async {
    (await addEdge(
      parentSkuId: 'rack',
      childSkuId: 'card',
      quantity: 1,
    ).run()).isRight().should.beTrue();

    final loop = await addEdge(
      parentSkuId: 'card',
      childSkuId: 'rack',
      quantity: 1,
    ).run();

    loop.isLeft().should.beTrue();
    loop
        .fold((f) => f, (_) => fail('expected Left'))
        .should
        .beAssignableTo<WouldCreateCycleFailure>();
  });

  test('a three-SKU loop is refused', () async {
    await addEdge(parentSkuId: 'rack', childSkuId: 'card', quantity: 1).run();
    await addEdge(parentSkuId: 'card', childSkuId: 'base', quantity: 1).run();

    final loop = await addEdge(
      parentSkuId: 'base',
      childSkuId: 'rack',
      quantity: 1,
    ).run();

    loop.isLeft().should.beTrue();
  });

  test('a SKU cannot contain itself', () async {
    (await addEdge(
      parentSkuId: 'rack',
      childSkuId: 'rack',
      quantity: 1,
    ).run()).isLeft().should.beTrue();
  });

  test('an assembly edge can be removed', () async {
    await addEdge(parentSkuId: 'rack', childSkuId: 'card', quantity: 8).run();
    final rows = (await FetchComponentsBySku(components)(
      skuId: 'rack',
    ).run()).getOrElse((_) => fail('expected Right'));

    (await DeleteSkuComponent(components)(
      id: rows.single.meta.id,
    ).run()).isRight().should.beTrue();
    (await FetchComponentsBySku(components)(
      skuId: 'rack',
    ).run()).getOrElse((_) => []).should.beEmpty();
  });

  test('deleting a SKU that an instance instantiates is refused', () async {
    await CreateInstance(instances)(
      instance: Instance(
        meta: meta('d1'),
        skuId: 'base',
        locateId: null,
        name: 'Base 1',
      ),
    ).run();

    final result = await DeleteSku(
      skuRepository: skus,
      instanceRepository: instances,
      skuComponentRepository: components,
    )(id: 'base').run();

    result.isLeft().should.beTrue();
    result
        .fold((f) => f, (_) => fail('expected Left'))
        .should
        .beAssignableTo<InUseFailure>();
  });

  test(
    'deleting a SKU cascades the assembly lines that referenced it',
    () async {
      await addEdge(parentSkuId: 'rack', childSkuId: 'card', quantity: 8).run();

      final deleted = await DeleteSku(
        skuRepository: skus,
        instanceRepository: instances,
        skuComponentRepository: components,
      )(id: 'card').run();
      deleted.isRight().should.beTrue();

      (await FetchComponentsBySku(components)(
        skuId: 'rack',
      ).run()).getOrElse((_) => []).should.beEmpty();
      (await FetchAllSkus(skus)().run())
          .getOrElse((_) => [])
          .map((s) => s.meta.id)
          .should
          .not
          .contain('card');
    },
  );
}
