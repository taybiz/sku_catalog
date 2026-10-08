import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'support/memory_backends.dart';
import 'package:test/test.dart';

/// A use case that writes twice is only safe when the caller supplies a store
/// that can roll back. These tests pin both halves of that: with a unit of work
/// the partial write is undone, and without one it is not.
void main() {
  late MemorySkuRepository skus;
  late MemorySkuComponentRepository components;
  late MemoryInstanceRepository instances;

  Meta meta(String id) => Meta(
    id: id,
    notes: '',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  );

  setUp(() async {
    skus = MemorySkuRepository();
    components = MemorySkuComponentRepository();
    instances = MemoryInstanceRepository();
    await CreateSku(skus)(
      Sku(meta: meta('rack'), manufacturerId: 'm', modelNumber: 'RACK'),
    ).run();
    // An edge whose child SKU is deliberately absent from the SKU store, so the
    // SKU delete fails *after* the edge delete has already succeeded.
    await CreateSkuComponent(components)(
      SkuComponent(
        meta: meta('edge'),
        parentSkuId: 'rack',
        childSkuId: 'card',
        quantity: 8,
      ),
    ).run();
  });

  Future<int> edgeCount() async => (await FetchComponentsBySku(components)(
    'rack',
  ).run()).getOrElse((_) => []).length;

  test('a unit of work rolls a failed SKU delete back', () async {
    final result = await DeleteSku(
      skuRepository: skus,
      instanceRepository: instances,
      skuComponentRepository: components,
      unitOfWork: MemoryUnitOfWork([skus, components]),
    )('card').run();

    result.isLeft().should.beTrue();
    (await edgeCount()).should.be(1);
  });

  test('without a unit of work the assembly line is already gone', () async {
    final result = await DeleteSku(
      skuRepository: skus,
      instanceRepository: instances,
      skuComponentRepository: components,
    )('card').run();

    result.isLeft().should.beTrue();
    // No transaction: the cascade committed before the failure. This is the
    // behaviour a store that cannot roll back gets, and why `unitOfWork` exists.
    (await edgeCount()).should.be(0);
  });

  test(
    'an instance delete takes its images and the instance in one unit',
    () async {
      final images = MemoryImageRepository();
      await CreateInstance(instances)(
        Instance(
          meta: meta('d1'),
          skuId: 'rack',
          locateId: null,
          name: 'Dev 1',
        ),
      ).run();
      await CreateImageRecord(images)(
        ImageRecord(
          id: 'img1',
          owner: ImageOwner.instance,
          ownerId: 'd1',
          filename: 'one.jpg',
          storedPath: 'data:image/jpeg;base64,AAAA',
          createdAt: '2024-01-01T00:00:00.000Z',
        ),
      ).run();

      final result = await DeleteInstance(
        instanceRepository: instances,
        imageRepository: images,
        unitOfWork: MemoryUnitOfWork([instances, images]),
      )('d1').run();

      result.isRight().should.beTrue();
      (await instances.fetchAll().run()).getOrElse((_) => []).should.beEmpty();
      (await images.fetchAll().run()).getOrElse((_) => []).should.beEmpty();
    },
  );
}
