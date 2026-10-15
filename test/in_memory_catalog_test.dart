import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/in_memory.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'package:test/test.dart';

/// The composition root is the point of the reference backend: one object that
/// holds every store, hands out a transaction over all of them, and wires the
/// model's rules and operations. These are the three things it is for.
void main() {
  Meta meta(String id) => Meta(
    id: id,
    notes: '',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  );

  Sku sku(String id, {List<String> traitIds = const []}) => Sku(
    meta: meta(id),
    manufacturerId: 'm',
    modelNumber: id.toUpperCase(),
    traitIds: traitIds,
  );

  Instance article(
    String id, {
    String skuId = 'panel',
    Map<String, dynamic> values = const {},
  }) => Instance(
    meta: meta(id),
    skuId: skuId,
    locateId: null,
    name: id,
    attributeValues: values,
  );

  test('the stores are exposed as contracts', () async {
    final catalog = InMemoryCatalog();

    // The check is the type: the catalogue's fields satisfy the interfaces.
    final ISkuRepository skus = catalog.skus;
    final IInstanceRepository instances = catalog.instances;
    final ITraitRepository traits = catalog.traits;

    await skus.create(sku: sku('qo120')).run();

    (await instances.fetchAll().run()).getOrElse((_) => []).should.beEmpty();
    (await traits.fetchAll().run()).getOrElse((_) => []).should.beEmpty();
    (await skus.fetchAll().run()).getOrElse((_) => []).should.haveCount(1);
  });

  test('the catalog runs the model end to end, rules included', () async {
    final catalog = InMemoryCatalog();
    final serializable = SerializableTrait.define(
      traitMeta: meta('serializable'),
      attributeMeta: meta('serializable-serial_number'),
    );
    await CreateTrait(catalog.traits)(trait: serializable.trait).run();
    await CreateTraitAttributeDefinition(catalog.attributes)(
      attribute: serializable.serialNumber,
    ).run();
    await CreateSku(catalog.skus)(
      sku: sku('panel', traitIds: const ['serializable']),
    ).run();

    final first = await catalog
        .createInstance(
          instance: article('pnl-1', values: const {'serial_number': 'SN-1'}),
        )
        .run();
    final clash = await catalog
        .createInstance(
          instance: article('pnl-2', values: const {'serial_number': 'SN-1'}),
        )
        .run();

    first.isRight().should.beTrue();
    // The rule is *wired*, not merely available: a second article may not take
    // a serial number the first one holds.
    clash
        .fold((failure) => failure, (_) => fail('expected a Left'))
        .should
        .beAssignableTo<DuplicateAttributeValueFailure>();
    (await catalog.instances.fetchAll().run())
        .getOrElse((_) => [])
        .should
        .haveCount(1);
  });

  test('the catalog transaction rolls a failed SKU delete back', () async {
    final catalog = InMemoryCatalog();
    // A SKU and an edge whose child SKU is deliberately absent, so the SKU delete
    // fails *after* the cascade has already removed the edge.
    await catalog.skus.create(sku: sku('rack')).run();
    await catalog.assemblies
        .create(
          component: SkuComponent(
            meta: meta('edge'),
            parentSkuId: 'rack',
            childSkuId: 'card',
            quantity: 8,
          ),
        )
        .run();

    final result = await catalog.deleteSku(id: 'card').run();

    result.isLeft().should.beTrue();
    // The transaction is the catalog's own, over every store it holds.
    (await catalog.assemblies.fetchAll().run())
        .getOrElse((_) => [])
        .should
        .haveCount(1);
  });

  test(
    'the reference backend resolves attributes through its own stores',
    () async {
      final catalog = InMemoryCatalog();
      final trait = Trait(
        meta: meta('switch'),
        name: 'Switch',
        scope: const [TraitScope.sku],
      );
      await CreateTrait(catalog.traits)(trait: trait).run();
      await CreateTraitAttributeDefinition(catalog.attributes)(
        attribute: TraitAttributeDefinition(
          meta: meta('switch-rated_amps'),
          traitId: 'switch',
          key: 'rated_amps',
          displayLabel: 'Rated Amperage',
          dataType: DataType.number,
          unit: 'A',
        ),
      ).run();
      await catalog.skus
          .create(
            sku: Sku(
              meta: meta('qo120'),
              manufacturerId: 'm',
              modelNumber: 'QO120',
              traitIds: const ['switch'],
              attributeValues: const {'rated_amps': 20},
            ),
          )
          .run();

      final resolved = await catalog
          .effectiveAttributes(instanceId: 'nope')
          .run();

      // An instance the catalog does not have fails as a value...
      resolved.isLeft().should.beTrue();

      // ...and the model question is answered through the same wiring.
      final forSku = await catalog.skuAttributes(skuId: 'qo120').run();
      final rated = forSku
          .getOrElse((_) => fail('expected Right'))
          .singleWhere((attribute) => attribute.name == 'Rated Amperage');

      (rated.value as int).should.be(20);
      rated.source.should.be(AttributeValueSource.sku);
      rated.unit.should.be('A');
    },
  );
}
