import 'package:fpdart/fpdart.dart';
import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/in_memory.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'package:test/test.dart';

/// The trait tree's rules run through the use cases, and they are rules rather
/// than storage: a trait with children, or one attached to a model, a maker or a
/// place, may not be deleted; deleting a leaf cascades to its attribute
/// definitions; and reparenting a trait may not loop the tree.
void main() {
  late InMemoryCatalog catalog;

  Meta meta(String id) => Meta(
    id: id,
    notes: '',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  );

  Trait traitOf(String id, {String? parent}) => Trait(
    meta: meta(id),
    name: id,
    parentTraitId: parent,
    scope: const [TraitScope.sku],
  );

  setUp(() {
    catalog = InMemoryCatalog();
  });

  Future<void> store(Trait trait) =>
      CreateTrait(catalog.traits)(trait: trait).run();

  Future<TraitAttributeDefinition> define(String traitId, String key) async {
    final attribute = TraitAttributeDefinition(
      meta: meta('$traitId-$key'),
      traitId: traitId,
      key: key,
      displayLabel: key,
      dataType: DataType.string,
    );
    await CreateTraitAttributeDefinition(catalog.attributes)(
      attribute: attribute,
    ).run();
    return attribute;
  }

  DeleteTrait deleteTrait() => DeleteTrait(
    traitRepository: catalog.traits,
    skuRepository: catalog.skus,
    manufacturerRepository: catalog.manufacturers,
    locateRepository: catalog.locates,
    traitAttributeRepository: catalog.attributes,
  );

  DomainFailure refusalOf(Either<DomainFailure, Object?> result) =>
      result.fold<DomainFailure>(
        (failure) => failure,
        (_) => fail('expected a refusal'),
      );

  test(
    'a trait with children may not be deleted, and is free once they go',
    () async {
      await store(traitOf('switch'));
      await store(traitOf('breaker', parent: 'switch'));

      refusalOf(
        await deleteTrait()(id: 'switch').run(),
      ).should.beAssignableTo<InUseFailure>();

      (await deleteTrait()(id: 'breaker').run()).isRight().should.beTrue();
      (await deleteTrait()(id: 'switch').run()).isRight().should.beTrue();
      (await FetchAllTraits(
        catalog.traits,
      )().run()).getOrElse((_) => []).should.beEmpty();
    },
  );

  test('a trait attached to a model may not be deleted', () async {
    await store(traitOf('on-model'));
    await catalog.skus
        .create(
          sku: Sku(
            meta: meta('s1'),
            manufacturerId: 'm',
            modelNumber: 'S1',
            traitIds: const ['on-model'],
          ),
        )
        .run();

    refusalOf(
      await deleteTrait()(id: 'on-model').run(),
    ).message.should.contain('SKU');
  });

  test('a trait attached to a maker may not be deleted', () async {
    await store(traitOf('on-maker'));
    await catalog.manufacturers
        .create(
          manufacturer: Manufacturer(
            meta: meta('m1'),
            name: 'M1',
            traitIds: const ['on-maker'],
          ),
        )
        .run();

    refusalOf(
      await deleteTrait()(id: 'on-maker').run(),
    ).message.should.contain('manufacturer');
  });

  test('a trait attached to a place may not be deleted', () async {
    await store(traitOf('on-place'));
    await catalog.locates
        .create(
          locate: Locate(
            meta: meta('l1'),
            name: 'L1',
            traitIds: const ['on-place'],
          ),
        )
        .run();

    refusalOf(
      await deleteTrait()(id: 'on-place').run(),
    ).message.should.contain('locate');
  });

  test('deleting a trait cascades to its attribute definitions', () async {
    await store(traitOf('batch'));
    await define('batch', 'lot');
    await define('batch', 'shift');

    (await FetchAllTraitAttributeDefinitions(
      catalog.attributes,
    )().run()).getOrElse((_) => []).should.haveCount(2);

    (await deleteTrait()(id: 'batch').run()).isRight().should.beTrue();

    (await FetchAllTraits(
      catalog.traits,
    )().run()).getOrElse((_) => []).should.beEmpty();
    (await FetchAllTraitAttributeDefinitions(
      catalog.attributes,
    )().run()).getOrElse((_) => []).should.beEmpty();
  });

  test('a trait may be reparented, but never into a loop', () async {
    await store(traitOf('a'));
    await store(traitOf('b', parent: 'a'));
    await store(traitOf('c'));
    final update = UpdateTrait(catalog.traits);

    // The parent nobody changed: written straight through, no cycle walk.
    (await update(trait: traitOf('a')).run()).isRight().should.beTrue();

    // B is below A, so A under B would loop — and so would a trait under itself.
    refusalOf(
      await update(trait: traitOf('a', parent: 'b')).run(),
    ).should.beAssignableTo<WouldCreateCycleFailure>();
    refusalOf(
      await update(trait: traitOf('b', parent: 'b')).run(),
    ).should.beAssignableTo<WouldCreateCycleFailure>();

    // A parent that is not below it: fine.
    (await update(
      trait: traitOf('c', parent: 'a'),
    ).run()).isRight().should.beTrue();
    (await FetchTraitById(catalog.traits)(id: 'c').run())
        .getOrElse((_) => fail('expected the trait back'))
        .parentTraitId
        .should
        .be('a');
  });

  test('the trait delegates read and write through their stores', () async {
    await store(traitOf('switch'));
    final lot = await define('switch', 'lot');

    (await FetchAllTraits(
      catalog.traits,
    )().run()).getOrElse((_) => []).should.haveCount(1);
    (await FetchTraitById(catalog.traits)(id: 'switch').run())
        .getOrElse((_) => fail('expected the trait back'))
        .name
        .should
        .be('switch');
    (await FetchAttributesByTrait(catalog.attributes)(
      traitId: 'switch',
    ).run()).getOrElse((_) => []).should.haveCount(1);
    (await FetchTraitAttributeDefinitionById(catalog.attributes)(
      id: 'nope',
    ).run()).isLeft().should.beTrue();
    (await FetchTraitAttributeDefinitionById(catalog.attributes)(
          id: lot.meta.id,
        ).run())
        .getOrElse((_) => fail('expected the definition back'))
        .key
        .should
        .be('lot');

    final relabelled = TraitAttributeDefinition(
      meta: lot.meta,
      traitId: 'switch',
      key: 'lot',
      displayLabel: 'Lot number',
      dataType: DataType.string,
    );
    (await UpdateTraitAttributeDefinition(catalog.attributes)(
          definition: relabelled,
        ).run())
        .getOrElse((_) => fail('expected the definition back'))
        .displayLabel
        .should
        .be('Lot number');

    (await DeleteTraitAttributeDefinition(catalog.attributes)(
      id: lot.meta.id,
    ).run()).isRight().should.beTrue();
    (await FetchAllTraitAttributeDefinitions(
      catalog.attributes,
    )().run()).getOrElse((_) => []).should.beEmpty();
  });
}
