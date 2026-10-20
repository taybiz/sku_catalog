import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/in_memory.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'package:test/test.dart';

/// The reference backend is the worked example of a composition root, and it has a
/// rule worth holding it to: **every operation that takes a `UnitOfWork` is wired
/// here**, because a transaction is a composition decision. That is all fourteen.
///
/// Naming each one is compile-time proof the root still exposes it, and the count is
/// the reminder to add the next one in both places. The second group runs the three
/// that had been left out of the example — a deleted trait with its attribute
/// definitions, a model association, an assembly edge updated — through the root, so
/// the wiring is exercised rather than merely present.
void main() {
  test('the root wires every operation that takes a unit of work', () {
    final catalog = InMemoryCatalog();

    final wired = <Object>[
      catalog.createInstance,
      catalog.updateInstance,
      catalog.createLocate,
      catalog.updateLocate,
      catalog.createManufacturer,
      catalog.updateManufacturer,
      catalog.deleteInstance,
      catalog.deleteInstanceAndUnusedSku,
      catalog.deleteSku,
      catalog.deleteTrait,
      catalog.updateSkuComponent,
      catalog.addSkuComponent,
      catalog.addSkuAssociation,
      catalog.addInstanceAssociation,
    ];

    wired.length.should.be(14);
  });

  test('an assembly edge is added and updated through the root', () async {
    final catalog = InMemoryCatalog();
    final base = newMeta();
    final part = newMeta();
    await catalog.skus
        .create(
          sku: Sku(meta: base, manufacturerId: 'acme', modelNumber: 'BASE-1'),
        )
        .run();
    await catalog.skus
        .create(
          sku: Sku(meta: part, manufacturerId: 'acme', modelNumber: 'PART-1'),
        )
        .run();

    final added = await catalog
        .addSkuComponent(parentSkuId: base.id, childSkuId: part.id, quantity: 2)
        .run();
    final component = added.getOrElse((_) => fail('expected Right'));

    // The contract has no update path, so this is a delete and a re-create — the
    // two writes the root's transaction exists to cover.
    (await catalog
            .updateSkuComponent(skuId: component.meta.id, quantity: 5)
            .run())
        .isRight()
        .should
        .beTrue();

    final stored = (await catalog.assemblies.fetchAll().run()).getOrElse(
      (_) => [],
    );
    stored.should.haveCount(1);
    stored.single.quantity.should.be(5);
    stored.single.parentSkuId.should.be(base.id);
  });

  test('a model association and a trait delete run through the root', () async {
    final catalog = InMemoryCatalog();
    final left = newMeta();
    final right = newMeta();
    for (final (meta, number) in [(left, 'L-1'), (right, 'R-1')]) {
      await catalog.skus
          .create(
            sku: Sku(meta: meta, manufacturerId: 'acme', modelNumber: number),
          )
          .run();
    }

    (await catalog
            .addSkuAssociation(
              sourceSkuId: left.id,
              targetSkuId: right.id,
              kind: 'edited',
            )
            .run())
        .isRight()
        .should
        .beTrue();
    (await catalog.associations.fetchAll().run())
        .getOrElse((_) => [])
        .single
        .kind
        .should
        .be('edited');

    final trait = Trait(meta: newMeta(), name: 'Fastener');
    await catalog.traits.create(trait: trait).run();
    await catalog.attributes
        .create(
          attribute: TraitAttributeDefinition(
            meta: newMeta(),
            traitId: trait.meta.id,
            key: 'thread',
            displayLabel: 'Thread',
            dataType: DataType.string,
          ),
        )
        .run();

    // The attribute definition hangs off the trait, so the delete cascades — the
    // other half of what the root's transaction covers.
    (await catalog.deleteTrait(id: trait.meta.id).run())
        .isRight()
        .should
        .beTrue();
    (await catalog.traits.fetchAll().run())
        .getOrElse((_) => [])
        .should
        .beEmpty();
    (await catalog.attributes.fetchAll().run())
        .getOrElse((_) => [])
        .should
        .beEmpty();
  });
}
