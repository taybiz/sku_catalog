import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'package:sku_catalog/in_memory.dart';
import 'package:test/test.dart';

/// An instance is one article of a SKU at one place, and the rules that matter are
/// about *where* it is: names are unique per place, a copy is not fitted
/// anywhere on its own, and the catalog stores the place it is handed.
void main() {
  late InMemoryInstanceRepository instances;
  late InMemorySkuRepository skus;
  late InMemoryTraitRepository traits;
  late InMemoryTraitAttributeDefinitionRepository attributes;
  late InMemoryImageRepository images;
  late InMemoryLocateRepository locates;

  Meta meta(String id) => Meta(
    id: id,
    notes: '',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  );

  Instance instance(
    String id,
    String name, {
    String? locateId = 'rack-1',
    String typeId = 'free',
  }) => Instance(meta: meta(id), skuId: typeId, locateId: locateId, name: name);

  ResolveInstanceSchema schemaResolver() => ResolveInstanceSchema(
    skuRepository: skus,
    resolveSchema: ResolveSchema(
      traitRepository: traits,
      attributeRepository: attributes,
    ),
  );

  AssertUniqueAttributeValues uniqueness() => AssertUniqueAttributeValues(
    instanceRepository: instances,
    resolveInstanceSchema: schemaResolver(),
  );

  CreateInstance createInstance() => CreateInstance(
    instanceRepository: instances,
    assertUniqueInstanceName: AssertUniqueInstanceName(instances),
    assertUniqueAttributeValues: uniqueness(),
  );

  UpdateInstance updateInstance() => UpdateInstance(
    instanceRepository: instances,
    assertUniqueInstanceName: AssertUniqueInstanceName(instances),
    assertUniqueAttributeValues: uniqueness(),
  );

  DuplicateInstance duplicator() => DuplicateInstance(
    instanceRepository: instances,
    resolveInstanceSchema: schemaResolver(),
  );

  setUp(() async {
    instances = InMemoryInstanceRepository();
    skus = InMemorySkuRepository();
    traits = InMemoryTraitRepository();
    attributes = InMemoryTraitAttributeDefinitionRepository();
    images = InMemoryImageRepository();
    locates = InMemoryLocateRepository();

    await CreateSku(skus)(
      sku: Sku(meta: meta('free'), manufacturerId: 'm', modelNumber: 'FREE'),
    ).run();
    await CreateLocate(locates)(
      locate: Locate(meta: meta('rack-1'), name: 'Rack 1'),
    ).run();
    await CreateLocate(locates)(
      locate: Locate(meta: meta('rack-2'), name: 'Rack 2'),
    ).run();
  });

  test('a created instance is fetched back and found by its place', () async {
    await createInstance()(instance: instance('d1', 'Sensor 1')).run();

    (await FetchAllInstances(
      instances,
    )().run()).getOrElse((_) => fail('expected Right')).should.haveCount(1);

    final atRack = await FetchInstancesByLocate(instances)(
      locateId: 'rack-1',
    ).run();
    atRack
        .getOrElse((_) => fail('expected Right'))
        .single
        .name
        .should
        .be('Sensor 1');
    (await FetchInstancesByLocate(instances)(
      locateId: 'rack-2',
    ).run()).getOrElse((_) => []).should.beEmpty();
  });

  test('an instance knows whether it is placed', () {
    instance('d1', 'Sensor 1').isPlaced.should.beTrue();
    instance('d2', 'Loose', locateId: null).isPlaced.should.beFalse();
  });

  test(
    'a name clash at the same place is refused, and allowed elsewhere',
    () async {
      await createInstance()(instance: instance('d1', 'Sensor 1')).run();
      await createInstance()(instance: instance('d2', 'Other')).run();
      await createInstance()(
        instance: instance('d3', 'Third', locateId: 'rack-2'),
      ).run();

      final clash = await updateInstance()(
        instance: instance('d2', 'sensor 1'),
      ).run();
      clash.isLeft().should.beTrue();
      clash
          .fold((f) => f, (_) => fail('expected Left'))
          .should
          .beAssignableTo<AlreadyExistsFailure>();

      // The same name at a different place is fine.
      final elsewhere = await updateInstance()(
        instance: instance('d3', 'Sensor 1', locateId: 'rack-2'),
      ).run();
      elsewhere.isRight().should.beTrue();
    },
  );

  test('a name clash is refused on create too', () async {
    await createInstance()(instance: instance('d1', 'Sensor 1')).run();

    final clash = await createInstance()(
      instance: instance('d2', 'sensor 1'),
    ).run();

    clash.isLeft().should.beTrue();
    clash
        .fold((f) => f, (_) => fail('expected Left'))
        .should
        .beAssignableTo<AlreadyExistsFailure>();
    // The refused article was never stored.
    (await instances.fetchAll().run()).getOrElse((_) => []).should.haveCount(1);

    // The same name at another place is fine, on create as on update.
    final elsewhere = await createInstance()(
      instance: instance('d2', 'Sensor 1', locateId: 'rack-2'),
    ).run();
    elsewhere.isRight().should.beTrue();
  });

  test('a copy gets a unique name and the original keeps its place', () async {
    await createInstance()(instance: instance('d1', 'Sensor 1')).run();

    final first = await duplicator()(id: 'd1').run();
    first
        .getOrElse((_) => fail('expected Right'))
        .name
        .should
        .be('Sensor 1 copy');

    final second = await duplicator()(id: 'd1').run();
    second
        .getOrElse((_) => fail('expected Right'))
        .name
        .should
        .be('Sensor 1 copy 2');
  });

  test('a copy takes the original place, and the caller can move it', () async {
    await createInstance()(instance: instance('d1', 'Card 1')).run();

    final copy = await duplicator()(id: 'd1').run();

    copy.getOrElse((_) => fail('expected Right')).locateId.should.be('rack-1');
  });

  test('deleting an instance takes its images with it', () async {
    await createInstance()(instance: instance('d1', 'Sensor 1')).run();
    await CreateImageRecord(images)(
      image: ImageRecord(
        id: 'img-d1',
        owner: ImageOwner.instance,
        ownerId: 'd1',
        filename: 'd1.jpg',
        storedPath: 'data:image/jpeg;base64,AAAA',
        createdAt: '2024-01-01T00:00:00.000Z',
      ),
    ).run();

    final result = await DeleteInstance(
      instanceRepository: instances,
      imageRepository: images,
    )(id: 'd1').run();

    result.isRight().should.beTrue();
    (await FetchAllInstances(
      instances,
    )().run()).getOrElse((_) => []).should.beEmpty();
    (await images.fetchAll().run()).getOrElse((_) => []).should.beEmpty();
  });

  test(
    'deleting an instance leaves images owned by something else alone',
    () async {
      await createInstance()(instance: instance('d1', 'Sensor 1')).run();
      await CreateImageRecord(images)(
        image: ImageRecord(
          id: 'img-sku',
          owner: ImageOwner.sku,
          ownerId: 'd1',
          filename: 'sku.jpg',
          storedPath: 'data:image/jpeg;base64,AAAA',
          createdAt: '2024-01-01T00:00:00.000Z',
        ),
      ).run();

      await DeleteInstance(
        instanceRepository: instances,
        imageRepository: images,
      )(id: 'd1').run();

      (await images.fetchAll().run()).getOrElse((_) => []).should.haveCount(1);
    },
  );

  test(
    'instance traits and values are carried on the instance itself',
    () async {
      final one = instance('d1', 'Sensor 1').copyWith(
        traitIds: const ['calibrated'],
        attributeValues: const {'calibrated_on': '2026-01-01'},
      );

      final saved = await createInstance()(instance: one).run();
      final back = saved.getOrElse((_) => fail('expected Right'));

      back.traitIds.should.be(['calibrated']);
      (back.attributeValues['calibrated_on'] as String).should.be('2026-01-01');
    },
  );
}
