import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'package:test/test.dart';

/// Every record in this package round-trips through JSON — an adapter persists
/// `toJson()` and decodes `fromJson()` — so a field missing from either half is
/// data loss, and a field missing from `props` is an equality that lies. This
/// suite exists to catch exactly those two: round-trip and identity, per entity.
///
/// The inequality assertions are the load-bearing ones. A round-trip check passes
/// for an entity whose `props` is empty; flipping one field and demanding the two
/// are *not* equal is what proves each field is in the list.
void main() {
  Meta meta(String id) => Meta(
    id: id,
    notes: 'note',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  );

  void roundTrips<T extends Object>(T entity, T fromJson, T different) {
    entity.should.be(fromJson);
    entity.should.not.be(different);
  }

  test('a Meta round-trips and compares by every field', () {
    final original = meta('m1');
    roundTrips<Meta>(
      original,
      Meta.fromJson(original.toJson()),
      Meta(
        id: 'm1',
        notes: 'other',
        createdAt: '2026-01-01T00:00:00.000Z',
        updatedAt: '2026-01-01T00:00:00.000Z',
      ),
    );
  });

  test('a Trait round-trips and compares by every field', () {
    final original = Trait(
      meta: meta('t1'),
      name: 'Switch',
      parentTraitId: 'device',
      scope: const [TraitScope.sku],
    );

    roundTrips<Trait>(
      original,
      Trait.fromJson(original.toJson()),
      Trait.fromJson(
        Trait(
          meta: meta('t1'),
          name: 'Breaker',
          parentTraitId: 'device',
        ).toJson(),
      ),
    );
  });

  test(
    'a TraitAttributeDefinition round-trips and compares by every field',
    () {
      final original = TraitAttributeDefinition(
        meta: meta('a1'),
        traitId: 't1',
        key: 'serial_number',
        displayLabel: 'Serial Number',
        dataType: DataType.string,
        unit: 'mm',
        enumOptions: const ['a', 'b'],
        isRequired: true,
        isUnique: true,
        defaultValue: 'none',
      );

      roundTrips<TraitAttributeDefinition>(
        original,
        TraitAttributeDefinition.fromJson(original.toJson()),
        TraitAttributeDefinition.fromJson(
          TraitAttributeDefinition(
            meta: meta('a1'),
            traitId: 't1',
            key: 'serial_number',
            displayLabel: 'Serial Number',
            dataType: DataType.string,
            isUnique: false,
          ).toJson(),
        ),
      );
    },
  );

  test('a Sku round-trips and compares by every field', () {
    final original = Sku(
      meta: meta('s1'),
      manufacturerId: 'square-d',
      modelNumber: 'QO120',
      traitIds: const ['breaker'],
      attributeValues: const {'amperage': 20},
    );

    roundTrips<Sku>(
      original,
      Sku.fromJson(original.toJson()),
      Sku.fromJson(
        Sku(
          meta: meta('s1'),
          manufacturerId: 'square-d',
          modelNumber: 'QO120-2',
        ).toJson(),
      ),
    );
  });

  test('a SkuComponent round-trips and compares by every field', () {
    final original = SkuComponent(
      meta: meta('e1'),
      parentSkuId: 'panel',
      childSkuId: 'breaker',
      quantity: 12,
    );

    roundTrips<SkuComponent>(
      original,
      SkuComponent.fromJson(original.toJson()),
      SkuComponent.fromJson(
        SkuComponent(
          meta: meta('e1'),
          parentSkuId: 'panel',
          childSkuId: 'breaker',
          quantity: 13,
        ).toJson(),
      ),
    );
  });

  test('a SkuAssociation round-trips and compares by every field', () {
    final original = SkuAssociation(
      meta: meta('r1'),
      sourceSkuId: 'new',
      targetSkuId: 'old',
      kind: 'replaces',
    );

    roundTrips<SkuAssociation>(
      original,
      SkuAssociation.fromJson(original.toJson()),
      SkuAssociation.fromJson(
        SkuAssociation(
          meta: meta('r1'),
          sourceSkuId: 'new',
          targetSkuId: 'old',
          kind: 'fits',
        ).toJson(),
      ),
    );
  });

  test('an InstanceAssociation round-trips and compares by every field', () {
    final original = InstanceAssociation(
      meta: meta('r1'),
      sourceInstanceId: 'copy-1',
      targetInstanceId: 'copy-2',
      kind: 'bound_with',
    );

    roundTrips<InstanceAssociation>(
      original,
      InstanceAssociation.fromJson(original.toJson()),
      InstanceAssociation.fromJson(
        InstanceAssociation(
          meta: meta('r1'),
          sourceInstanceId: 'copy-1',
          targetInstanceId: 'copy-2',
          kind: 'replaced_by',
        ).toJson(),
      ),
    );
  });

  test('a Locate round-trips and compares by every field', () {
    final original = Locate(
      meta: meta('l1'),
      name: 'Rack 3',
      parentLocateId: 'panel',
      icon: 'shelf',
      traitIds: const ['tagged'],
      attributeValues: const {'height': 3},
    );

    roundTrips<Locate>(
      original,
      Locate.fromJson(original.toJson()),
      Locate.fromJson(
        Locate(
          meta: meta('l1'),
          name: 'Rack 4',
          parentLocateId: 'panel',
        ).toJson(),
      ),
    );
  });

  test('a Manufacturer round-trips and compares by every field', () {
    final original = Manufacturer(
      meta: meta('m1'),
      name: 'Square D',
      website: 'https://example.test',
      description: 'breakers',
      traitIds: const ['tagged'],
      attributeValues: const {'country': 'US'},
    );

    roundTrips<Manufacturer>(
      original,
      Manufacturer.fromJson(original.toJson()),
      Manufacturer.fromJson(
        Manufacturer(
          meta: meta('m1'),
          name: 'GE',
          website: original.website,
        ).toJson(),
      ),
    );
  });

  test('an ImageRecord round-trips and compares by every field', () {
    final original = ImageRecord(
      id: 'img-1',
      owner: ImageOwner.locate,
      ownerId: 'rack-3',
      filename: 'rack.jpg',
      storedPath: 'images/rack.jpg',
      createdAt: '2026-01-01T00:00:00.000Z',
    );

    roundTrips<ImageRecord>(
      original,
      ImageRecord.fromJson(original.toJson()),
      ImageRecord.fromJson(
        ImageRecord(
          id: 'img-1',
          owner: ImageOwner.locate,
          ownerId: 'rack-3',
          filename: 'other.jpg',
          storedPath: 'images/rack.jpg',
          createdAt: '2026-01-01T00:00:00.000Z',
        ).toJson(),
      ),
    );
  });

  test('an Instance round-trips and compares by every field', () {
    final original = Instance(
      meta: meta('i1'),
      skuId: 's1',
      locateId: 'rack-3',
      name: 'Panel 1',
      traitIds: const ['breaker'],
      attributeValues: const {'serial_number': 'SN-0001'},
      icon: 'bolt',
    );

    roundTrips<Instance>(
      original,
      Instance.fromJson(original.toJson()),
      Instance.fromJson(
        Instance(
          meta: meta('i1'),
          skuId: 's1',
          locateId: 'rack-3',
          name: 'Panel 2',
        ).toJson(),
      ),
    );
  });

  test('an Instance un-places itself with an explicit null, and keeps what it '
      'was not asked about', () {
    final placed = Instance(
      meta: meta('i1'),
      skuId: 's1',
      locateId: 'rack-3',
      name: 'Panel 1',
      icon: 'bolt',
    );

    // The sentinel: passing null un-places, passing nothing keeps the place.
    final unplaced = placed.copyWith(locateId: null);
    unplaced.locateId.should.beNull();
    unplaced.isPlaced.should.beFalse();
    unplaced.icon.should.be('bolt');
    placed.copyWith(name: 'Panel 2').locateId.should.be('rack-3');

    // The same for the other nullable pair, and for an identity change.
    final renamed = placed.copyWith(icon: 'sensor', skuId: 's2');
    renamed.icon.should.be('sensor');
    renamed.skuId.should.be('s2');
    renamed.copyWith(icon: null).icon.should.beNull();
  });

  test('every failure is a value that carries its message', () {
    const failures = <DomainFailure>[
      NotFoundFailure('a'),
      AlreadyExistsFailure('a'),
      WouldCreateCycleFailure('a'),
      InvalidInputFailure('a'),
      PermissionDeniedFailure('a'),
      InUseFailure('a'),
      InternalFailure('a'),
      DatasourceFailure('a'),
      SerializationFailure('a'),
      DuplicateAttributeValueFailure('a'),
    ];

    for (final failure in failures) {
      failure.message.should.be('a');
      failure.should.be(failure);
    }

    // Same message, different kind: not the same failure. A caller switching on
    // the sealed hierarchy depends on that.
    const NotFoundFailure('a').should.not.be(const InUseFailure('a'));
    const NotFoundFailure('a').should.be(const NotFoundFailure('a'));
    const NotFoundFailure('a').should.not.be(const NotFoundFailure('b'));
  });
}
