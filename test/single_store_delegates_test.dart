import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/in_memory.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'package:test/test.dart';

/// The operations ring has a family of use cases whose whole job is to name a
/// store: read one record, read them all, write one through. They are one-liners,
/// which is exactly why they went untested — and why a wrong store, a wrong id or
/// a parameter swapped with its neighbour would ship unnoticed. Each is called
/// once here against the reference backend, on the record it is supposed to name.
void main() {
  late InMemoryCatalog catalog;

  Meta meta(String id) => Meta(
    id: id,
    notes: 'note',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  );

  setUp(() {
    catalog = InMemoryCatalog();
  });

  test('the SKU delegates read and write through their store', () async {
    await catalog.skus
        .create(
          sku: Sku(
            meta: meta('qo120'),
            manufacturerId: 'square-d',
            modelNumber: 'QO120',
          ),
        )
        .run();

    (await FetchAllSkus(
      catalog.skus,
    )().run()).getOrElse((_) => []).should.haveCount(1);
    (await FetchSkuById(catalog.skus)(id: 'qo120').run())
        .getOrElse((_) => fail('expected the model back'))
        .modelNumber
        .should
        .be('QO120');

    (await UpdateSku(
              skuRepository: catalog.skus,
              assertUniqueModelNumber: AssertUniqueModelNumber(catalog.skus),
            )(
              sku: Sku(
                meta: meta('qo120'),
                manufacturerId: 'square-d',
                modelNumber: 'QO120-2',
              ),
            )
            .run())
        .isRight()
        .should
        .beTrue();
    (await FetchSkuById(catalog.skus)(id: 'qo120').run())
        .getOrElse((_) => fail('expected the model back'))
        .modelNumber
        .should
        .be('QO120-2');
  });

  test('the instance delegate reads the article it names', () async {
    await catalog.instances
        .create(
          instance: Instance(
            meta: meta('pnl-1'),
            skuId: 'qo120',
            locateId: null,
            name: 'Panel 1',
          ),
        )
        .run();

    (await FetchInstanceById(catalog.instances)(id: 'pnl-1').run())
        .getOrElse((_) => fail('expected the article back'))
        .name
        .should
        .be('Panel 1');
  });

  test('the assembly delegate reads the edges a model holds', () async {
    await catalog.assemblies
        .create(
          component: SkuComponent(
            meta: meta('edge-1'),
            parentSkuId: 'panel',
            childSkuId: 'breaker',
            quantity: 12,
          ),
        )
        .run();

    (await FetchAllSkuComponents(
      catalog.assemblies,
    )().run()).getOrElse((_) => []).should.haveCount(1);
  });

  test('the image delegate reads the records of one owner', () async {
    await catalog.images
        .create(
          image: ImageRecord(
            id: 'img-1',
            owner: ImageOwner.instance,
            ownerId: 'pnl-1',
            filename: 'panel.jpg',
            storedPath: 'images/panel.jpg',
            createdAt: '2026-01-01T00:00:00.000Z',
          ),
        )
        .run();
    await catalog.images
        .create(
          image: ImageRecord(
            id: 'img-2',
            owner: ImageOwner.locate,
            ownerId: 'rack-1',
            filename: 'rack.jpg',
            storedPath: 'images/rack.jpg',
            createdAt: '2026-01-01T00:00:00.000Z',
          ),
        )
        .run();

    (await FetchImageRecords(catalog.images)(
      owner: ImageOwner.instance,
      ownerId: 'pnl-1',
    ).run()).getOrElse((_) => []).should.haveCount(1);
    (await FetchImageRecords(catalog.images)(
      owner: ImageOwner.locate,
      ownerId: 'pnl-1',
    ).run()).getOrElse((_) => []).should.beEmpty();
  });

  test('the catalog meta delegates read and write the one record', () async {
    // Nothing stored yet: the store answers with an empty meta rather than a
    // failure, because "the catalog has no notes yet" is not an error.
    (await FetchMeta(catalog.meta)().run())
        .getOrElse((_) => fail('expected the meta back'))
        .id
        .should
        .be('');

    (await UpdateMeta(catalog.meta)(
      meta: meta('catalog'),
    ).run()).isRight().should.beTrue();
    (await FetchMeta(catalog.meta)().run())
        .getOrElse((_) => fail('expected the meta back'))
        .notes
        .should
        .be('note');
  });

  test('a resolved attribute compares by everything it carries', () {
    final definition = TraitAttributeDefinition(
      meta: meta('a1'),
      traitId: 't1',
      key: 'k',
      displayLabel: 'K',
      dataType: DataType.string,
    );

    ResolvedAttribute attribute({Object? value = '20', String name = 'K'}) =>
        ResolvedAttribute(
          attributeId: 'a1',
          name: name,
          value: value,
          unit: 'A',
          source: AttributeValueSource.trait,
          def: definition,
          inheritedFrom: 'sku-1',
        );

    attribute().should.be(attribute());
    attribute().should.not.be(attribute(value: '30'));
    attribute().should.not.be(attribute(name: 'Other'));
  });

  test('a domain failure is only itself', () {
    // The failures are values, so they compare as values: a rule that refuses
    // with one kind is not a rule that refused with another.
    const notFound = NotFoundFailure('gone');
    const inUse = InUseFailure('in use');

    notFound.should.be(const NotFoundFailure('gone'));
    notFound.should.not.be(inUse);
    notFound.message.should.be('gone');
    inUse.message.should.be('in use');
  });
}
