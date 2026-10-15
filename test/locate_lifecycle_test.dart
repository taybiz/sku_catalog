import 'package:fpdart/fpdart.dart';
import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/in_memory.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'package:test/test.dart';

/// A place is a tree, and the tree's rules run through the use cases: a place
/// with sub-locates or assigned articles may not be deleted, a parent change may
/// not loop the tree, and the two readers — the descendant walk and the display
/// path — answer for a real tree.
void main() {
  late InMemoryCatalog catalog;

  Meta meta(String id) => Meta(
    id: id,
    notes: '',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  );

  Locate placeOf(String id, {String? parent, String? name}) =>
      Locate(meta: meta(id), name: name ?? id, parentLocateId: parent);

  setUp(() {
    catalog = InMemoryCatalog();
  });

  Future<void> put(Locate locate) => catalog.createLocate(locate: locate).run();

  DomainFailure refusalOf(Either<DomainFailure, Object?> result) =>
      result.fold<DomainFailure>(
        (failure) => failure,
        (_) => fail('expected a refusal'),
      );

  /// Garage → Panel Position → Rack 3, with a place beside it that no walk
  /// should reach.
  Future<void> seedTree() async {
    await put(placeOf('garage', name: 'Garage'));
    await put(placeOf('panel', parent: 'garage', name: 'Panel Position'));
    await put(placeOf('rack', parent: 'panel', name: 'Rack 3'));
    await put(placeOf('attic', name: 'Attic'));
  }

  test('a place with sub-locates may not be deleted', () async {
    await seedTree();
    final deletePlace = DeleteLocate(
      locateRepository: catalog.locates,
      instanceRepository: catalog.instances,
    );

    refusalOf(
      await deletePlace(id: 'garage').run(),
    ).should.beAssignableTo<InUseFailure>();

    // The leaf is free, and once it is gone so is its parent.
    (await deletePlace(id: 'rack').run()).isRight().should.beTrue();
    (await deletePlace(id: 'panel').run()).isRight().should.beTrue();
  });

  test('a place holding an article may not be deleted', () async {
    await put(placeOf('garage', name: 'Garage'));
    await catalog.instances
        .create(
          instance: Instance(
            meta: meta('i1'),
            skuId: 's1',
            locateId: 'garage',
            name: 'Panel 1',
          ),
        )
        .run();
    final deletePlace = DeleteLocate(
      locateRepository: catalog.locates,
      instanceRepository: catalog.instances,
    );

    refusalOf(
      await deletePlace(id: 'garage').run(),
    ).message.should.contain('assigned instances');
  });

  test('a parent change that would loop the tree is refused', () async {
    await seedTree();

    // Garage under Rack 3: Rack 3 is below Garage, so this is a loop.
    refusalOf(
      await catalog
          .updateLocate(locate: placeOf('garage', parent: 'rack'))
          .run(),
    ).should.beAssignableTo<WouldCreateCycleFailure>();

    // A place under itself is the same loop, one step shorter.
    refusalOf(
      await catalog
          .updateLocate(locate: placeOf('attic', parent: 'attic'))
          .run(),
    ).should.beAssignableTo<WouldCreateCycleFailure>();

    // A legitimate move is written: Attic becomes a child of Garage.
    (await catalog
            .updateLocate(locate: placeOf('attic', parent: 'garage'))
            .run())
        .isRight()
        .should
        .beTrue();
    (await catalog.locates.fetchById(id: 'attic').run())
        .getOrElse((_) => fail('expected the place back'))
        .parentLocateId
        .should
        .be('garage');
  });

  test('the descendant walk answers for a nested tree', () async {
    await seedTree();
    final descendants = DescendantLocateIds(catalog.locates);

    (await descendants(
      rootId: 'garage',
    ).run()).getOrElse((_) => []).should.be(['panel', 'rack']);
    (await descendants(
      rootId: 'garage',
      includeSelf: true,
    ).run()).getOrElse((_) => []).should.be(['garage', 'panel', 'rack']);
    (await descendants(
      rootId: 'attic',
    ).run()).getOrElse((_) => []).should.beEmpty();
  });

  test('the display path walks up the parents', () async {
    await seedTree();
    final path = ResolveLocatePath(catalog.locates);

    (await path(locateId: 'rack').run())
        .getOrElse((_) => fail('expected a path'))
        .should
        .be('Garage / Panel Position / Rack 3');
    (await path(
      locateId: 'garage',
    ).run()).getOrElse((_) => fail('expected a path')).should.be('Garage');
    (await path(locateId: 'nowhere').run()).isLeft().should.beTrue();
  });

  test('the locate delegates read through the store', () async {
    await seedTree();

    (await FetchAllLocates(
      catalog.locates,
    )().run()).getOrElse((_) => []).should.haveCount(4);
    (await FetchLocateById(catalog.locates)(id: 'rack').run())
        .getOrElse((_) => fail('expected the place back'))
        .name
        .should
        .be('Rack 3');
    (await FetchInstancesByLocate(catalog.instances)(
      locateId: 'rack',
    ).run()).getOrElse((_) => []).should.beEmpty();
  });
}
