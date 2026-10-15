import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/in_memory.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'package:test/test.dart';

/// The reference backend is shipped, so it is tested: round-trip, not-found,
/// delete and the per-store filters, over each contract a consumer is most likely
/// to reach for first.
void main() {
  Meta meta(String id) => Meta(
    id: id,
    notes: 'note',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  );

  test('a SKU round-trips through create, fetch and update', () async {
    final repo = InMemorySkuRepository();
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

  test('create refuses an id that is already stored', () async {
    final repo = InMemorySkuRepository();
    final sku = Sku(
      meta: meta('qo120'),
      manufacturerId: 'square-d',
      modelNumber: 'QO120',
    );
    await repo.create(sku: sku).run();

    final again = await repo.create(sku: sku).run();

    again
        .fold((failure) => failure, (_) => fail('expected Left'))
        .should
        .beAssignableTo<AlreadyExistsFailure>();
    (await repo.fetchAll().run()).getOrElse((_) => []).should.haveCount(1);
  });

  test('an update of a record that is not there fails', () async {
    final repo = InMemorySkuRepository();
    final result = await repo
        .update(
          sku: Sku(meta: meta('ghost'), manufacturerId: 'm', modelNumber: 'G'),
        )
        .run();

    result
        .fold((failure) => failure, (_) => fail('expected Left'))
        .should
        .beAssignableTo<NotFoundFailure>();
  });

  test('a missing record fails as a value, not an exception', () async {
    final repo = InMemorySkuRepository();
    final result = await repo.fetchById(id: 'nope').run();

    result.isLeft().should.beTrue();
    result
        .fold((f) => f, (_) => fail('expected Left'))
        .should
        .beAssignableTo<NotFoundFailure>();
  });

  test('delete removes, and delete of a missing record fails', () async {
    final repo = InMemoryLocateRepository();
    await repo
        .create(
          locate: Locate(meta: meta('rack-1'), name: 'Rack 1'),
        )
        .run();

    (await repo.delete(id: 'rack-1').run()).isRight().should.beTrue();
    (await repo.fetchAll().run()).getOrElse((_) => []).should.beEmpty();
    (await repo.delete(id: 'rack-1').run()).isLeft().should.beTrue();
  });

  test('a trait round-trips through create, fetch and delete', () async {
    final repo = InMemoryTraitRepository();

    (await repo
            .create(
              trait: Trait(meta: meta('t'), name: 'T'),
            )
            .run())
        .isRight()
        .should
        .beTrue();
    (await repo.fetchById(id: 't').run())
        .getOrElse((_) => fail('expected Right'))
        .name
        .should
        .be('T');

    (await repo.delete(id: 't').run()).isRight().should.beTrue();
    (await repo.fetchAll().run()).getOrElse((_) => []).should.beEmpty();
  });

  test('the assembly edge repository filters by parent SKU', () async {
    final repo = InMemorySkuComponentRepository();
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

  test('the instance repository filters by place', () async {
    final repo = InMemoryInstanceRepository();
    for (final row in [
      (id: 'i1', locateId: 'rack-1'),
      (id: 'i2', locateId: 'rack-2'),
    ]) {
      await repo
          .create(
            instance: Instance(
              meta: meta(row.id),
              skuId: 's',
              locateId: row.locateId,
              name: row.id,
            ),
          )
          .run();
    }

    final atRack = await repo.fetchByLocate(locateId: 'rack-1').run();
    atRack.getOrElse((_) => fail('expected Right')).single.name.should.be('i1');
  });

  test(
    'the association repository matches either end, and filters by kind',
    () async {
      final repo = InMemorySkuAssociationRepository();
      for (final row in [
        (id: 'a1', source: 'smith', target: 'anthology', kind: 'edited'),
        (id: 'a2', source: 'smith', target: 'other', kind: 'reviewed'),
        (id: 'a3', source: 'jones', target: 'anthology', kind: 'edited'),
      ]) {
        await repo
            .create(
              association: SkuAssociation(
                meta: meta(row.id),
                sourceSkuId: row.source,
                targetSkuId: row.target,
                kind: row.kind,
              ),
            )
            .run();
      }

      final forAnthology = await repo.fetchBySku(skuId: 'anthology').run();
      forAnthology.getOrElse((_) => fail('expected Right')).should.haveCount(2);

      final edited = await repo
          .fetchBySku(skuId: 'anthology', kind: 'edited')
          .run();
      edited.getOrElse((_) => fail('expected Right')).should.haveCount(2);

      final smith = await repo.fetchBySku(skuId: 'smith', kind: 'edited').run();
      smith
          .getOrElse((_) => fail('expected Right'))
          .single
          .kind
          .should
          .be('edited');
    },
  );

  test('the attribute repository filters by declaring trait', () async {
    final repo = InMemoryTraitAttributeDefinitionRepository();
    await repo
        .create(
          attribute: TraitAttributeDefinition(
            meta: meta('switch-amps'),
            traitId: 'switch',
            key: 'rated_amps',
            displayLabel: 'Rated Amperage',
            dataType: DataType.number,
          ),
        )
        .run();
    await repo
        .create(
          attribute: TraitAttributeDefinition(
            meta: meta('breaker-amps'),
            traitId: 'breaker',
            key: 'rated_amps',
            displayLabel: 'Rated Amperage',
            dataType: DataType.number,
          ),
        )
        .run();

    final onSwitch = await repo.fetchByTrait(traitId: 'switch').run();
    onSwitch
        .getOrElse((_) => fail('expected Right'))
        .single
        .meta
        .id
        .should
        .be('switch-amps');
  });

  test('the image repository filters by owner', () async {
    final repo = InMemoryImageRepository();
    await repo
        .create(
          image: ImageRecord(
            id: 'img-1',
            owner: ImageOwner.instance,
            ownerId: 'i1',
            filename: 'one.jpg',
            storedPath: 'data:image/jpeg;base64,AAAA',
            createdAt: '2026-01-01T00:00:00.000Z',
          ),
        )
        .run();
    await repo
        .create(
          image: ImageRecord(
            id: 'img-2',
            owner: ImageOwner.locate,
            ownerId: 'i1',
            filename: 'two.jpg',
            storedPath: 'data:image/jpeg;base64,BBBB',
            createdAt: '2026-01-01T00:00:00.000Z',
          ),
        )
        .run();

    final mine = await repo
        .fetchByOwner(owner: ImageOwner.instance, ownerId: 'i1')
        .run();
    mine.getOrElse((_) => fail('expected Right')).single.id.should.be('img-1');
  });

  test(
    'the meta repository holds one record, keyed for a transaction',
    () async {
      final repo = InMemoryMetaRepository();

      (await repo.fetch().run())
          .getOrElse((_) => fail('expected Right'))
          .id
          .should
          .be('');

      await repo.update(meta: meta('catalog')).run();

      (await repo.fetch().run())
          .getOrElse((_) => fail('expected Right'))
          .id
          .should
          .be('catalog');
      repo.rows.keys.should.be(<String>['meta']);
    },
  );

  group('Given an in-memory table', () {
    test('Then it stores, finds and removes records by id', () {
      final table = InMemoryTable<Sku>(
        decode: Sku.fromJson,
        encode: (sku) => sku.toJson(),
        idOf: (sku) => sku.meta.id,
      );

      table.has('qo120').should.beFalse();
      table.put(
        Sku(meta: meta('qo120'), manufacturerId: 'm', modelNumber: 'QO120'),
      );

      table.has('qo120').should.beTrue();
      table.find('qo120').should.not.beNull();
      table.find('qo120')!.modelNumber.should.be('QO120');
      table.all().should.haveCount(1);
      table.remove('qo120').should.beTrue();
      table.remove('qo120').should.beFalse();
      table.all().should.beEmpty();
    });

    test('Then a snapshot is a copy, and replaceAll puts it back', () {
      final table = InMemoryTable<Sku>(
        decode: Sku.fromJson,
        encode: (sku) => sku.toJson(),
        idOf: (sku) => sku.meta.id,
      );
      table.put(Sku(meta: meta('a'), manufacturerId: 'm', modelNumber: 'A'));

      final snapshot = table.snapshot();
      table.put(Sku(meta: meta('b'), manufacturerId: 'm', modelNumber: 'B'));
      table.all().should.haveCount(2);

      // The snapshot did not move with the table.
      snapshot.keys.should.be(<String>['a']);

      table.replaceAll(snapshot);
      table.all().should.haveCount(1);
      table.has('a').should.beTrue();
      table.has('b').should.beFalse();
    });
  });
}
