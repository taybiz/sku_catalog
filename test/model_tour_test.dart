import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/in_memory.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'package:test/test.dart';

/// The model read as a running system, in one flow: classify, value, catalogue,
/// assemble, place, instantiate, ask, fold.
///
/// The focused suites cover each rule on its own; what this one adds is the
/// *sequence*, in the order a reader meets it — which is why it used to be the
/// example. `example/` is a published, consumer-facing deliverable now (it has to
/// run on published code alone), so the tour that needs the repo-only reference
/// backend lives here instead, where it is also a gate.
void main() {
  late InMemoryCatalog catalog;

  final switchTrait = Trait(
    meta: newMeta(),
    name: 'Switch',
    scope: const [TraitScope.sku],
  );
  final breakerTrait = Trait(
    meta: newMeta(),
    name: 'Breaker',
    parentTraitId: switchTrait.meta.id,
    scope: const [TraitScope.sku],
  );
  final serializable = SerializableTrait.define(
    traitMeta: newMeta(),
    attributeMeta: newMeta(),
  );

  setUp(() {
    catalog = InMemoryCatalog();
  });

  final breaker = Sku(
    meta: newMeta(),
    manufacturerId: 'square-d',
    modelNumber: 'QO120',
    traitIds: [breakerTrait.meta.id],
    attributeValues: const {'rated_amps': 20, 'trip_amperage': 20},
  );
  final panel = Sku(
    meta: newMeta(),
    manufacturerId: 'square-d',
    modelNumber: 'QO-16',
    traitIds: [serializable.trait.meta.id],
  );
  final subPanel = Sku(
    meta: newMeta(),
    manufacturerId: 'square-d',
    modelNumber: 'QO-4',
  );

  /// One trait tree, its typed attributes, and three models — the catalog every
  /// case below builds on.
  Future<void> classifyAndCatalogue() async {
    await CreateTrait(catalog.traits)(trait: switchTrait).run();
    await CreateTrait(catalog.traits)(trait: breakerTrait).run();
    await CreateTrait(catalog.traits)(trait: serializable.trait).run();
    await CreateTraitAttributeDefinition(catalog.attributes)(
      attribute: serializable.serialNumber,
    ).run();
    await CreateTraitAttributeDefinition(catalog.attributes)(
      attribute: TraitAttributeDefinition(
        meta: newMeta(),
        traitId: switchTrait.meta.id,
        key: 'rated_amps',
        displayLabel: 'Rated Amperage',
        dataType: DataType.number,
        unit: 'A',
        isRequired: true,
      ),
    ).run();
    await CreateTraitAttributeDefinition(catalog.attributes)(
      attribute: TraitAttributeDefinition(
        meta: newMeta(),
        traitId: breakerTrait.meta.id,
        key: 'trip_amperage',
        displayLabel: 'Trip Amperage',
        dataType: DataType.number,
        unit: 'A',
      ),
    ).run();

    for (final sku in [breaker, panel, subPanel]) {
      (await catalog.createSku(sku: sku).run()).isRight().should.beTrue();
    }
  }

  test('a trait tree resolves down, so the child carries the parent', () async {
    await classifyAndCatalogue();

    final resolved = await catalog.schema(traitIds: breaker.traitIds).run();

    final names = resolved
        .getOrElse((_) => [])
        .map((attribute) => attribute.name)
        .toList();
    // The child's own attribute, and the one it inherits from Switch.
    names.should.contain('Trip Amperage');
    names.should.contain('Rated Amperage');
  });

  test('an assembly consumes what it holds, at every level', () async {
    await classifyAndCatalogue();

    // The panel holds eight breakers and four sub-panels; each sub-panel holds
    // four breakers. The edge is then tried the other way round on purpose.
    (await catalog
            .addSkuComponent(
              parentSkuId: panel.meta.id,
              childSkuId: breaker.meta.id,
              quantity: 8,
            )
            .run())
        .isRight()
        .should
        .beTrue();
    (await catalog
            .addSkuComponent(
              parentSkuId: panel.meta.id,
              childSkuId: subPanel.meta.id,
              quantity: 4,
            )
            .run())
        .isRight()
        .should
        .beTrue();
    (await catalog
            .addSkuComponent(
              parentSkuId: subPanel.meta.id,
              childSkuId: breaker.meta.id,
              quantity: 4,
            )
            .run())
        .isRight()
        .should
        .beTrue();

    final loop = await catalog
        .addSkuComponent(
          parentSkuId: breaker.meta.id,
          childSkuId: panel.meta.id,
          quantity: 1,
        )
        .run();
    loop
        .fold((failure) => failure, (_) => fail('expected a refusal'))
        .should
        .beAssignableTo<WouldCreateCycleFailure>();

    // Two panels: eight breakers each, plus four sub-panels of four — reached
    // both ways, so the breaker is one line with the total.
    final bill = await catalog
        .billOfMaterials(skuId: panel.meta.id, units: 2)
        .run();

    final lines = bill.getOrElse((_) => fail('expected Right')).lines;
    lines
        .singleWhere((line) => line.modelNumber == 'QO120')
        .quantity
        .should
        .be(48);
    lines
        .singleWhere((line) => line.modelNumber == 'QO-4')
        .quantity
        .should
        .be(8);
  });

  test('a place holds what is placed in it, and a serial is held once', () async {
    await classifyAndCatalogue();
    final garage = Locate(meta: newMeta(), name: 'Garage');
    final panelPlace = Locate(
      meta: newMeta(),
      name: 'Panel Position',
      parentLocateId: garage.meta.id,
    );
    await catalog.createLocate(locate: garage).run();
    await catalog.createLocate(locate: panelPlace).run();

    final panelOne = Instance(
      meta: newMeta(),
      skuId: panel.meta.id,
      locateId: panelPlace.meta.id,
      name: 'Garage Panel 1',
      attributeValues: const {SerializableTrait.serialNumberKey: 'QO-0001'},
    );
    (await catalog.createInstance(instance: panelOne).run())
        .isRight()
        .should
        .beTrue();

    // The serial is an attribute value, and the trait marks it unique, so a second
    // article claiming it is refused.
    final second = await catalog
        .createInstance(
          instance: panelOne.copyWith(meta: newMeta(), name: 'Garage Panel 2'),
        )
        .run();
    second
        .fold((failure) => failure, (_) => fail('expected a refusal'))
        .should
        .beAssignableTo<DuplicateAttributeValueFailure>();

    final placed = await FetchInstancesByLocate(catalog.instances)(
      locateId: panelPlace.meta.id,
    ).run();
    placed.getOrElse((_) => []).single.name.should.be('Garage Panel 1');

    // An article carries its own classification and values, independent of its
    // model — which is what lets one SKU be wired two ways.
    final spare = panelOne.copyWith(
      name: 'Spare Panel',
      locateId: null,
      traitIds: const ['spare'],
      attributeValues: const {'note': 'not yet fitted'},
    );
    spare.isPlaced.should.beFalse();
    spare.traitIds.should.be(['spare']);
  });
}
