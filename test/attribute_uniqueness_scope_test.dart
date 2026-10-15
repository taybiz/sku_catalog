import 'package:fpdart/fpdart.dart';
import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/in_memory.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'package:test/test.dart';

/// A unique attribute is a statement about the catalog, not about one kind of
/// record. An article, a place and a maker all hold trait values, so a value
/// marked unique may be held by exactly one of them — whichever kind it is.
///
/// The canonical case is a serial number: a `serializable` trait carrying
/// `serial_number` marked `isUnique` means the catalog holds that number once,
/// and a place that claims a serial already spoken for is refused the same way a
/// second article would be.
void main() {
  late InMemoryCatalog catalog;

  Meta meta(String id) => Meta(
    id: id,
    notes: '',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  );

  setUp(() {
    catalog = InMemoryCatalog();
  });

  /// One `serializable` trait, carried by any of the three kinds, with the one
  /// unique string attribute it contributes.
  Future<void> seedSerializable() async {
    await CreateTrait(catalog.traits)(
      trait: Trait(
        meta: meta('serializable'),
        name: 'Serializable',
        scope: const [
          TraitScope.sku,
          TraitScope.locate,
          TraitScope.manufacturer,
        ],
      ),
    ).run();
    await CreateTraitAttributeDefinition(catalog.attributes)(
      attribute: TraitAttributeDefinition(
        meta: meta('serializable-serial_number'),
        traitId: 'serializable',
        key: 'serial_number',
        displayLabel: 'Serial Number',
        dataType: DataType.string,
        isUnique: true,
      ),
    ).run();
    // A model carrying the trait, so an article of it has the attribute in
    // scope the way a real one would.
    await catalog.skus
        .create(
          sku: Sku(
            meta: meta('ser'),
            manufacturerId: 'm',
            modelNumber: 'SER',
            traitIds: const ['serializable'],
          ),
        )
        .run();
  }

  Locate place(String id, Map<String, dynamic> values) => Locate(
    meta: meta(id),
    name: id,
    traitIds: const ['serializable'],
    attributeValues: values,
  );

  Manufacturer maker(String id, Map<String, dynamic> values) => Manufacturer(
    meta: meta(id),
    name: id,
    traitIds: const ['serializable'],
    attributeValues: values,
  );

  Instance article(String id, Map<String, dynamic> values) => Instance(
    meta: meta(id),
    skuId: 'ser',
    locateId: null,
    name: id,
    attributeValues: values,
  );

  DomainFailure refusalOf(Either<DomainFailure, Object?> result) =>
      result.fold<DomainFailure>(
        (failure) => failure,
        (_) => fail('expected the write to be refused'),
      );

  test('a place may not claim a value an article already holds', () async {
    await seedSerializable();
    await catalog
        .createInstance(instance: article('a1', {'serial_number': 'SN-0001'}))
        .run();

    final result = await catalog
        .createLocate(locate: place('rack-1', {'serial_number': 'SN-0001'}))
        .run();

    final failure = refusalOf(result);
    failure.should.beAssignableTo<DuplicateAttributeValueFailure>();
    failure.message.should.contain('SN-0001');
    failure.message.should.contain('a1');
    (await catalog.locates.fetchAll().run())
        .getOrElse((_) => [])
        .should
        .beEmpty();
  });

  test('a maker may not claim a value a place already holds', () async {
    await seedSerializable();
    await catalog
        .createLocate(locate: place('rack-1', {'serial_number': 'SN-0001'}))
        .run();

    final failure = refusalOf(
      await catalog
          .createManufacturer(
            manufacturer: maker('square-d', {'serial_number': 'SN-0001'}),
          )
          .run(),
    );

    failure.should.beAssignableTo<DuplicateAttributeValueFailure>();
    failure.message.should.contain('rack-1');
  });

  test('two places may not share a value', () async {
    await seedSerializable();
    await catalog
        .createLocate(locate: place('rack-1', {'serial_number': 'SN-0001'}))
        .run();

    refusalOf(
      await catalog
          .createLocate(locate: place('rack-2', {'serial_number': 'SN-0001'}))
          .run(),
    ).should.beAssignableTo<DuplicateAttributeValueFailure>();
  });

  test('a value nobody holds is accepted, whichever kind claims it', () async {
    await seedSerializable();

    (await catalog
            .createManufacturer(
              manufacturer: maker('square-d', {'serial_number': 'SN-0002'}),
            )
            .run())
        .isRight()
        .should
        .beTrue();
  });

  test('an update that keeps its own value is no clash with itself', () async {
    await seedSerializable();
    await catalog
        .createLocate(locate: place('rack-1', {'serial_number': 'SN-0001'}))
        .run();

    (await catalog
            .updateLocate(locate: place('rack-1', {'serial_number': 'SN-0001'}))
            .run())
        .isRight()
        .should
        .beTrue();
  });

  test('an update may not take a value another holder has', () async {
    await seedSerializable();
    await catalog
        .createManufacturer(
          manufacturer: maker('square-d', {'serial_number': 'SN-0001'}),
        )
        .run();
    await catalog.createLocate(locate: place('rack-1', {})).run();

    refusalOf(
      await catalog
          .updateLocate(locate: place('rack-1', {'serial_number': 'SN-0001'}))
          .run(),
    ).should.beAssignableTo<DuplicateAttributeValueFailure>();
  });

  test('an attribute nobody marked unique may repeat across kinds', () async {
    await seedSerializable();
    await CreateTraitAttributeDefinition(catalog.attributes)(
      attribute: TraitAttributeDefinition(
        meta: meta('serializable-lot'),
        traitId: 'serializable',
        key: 'lot_number',
        displayLabel: 'Lot',
        dataType: DataType.string,
      ),
    ).run();

    await catalog
        .createLocate(locate: place('rack-1', {'lot_number': 'L-7'}))
        .run();

    (await catalog
            .createManufacturer(
              manufacturer: maker('square-d', {'lot_number': 'L-7'}),
            )
            .run())
        .isRight()
        .should
        .beTrue();
  });
}
