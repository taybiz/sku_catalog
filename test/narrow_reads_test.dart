import 'package:fpdart/fpdart.dart';
import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/in_memory.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'package:test/test.dart';

/// The rules and cascades read what they need, not every row in the store.
///
/// Each spy below is the reference store with exactly one method changed:
/// `fetchAll()` answers a failure instead of the store's rows. A rule that
/// quietly goes back to scanning therefore *fails* in this file — which is the
/// only way the narrowing stays true, because when the data happens to fit, a
/// scan and a narrow read answer the same `Right`.
class _NoScanInstances extends InMemoryInstanceRepository {
  @override
  TaskEither<DomainFailure, List<Instance>> fetchAll() =>
      TaskEither.left(NotFoundFailure('read every instance'));
}

class _NoScanSkus extends InMemorySkuRepository {
  @override
  TaskEither<DomainFailure, List<Sku>> fetchAll() =>
      TaskEither.left(NotFoundFailure('read every SKU'));
}

class _NoScanLocates extends InMemoryLocateRepository {
  @override
  TaskEither<DomainFailure, List<Locate>> fetchAll() =>
      TaskEither.left(NotFoundFailure('read every locate'));
}

class _NoScanImages extends InMemoryImageRepository {
  @override
  TaskEither<DomainFailure, List<ImageRecord>> fetchAll() =>
      TaskEither.left(NotFoundFailure('read every image'));
}

class _NoScanEdges extends InMemoryInstanceAssociationRepository {
  @override
  TaskEither<DomainFailure, List<InstanceAssociation>> fetchAll() =>
      TaskEither.left(NotFoundFailure('read every association'));
}

Instance article({
  required String skuId,
  required String? locateId,
  required String name,
}) => Instance(meta: newMeta(), skuId: skuId, locateId: locateId, name: name);

void main() {
  group('Given a rule or cascade that reads narrowly', () {
    test('the per-locate name rule reads one locate group', () async {
      final instances = _NoScanInstances();
      final here = article(skuId: 's', locateId: 'room-1', name: 'Panel');
      final elsewhere = article(skuId: 's', locateId: 'room-2', name: 'Panel');
      await instances.create(instance: here).run();
      await instances.create(instance: elsewhere).run();
      final rule = AssertUniqueInstanceName(instances);

      // A name taken in another room does not block this one — and the store
      // refuses a whole-store read, so a scan cannot be what answered.
      (await rule(
        name: 'Panel',
        locateId: 'room-1',
        excludeId: here.meta.id,
      ).run()).isRight().should.beTrue();

      // Inside the group the rule still refuses.
      final clash = await rule(name: 'Panel', locateId: 'room-2').run();
      clash
          .fold((failure) => failure, (_) => fail('expected Left'))
          .should
          .beAssignableTo<AlreadyExistsFailure>();
    });

    test('the model-number rule reads one maker', () async {
      final skus = _NoScanSkus();
      final mine = Sku(
        meta: newMeta(),
        manufacturerId: 'acme',
        modelNumber: 'QO120',
      );
      await skus.create(sku: mine).run();
      await skus
          .create(
            sku: Sku(
              meta: newMeta(),
              manufacturerId: 'other',
              modelNumber: 'QO120',
            ),
          )
          .run();
      final rule = AssertUniqueModelNumber(skus);

      // Another maker numbering its own model the same way is not a clash: acme
      // asking about its own QO120 while excluding that row is clean — and the
      // store refuses a whole-store read, so no scan answered.
      (await rule(
        modelNumber: 'QO120',
        manufacturerId: 'acme',
        excludeId: mine.meta.id,
      ).run()).isRight().should.beTrue();

      // The same maker is still refused.
      final clash = await rule(
        modelNumber: 'QO120',
        manufacturerId: 'acme',
      ).run();
      clash
          .fold((failure) => failure, (_) => fail('expected Left'))
          .should
          .beAssignableTo<AlreadyExistsFailure>();
    });

    test('DeleteSku reads the articles of that model', () async {
      final skus = _NoScanSkus();
      final instances = _NoScanInstances();
      final assemblies = InMemorySkuComponentRepository();
      final base = Sku(
        meta: newMeta(),
        manufacturerId: 'acme',
        modelNumber: 'BASE-1',
      );
      final part = Sku(
        meta: newMeta(),
        manufacturerId: 'acme',
        modelNumber: 'PART-1',
      );
      await skus.create(sku: base).run();
      await skus.create(sku: part).run();
      // An article of the *other* model must not block the delete.
      await instances
          .create(
            instance: article(skuId: part.meta.id, locateId: null, name: 'a'),
          )
          .run();

      final deleteSku = DeleteSku(
        skuRepository: skus,
        instanceRepository: instances,
        skuComponentRepository: assemblies,
        unitOfWork: inMemoryUnitOfWork([skus, instances, assemblies]),
      );

      (await deleteSku(id: base.meta.id).run()).isRight().should.beTrue();
      (await skus.fetchById(id: base.meta.id).run()).isLeft().should.beTrue();

      // An article of *this* model still refuses it.
      await skus.create(sku: base).run();
      await instances
          .create(
            instance: article(skuId: base.meta.id, locateId: null, name: 'b'),
          )
          .run();
      final refused = await deleteSku(id: base.meta.id).run();
      refused
          .fold((failure) => failure, (_) => fail('expected Left'))
          .should
          .beAssignableTo<InUseFailure>();
    });

    test('DeleteInstance reads its own images and edges', () async {
      final instances = _NoScanInstances();
      final images = _NoScanImages();
      final edges = _NoScanEdges();
      final mine = article(skuId: 's', locateId: null, name: 'mine');
      final other = article(skuId: 's', locateId: null, name: 'other');
      final third = article(skuId: 's', locateId: null, name: 'third');
      for (final instance in [mine, other, third]) {
        await instances.create(instance: instance).run();
      }
      await images
          .create(
            image: ImageRecord(
              id: 'img-mine',
              owner: ImageOwner.instance,
              ownerId: mine.meta.id,
              filename: 'mine.jpg',
              storedPath: 'images/mine.jpg',
              createdAt: '2026-01-01T00:00:00.000Z',
            ),
          )
          .run();
      await images
          .create(
            image: ImageRecord(
              id: 'img-other',
              owner: ImageOwner.instance,
              ownerId: other.meta.id,
              filename: 'other.jpg',
              storedPath: 'images/other.jpg',
              createdAt: '2026-01-01T00:00:00.000Z',
            ),
          )
          .run();
      await edges
          .create(
            association: InstanceAssociation(
              meta: newMeta(),
              sourceInstanceId: mine.meta.id,
              targetInstanceId: other.meta.id,
              kind: 'bound_with',
            ),
          )
          .run();
      await edges
          .create(
            association: InstanceAssociation(
              meta: newMeta(),
              sourceInstanceId: other.meta.id,
              targetInstanceId: third.meta.id,
              kind: 'bound_with',
            ),
          )
          .run();

      final deleteInstance = DeleteInstance(
        instanceRepository: instances,
        imageRepository: images,
        instanceAssociationRepository: edges,
        unitOfWork: inMemoryUnitOfWork([instances, images, edges]),
      );

      (await deleteInstance(id: mine.meta.id).run()).isRight().should.beTrue();

      // Its own rows went, the neighbours' stayed.
      (await images.fetchById(id: 'img-mine').run()).isLeft().should.beTrue();
      (await images.fetchById(id: 'img-other').run()).isRight().should.beTrue();
      final remaining =
          (await edges.fetchByInstance(instanceId: other.meta.id).run())
              .getOrElse((_) => []);
      remaining.should.haveCount(1);
      remaining.single.targetInstanceId.should.be(third.meta.id);
    });

    test('DeleteLocate reads its own children and articles', () async {
      final locates = _NoScanLocates();
      final instances = _NoScanInstances();
      final parent = Locate(meta: newMeta(), name: 'Room 1');
      final child = Locate(
        meta: newMeta(),
        name: 'Shelf 1',
        parentLocateId: parent.meta.id,
      );
      final other = Locate(meta: newMeta(), name: 'Room 2');
      for (final locate in [parent, child, other]) {
        await locates.create(locate: locate).run();
      }
      final deleteLocate = DeleteLocate(
        locateRepository: locates,
        instanceRepository: instances,
      );

      // A place with a child is refused, one without is not.
      final refused = await deleteLocate(id: parent.meta.id).run();
      refused
          .fold((failure) => failure, (_) => fail('expected Left'))
          .should
          .beAssignableTo<InUseFailure>();
      (await deleteLocate(id: other.meta.id).run()).isRight().should.beTrue();

      // An article in the place refuses it; an article elsewhere does not.
      await locates.create(locate: other).run();
      await instances
          .create(
            instance: article(
              skuId: 's',
              locateId: parent.meta.id,
              name: 'in room 1',
            ),
          )
          .run();
      (await deleteLocate(id: other.meta.id).run()).isRight().should.beTrue();
      final stillRefused = await deleteLocate(id: parent.meta.id).run();
      stillRefused
          .fold((failure) => failure, (_) => fail('expected Left'))
          .should
          .beAssignableTo<InUseFailure>();
    });

    test('DeleteManufacturer reads one maker\'s models', () async {
      final skus = _NoScanSkus();
      final manufacturers = InMemoryManufacturerRepository();
      final busy = Manufacturer(meta: newMeta(), name: 'Acme');
      final idle = Manufacturer(meta: newMeta(), name: 'Zenith');
      for (final manufacturer in [busy, idle]) {
        await manufacturers.create(manufacturer: manufacturer).run();
      }
      await skus
          .create(
            sku: Sku(
              meta: newMeta(),
              manufacturerId: busy.meta.id,
              modelNumber: 'QO120',
            ),
          )
          .run();
      final deleteManufacturer = DeleteManufacturer(
        manufacturerRepository: manufacturers,
        skuRepository: skus,
      );

      // A model by another maker does not block this one.
      (await deleteManufacturer(
        id: idle.meta.id,
      ).run()).isRight().should.beTrue();
      final refused = await deleteManufacturer(id: busy.meta.id).run();
      refused
          .fold((failure) => failure, (_) => fail('expected Left'))
          .should
          .beAssignableTo<InUseFailure>();
    });

    test('DuplicateSku mints its number from one maker', () async {
      final skus = _NoScanSkus();
      final mine = Sku(
        meta: newMeta(),
        manufacturerId: 'acme',
        modelNumber: 'QO120',
      );
      await skus.create(sku: mine).run();
      // Another maker already uses the number the copy would take.
      await skus
          .create(
            sku: Sku(
              meta: newMeta(),
              manufacturerId: 'other',
              modelNumber: 'QO120 (copy)',
            ),
          )
          .run();

      final copy = await DuplicateSku(skus)(id: mine.meta.id).run();

      // The copy is numbered against its own maker, so "QO120 (copy)" is free.
      copy
          .getOrElse((_) => fail('expected Right'))
          .modelNumber
          .should
          .be('QO120 (copy)');
    });
  });
}
