import 'package:fpdart/fpdart.dart';
import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/in_memory.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'package:test/test.dart';

/// A maker is a holder, so its writes run the model's rules the way an article's
/// do — including the one this release widened: a value marked `isUnique` may be
/// held once across articles, places and makers, and both maker write paths are
/// guarded. It is also blocked from deletion while a model still names it.
void main() {
  late InMemoryCatalog catalog;

  Meta meta(String id) => Meta(
    id: id,
    notes: '',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  );

  Manufacturer makerOf(
    String id, {
    Map<String, dynamic> values = const {},
    List<String> traitIds = const [],
  }) => Manufacturer(
    meta: meta(id),
    name: id,
    traitIds: traitIds,
    attributeValues: values,
  );

  setUp(() {
    catalog = InMemoryCatalog();
  });

  /// A `serializable` trait every carrier may hold, and a model that carries it,
  /// so an article of that model has `serial_number` in scope.
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
    await catalog.skus
        .create(
          sku: Sku(
            meta: meta('ser'),
            manufacturerId: 'square-d',
            modelNumber: 'SER',
            traitIds: const ['serializable'],
          ),
        )
        .run();
  }

  DomainFailure refusalOf(Either<DomainFailure, Object?> result) =>
      result.fold<DomainFailure>(
        (failure) => failure,
        (_) => fail('expected a refusal'),
      );

  test('a maker is created and updated through the guarded paths', () async {
    (await catalog.createManufacturer(manufacturer: makerOf('square-d')).run())
        .isRight()
        .should
        .beTrue();

    (await catalog
            .updateManufacturer(
              manufacturer: makerOf('square-d', values: {'website': 'x'}),
            )
            .run())
        .isRight()
        .should
        .beTrue();
    final stored = (await FetchManufacturerById(catalog.manufacturers)(
      id: 'square-d',
    ).run()).getOrElse((_) => fail('expected the maker back'));
    (stored.attributeValues['website'] as String).should.be('x');
  });

  test('an update may not take a value another holder already has', () async {
    await seedSerializable();
    await catalog
        .createInstance(
          instance: Instance(
            meta: meta('pnl-1'),
            skuId: 'ser',
            locateId: null,
            name: 'Panel 1',
            attributeValues: const {'serial_number': 'SN-0001'},
          ),
        )
        .run();
    await catalog.createManufacturer(manufacturer: makerOf('square-d')).run();

    refusalOf(
      await catalog
          .updateManufacturer(
            manufacturer: makerOf(
              'square-d',
              traitIds: const ['serializable'],
              values: const {'serial_number': 'SN-0001'},
            ),
          )
          .run(),
    ).should.beAssignableTo<DuplicateAttributeValueFailure>();
  });

  test('a maker keeping its own value is no clash with itself', () async {
    await seedSerializable();
    await catalog
        .createManufacturer(
          manufacturer: makerOf(
            'square-d',
            traitIds: const ['serializable'],
            values: const {'serial_number': 'SN-0002'},
          ),
        )
        .run();

    (await catalog
            .updateManufacturer(
              manufacturer: makerOf(
                'square-d',
                traitIds: const ['serializable'],
                values: const {'serial_number': 'SN-0002'},
              ),
            )
            .run())
        .isRight()
        .should
        .beTrue();
  });

  test('a maker a model names may not be deleted', () async {
    await catalog.createManufacturer(manufacturer: makerOf('square-d')).run();
    await catalog.createManufacturer(manufacturer: makerOf('spare')).run();
    await catalog.skus
        .create(
          sku: Sku(
            meta: meta('qo120'),
            manufacturerId: 'square-d',
            modelNumber: 'QO120',
          ),
        )
        .run();
    final deleteMaker = DeleteManufacturer(
      manufacturerRepository: catalog.manufacturers,
      skuRepository: catalog.skus,
    );

    refusalOf(
      await deleteMaker(id: 'square-d').run(),
    ).message.should.contain('in use by one or more SKUs');

    (await deleteMaker(id: 'spare').run()).isRight().should.beTrue();
    (await FetchAllManufacturers(
      catalog.manufacturers,
    )().run()).getOrElse((_) => []).should.haveCount(1);
  });
}
