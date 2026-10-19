import 'package:fpdart/fpdart.dart';
import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'package:test/test.dart';

import 'package:sku_catalog/in_memory.dart';

/// A unique attribute is the one rule a *value* carries about itself: at most one
/// article in the catalog may hold it. A serial number is the case that makes the
/// rule necessary — two articles of the same model cannot be the same article —
/// which is why serial numbers are a trait attribute here rather than a field on
/// the entity: the trait says "this model is serializable", the value says "this
/// is serial number X", and `isUnique` makes the catalog refuse a second X.
///
/// This suite proves the rule holds through the canonical `serializable` trait,
/// through a trait of the caller's own, through an inherited one, and through a
/// trait the instance carries itself — and that it stays out of the way of every
/// attribute nobody marked unique.
void main() {
  late InMemoryTraitRepository traits;
  late InMemoryTraitAttributeDefinitionRepository attributes;
  late InMemorySkuRepository skus;
  late InMemoryInstanceRepository instances;
  late InMemorySkuComponentRepository components;
  late InMemoryImageRepository images;
  late InMemoryLocateRepository locates;
  late InMemoryManufacturerRepository manufacturers;

  Meta meta(String id) => Meta(
    id: id,
    notes: '',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  );

  ResolveInstanceSchema schemaResolver() => ResolveInstanceSchema(
    skuRepository: skus,
    resolveSchema: ResolveSchema(
      traitRepository: traits,
      attributeRepository: attributes,
    ),
  );

  AssertUniqueAttributeValues uniqueness() => AssertUniqueAttributeValues(
    instanceRepository: instances,
    locateRepository: locates,
    manufacturerRepository: manufacturers,
    resolveInstanceSchema: schemaResolver(),
    resolveSchema: ResolveSchema(
      traitRepository: traits,
      attributeRepository: attributes,
    ),
  );

  CreateInstance createInstance() => CreateInstance(
    instanceRepository: instances,
    assertUniqueInstanceName: AssertUniqueInstanceName(instances),
    assertUniqueAttributeValues: uniqueness(),
  );

  UpdateInstance updateInstance() => UpdateInstance(
    instanceRepository: instances,
    assertUniqueInstanceName: AssertUniqueInstanceName(instances),
    assertUniqueAttributeValues: uniqueness(),
  );

  DuplicateInstance duplicator() => DuplicateInstance(
    instanceRepository: instances,
    resolveInstanceSchema: schemaResolver(),
  );

  Instance article(
    String id,
    String name, {
    String sku = 'ser',
    Map<String, dynamic> values = const {},
    List<String> traitIds = const [],
  }) => Instance(
    meta: meta(id),
    skuId: sku,
    locateId: null,
    name: name,
    traitIds: traitIds,
    attributeValues: values,
  );

  DomainFailure refusalOf(Either<DomainFailure, Object?> result) =>
      result.fold<DomainFailure>(
        (failure) => failure,
        (_) => fail('expected a Left'),
      );

  setUp(() async {
    traits = InMemoryTraitRepository();
    attributes = InMemoryTraitAttributeDefinitionRepository();
    skus = InMemorySkuRepository();
    instances = InMemoryInstanceRepository();
    components = InMemorySkuComponentRepository();
    images = InMemoryImageRepository();
    locates = InMemoryLocateRepository();
    manufacturers = InMemoryManufacturerRepository();

    // The canonical one: a serializable model, its serial number unique.
    final serializable = SerializableTrait.define(
      traitMeta: meta('serializable'),
      attributeMeta: meta('serializable-serial_number'),
    );
    // A trait of the caller's own, with a unique attribute.
    final asset = Trait(
      meta: meta('asset'),
      name: 'Asset',
      scope: const [TraitScope.sku],
    );
    // A child of it: inherits the unique attribute without redeclaring it.
    final rented = Trait(
      meta: meta('asset-rented'),
      name: 'Rented',
      parentTraitId: 'asset',
      scope: const [TraitScope.sku],
    );
    // A trait with one unique attribute and one that is not.
    final batch = Trait(
      meta: meta('batch'),
      name: 'Batch',
      scope: const [TraitScope.sku],
    );

    await CreateTrait(traits)(trait: serializable.trait).run();
    await CreateTraitAttributeDefinition(attributes)(
      attribute: serializable.serialNumber,
    ).run();
    await CreateTrait(traits)(trait: asset).run();
    await CreateTrait(traits)(trait: rented).run();
    await CreateTrait(traits)(trait: batch).run();

    await CreateTraitAttributeDefinition(attributes)(
      attribute: TraitAttributeDefinition(
        meta: meta('asset-tag'),
        traitId: 'asset',
        key: 'asset_tag',
        displayLabel: 'Asset Tag',
        dataType: DataType.string,
        isUnique: true,
      ),
    ).run();
    await CreateTraitAttributeDefinition(attributes)(
      attribute: TraitAttributeDefinition(
        meta: meta('batch-lot'),
        traitId: 'batch',
        key: 'lot_code',
        displayLabel: 'Lot',
        dataType: DataType.string,
      ),
    ).run();
    await CreateTraitAttributeDefinition(attributes)(
      attribute: TraitAttributeDefinition(
        meta: meta('batch-ref'),
        traitId: 'batch',
        key: 'batch_ref',
        displayLabel: 'Batch Reference',
        dataType: DataType.string,
        isUnique: true,
      ),
    ).run();

    // Models: one serializable, one plain, one of the caller's own trait, one
    // that only inherits it, one batched.
    Future<void> sku(String id, {List<String> traitIds = const []}) =>
        CreateSku(
              skuRepository: skus,
              assertUniqueModelNumber: AssertUniqueModelNumber(skus),
            )(
              sku: Sku(
                meta: meta(id),
                manufacturerId: 'm',
                modelNumber: id.toUpperCase(),
                traitIds: traitIds,
              ),
            )
            .run();
    await sku('ser', traitIds: const ['serializable']);
    await sku('plain');
    await sku('tagged', traitIds: const ['asset']);
    await sku('rented', traitIds: const ['asset-rented']);
    await sku('batched', traitIds: const ['batch']);
  });

  group('Given a serializable model and its serial numbers', () {
    test('Then two articles of it may not share a serial number', () async {
      await createInstance()(
        instance: article('i1', 'Article 1', values: {'serial_number': 'SN-1'}),
      ).run();

      final clash = await createInstance()(
        instance: article('i2', 'Article 2', values: {'serial_number': 'SN-1'}),
      ).run();

      clash.isLeft().should.beTrue();
      final failure = refusalOf(clash);
      failure.should.beAssignableTo<DuplicateAttributeValueFailure>();
      (failure as DuplicateAttributeValueFailure).message.should.contain(
        'serial_number',
      );
      // The refused article was never stored.
      (await instances.fetchAll().run())
          .getOrElse((_) => [])
          .should
          .haveCount(1);
    });

    test('Then a serial number nobody else holds is accepted', () async {
      await createInstance()(
        instance: article('i1', 'Article 1', values: {'serial_number': 'SN-1'}),
      ).run();

      final other = await createInstance()(
        instance: article('i2', 'Article 2', values: {'serial_number': 'SN-2'}),
      ).run();

      other.isRight().should.beTrue();
      (await instances.fetchAll().run())
          .getOrElse((_) => [])
          .should
          .haveCount(2);
    });

    test(
      'Then the rule spans models: a different SKU carrying the trait shares it',
      () async {
        await createInstance()(
          instance: article(
            'i1',
            'Article 1',
            values: {'serial_number': 'SN-1'},
          ),
        ).run();

        // The instance's own trait, rather than its model's: the same trait is
        // in scope either way, so the same serial number is still taken.
        final clash = await createInstance()(
          instance: article(
            'i2',
            'Article 2',
            sku: 'plain',
            traitIds: const ['serializable'],
            values: {'serial_number': 'SN-1'},
          ),
        ).run();

        clash
            .fold<DomainFailure>((f) => f, (_) => fail('expected Left'))
            .should
            .beAssignableTo<DuplicateAttributeValueFailure>();
      },
    );

    test(
      'Then case and surrounding space do not make it another serial',
      () async {
        await createInstance()(
          instance: article(
            'i1',
            'Article 1',
            values: {'serial_number': 'SN-1'},
          ),
        ).run();

        final clash = await createInstance()(
          instance: article(
            'i2',
            'Article 2',
            values: {'serial_number': ' sn-1 '},
          ),
        ).run();

        clash
            .fold<DomainFailure>((f) => f, (_) => fail('expected Left'))
            .should
            .beAssignableTo<DuplicateAttributeValueFailure>();
      },
    );

    test(
      'Then an article that sets no serial number is never a clash',
      () async {
        await createInstance()(instance: article('i1', 'Article 1')).run();

        final second = await createInstance()(
          instance: article('i2', 'Article 2', values: {'lot_code': 'L1'}),
        ).run();

        second.isRight().should.beTrue();
      },
    );

    test(
      'Then an article may keep its own serial number when it is updated',
      () async {
        await createInstance()(
          instance: article(
            'i1',
            'Article 1',
            values: {'serial_number': 'SN-1'},
          ),
        ).run();

        final kept = await updateInstance()(
          instance: article(
            'i1',
            'Article 1 renamed',
            values: {'serial_number': 'SN-1'},
          ),
        ).run();

        kept.isRight().should.beTrue();
      },
    );

    test(
      'Then taking a serial number another article holds is refused',
      () async {
        await createInstance()(
          instance: article(
            'i1',
            'Article 1',
            values: {'serial_number': 'SN-1'},
          ),
        ).run();
        await createInstance()(
          instance: article(
            'i2',
            'Article 2',
            values: {'serial_number': 'SN-2'},
          ),
        ).run();

        final clash = await updateInstance()(
          instance: article(
            'i1',
            'Article 1',
            values: {'serial_number': 'SN-2'},
          ),
        ).run();

        clash
            .fold<DomainFailure>((f) => f, (_) => fail('expected Left'))
            .should
            .beAssignableTo<DuplicateAttributeValueFailure>();
      },
    );

    test(
      'Then giving a serial number up frees it for another article',
      () async {
        await createInstance()(
          instance: article(
            'i1',
            'Article 1',
            values: {'serial_number': 'SN-1'},
          ),
        ).run();
        await createInstance()(
          instance: article(
            'i2',
            'Article 2',
            values: {'serial_number': 'SN-2'},
          ),
        ).run();

        // i2 is re-serialised, which releases SN-2...
        await updateInstance()(
          instance: article(
            'i2',
            'Article 2',
            values: {'serial_number': 'SN-3'},
          ),
        ).run();
        // ...so i1 may take it.
        final taken = await updateInstance()(
          instance: article(
            'i1',
            'Article 1',
            values: {'serial_number': 'SN-2'},
          ),
        ).run();

        taken.isRight().should.beTrue();
      },
    );

    test('Then deleting an article frees its serial number', () async {
      await createInstance()(
        instance: article('i1', 'Article 1', values: {'serial_number': 'SN-1'}),
      ).run();

      await DeleteInstance(
        instanceRepository: instances,
        imageRepository: images,
        instanceAssociationRepository: InMemoryInstanceAssociationRepository(),
      )(id: 'i1').run();

      final reused = await createInstance()(
        instance: article('i2', 'Article 2', values: {'serial_number': 'SN-1'}),
      ).run();

      reused.isRight().should.beTrue();
    });

    test(
      'Then a copy is a new article and takes no serial number with it',
      () async {
        await createInstance()(
          instance: article(
            'i1',
            'Article 1',
            traitIds: const ['batch'],
            values: {
              'serial_number': 'SN-1',
              'batch_ref': 'BR-1',
              'lot_code': 'L1',
            },
          ),
        ).run();

        final copied = await duplicator()(id: 'i1').run();

        final copy = copied.getOrElse((_) => fail('expected Right'));
        // Every unique attribute is dropped — the copy has no serial yet — while
        // the values that are not unique are carried over with the classification.
        copy.attributeValues.containsKey('serial_number').should.beFalse();
        copy.attributeValues.containsKey('batch_ref').should.beFalse();
        (copy.attributeValues['lot_code'] as String).should.be('L1');
        (await instances.fetchAll().run())
            .getOrElse((_) => [])
            .should
            .haveCount(2);
      },
    );
  });

  group('Given any other trait with a unique attribute', () {
    test('Then the caller\'s own unique attribute is enforced too', () async {
      await createInstance()(
        instance: article(
          'i1',
          'Article 1',
          sku: 'tagged',
          values: {'asset_tag': 'T-1'},
        ),
      ).run();

      final clash = await createInstance()(
        instance: article(
          'i2',
          'Article 2',
          sku: 'tagged',
          values: {'asset_tag': 'T-1'},
        ),
      ).run();

      clash
          .fold<DomainFailure>((f) => f, (_) => fail('expected Left'))
          .should
          .beAssignableTo<DuplicateAttributeValueFailure>();
    });

    test(
      'Then a unique attribute inherited from a parent trait is enforced',
      () async {
        await createInstance()(
          instance: article(
            'i1',
            'Article 1',
            sku: 'tagged',
            values: {'asset_tag': 'T-1'},
          ),
        ).run();

        // 'rented' declares no attribute of its own: it inherits asset_tag, and
        // inheriting it makes the value unique for it too.
        final clash = await createInstance()(
          instance: article(
            'i2',
            'Article 2',
            sku: 'rented',
            values: {'asset_tag': 'T-1'},
          ),
        ).run();

        clash
            .fold<DomainFailure>((f) => f, (_) => fail('expected Left'))
            .should
            .beAssignableTo<DuplicateAttributeValueFailure>();
      },
    );

    test(
      'Then a unique attribute the instance carries itself is enforced',
      () async {
        await createInstance()(
          instance: article(
            'i1',
            'Article 1',
            sku: 'plain',
            traitIds: const ['asset'],
            values: {'asset_tag': 'T-1'},
          ),
        ).run();

        final clash = await createInstance()(
          instance: article(
            'i2',
            'Article 2',
            sku: 'plain',
            traitIds: const ['asset'],
            values: {'asset_tag': 'T-1'},
          ),
        ).run();

        clash.isLeft().should.beTrue();
      },
    );

    test('Then an attribute nobody marked unique may repeat', () async {
      await createInstance()(
        instance: article(
          'i1',
          'Article 1',
          sku: 'batched',
          values: {'lot_code': 'L1'},
        ),
      ).run();

      final second = await createInstance()(
        instance: article(
          'i2',
          'Article 2',
          sku: 'batched',
          values: {'lot_code': 'L1'},
        ),
      ).run();

      second.isRight().should.beTrue();
    });

    test('Then the resolution says which of them are unique', () async {
      await createInstance()(
        instance: article(
          'i1',
          'Article 1',
          sku: 'batched',
          values: {'serial_number': 'SN-1', 'lot_code': 'L1'},
        ),
      ).run();

      final resolved = await ResolveEffectiveAttributes(
        instanceRepository: instances,
        skuRepository: skus,
        skuComponentRepository: components,
        resolveSchema: ResolveSchema(
          traitRepository: traits,
          attributeRepository: attributes,
        ),
      )(instanceId: 'i1').run();

      final schema = resolved.getOrElse((_) => fail('expected Right'));
      // 'batched' carries no serializable trait, so the serial number key is not
      // in its schema at all; the keys it does define report their own flags.
      final byKey = {for (final a in schema) a.def.key: a.def};
      byKey.containsKey('serial_number').should.beFalse();
      byKey['lot_code']!.isUnique.should.beFalse();

      // The serializable model's own schema carries the flag.
      await createInstance()(
        instance: article('i2', 'Article 2', values: {'serial_number': 'SN-2'}),
      ).run();
      final serialSchema = await ResolveEffectiveAttributes(
        instanceRepository: instances,
        skuRepository: skus,
        skuComponentRepository: components,
        resolveSchema: ResolveSchema(
          traitRepository: traits,
          attributeRepository: attributes,
        ),
      )(instanceId: 'i2').run();

      final serialAttrs = serialSchema.getOrElse((_) => fail('expected Right'));
      serialAttrs
          .singleWhere((a) => a.def.key == 'serial_number')
          .def
          .isUnique
          .should
          .beTrue();
    });
  });

  group('Given the schema in scope for an article', () {
    test("Then the instance's own traits and its model's are merged", () async {
      final resolved = await schemaResolver()(
        instance: article('i1', 'Article 1', traitIds: const ['batch']),
      ).run();

      final keys = {
        for (final entry in resolved.getOrElse((_) => fail('expected Right')))
          entry.def.key,
      };
      // The batch keys came from the instance, the serial number from its model.
      keys.should.contain('lot_code');
      keys.should.contain('batch_ref');
      keys.should.contain('serial_number');
    });

    test(
      'Then an article whose model nobody stored still resolves its own',
      () async {
        final resolved = await schemaResolver()(
          instance: article(
            'i1',
            'Article 1',
            sku: 'ghost',
            traitIds: const ['batch'],
          ),
        ).run();

        final keys = {
          for (final entry in resolved.getOrElse((_) => fail('expected Right')))
            entry.def.key,
        };
        keys.should.contain('lot_code');
        keys.contains('serial_number').should.beFalse();
      },
    );
  });

  group('Given two values for a unique attribute', () {
    // The attribute decides: a serial number is the same serial number whether it
    // was typed in another case or with space around it.
    late TraitAttributeDefinition serialNumber;

    setUp(() {
      serialNumber = SerializableTrait.define(
        traitMeta: meta('serializable'),
        attributeMeta: meta('serializable-serial_number'),
      ).serialNumber;
    });

    test(
      'Then the same string in another case or spacing is the same value',
      () {
        serialNumber.valuesMatch(a: 'SN-1', b: ' sn-1 ').should.beTrue();
      },
    );

    test('Then 20 and 20.0 are one number', () {
      serialNumber.valuesMatch(a: 20, b: 20.0).should.beTrue();
    });

    test(
      'Then a number and the string that reads like it are different values',
      () {
        serialNumber.valuesMatch(a: 20, b: '20').should.beFalse();
      },
    );

    test('Then a value nobody set clashes with nothing', () {
      serialNumber.valuesMatch(a: null, b: null).should.beFalse();
      serialNumber.valuesMatch(a: null, b: 'SN-1').should.beFalse();
      serialNumber.valuesMatch(a: 'SN-1', b: null).should.beFalse();
    });
  });

  group('Given the canonical serializable trait', () {
    test(
      'Then it is a sku-scoped classification with a unique serial number',
      () {
        final serializable = SerializableTrait.define(
          traitMeta: meta('serializable'),
          attributeMeta: meta('serializable-serial_number'),
        );

        serializable.trait.name.should.be('Serializable');
        serializable.trait.scope.should.be([TraitScope.sku]);
        serializable.serialNumber.traitId.should.be('serializable');
        serializable.serialNumber.key.should.be('serial_number');
        serializable.serialNumber.dataType.should.be(DataType.string);
        serializable.serialNumber.isUnique.should.beTrue();
      },
    );

    test('Then it round-trips through JSON with the flag intact', () {
      final serializable = SerializableTrait.define(
        traitMeta: meta('serializable'),
        attributeMeta: meta('serializable-serial_number'),
      );

      final attribute = TraitAttributeDefinition.fromJson(
        serializable.serialNumber.toJson(),
      );
      attribute.isUnique.should.beTrue();
      // Bind before asserting: shouldly does not dispatch on a dynamic receiver.
      (attribute.toJson()['is_unique'] as bool).should.beTrue();

      Trait.fromJson(
        serializable.trait.toJson(),
      ).scope.should.be([TraitScope.sku]);
    });

    test('Then an attribute is not unique unless it says so', () {
      final attribute = TraitAttributeDefinition(
        meta: meta('plain-attr'),
        traitId: 'plain',
        key: 'colour',
        displayLabel: 'Colour',
        dataType: DataType.string,
      );

      attribute.isUnique.should.beFalse();
      // A record written before the flag existed reads back as not unique.
      TraitAttributeDefinition.fromJson(
        attribute.toJson(),
      ).isUnique.should.beFalse();
    });
  });

  group('Given an instance record written before serial numbers moved', () {
    test('Then its serial number field is not resurrected as an attribute', () {
      // The old shape carried `serial_number` at the top level. The entity no
      // longer reads it: a consumer maps it to the serializable trait's
      // `serial_number` attribute on the way in, and nothing invents it here.
      final legacy = {
        'id': 'i1',
        'notes': '',
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-01T00:00:00.000Z',
        'sku_id': 'ser',
        'locate_id': null,
        'name': 'Article 1',
        'serial_number': 'SN-1',
        'image_ids': <String>[],
        'trait_ids': <String>[],
        'attribute_values': <String, dynamic>{},
        'icon': null,
      };

      final instance = Instance.fromJson(legacy);

      instance.attributeValues.should.beEmpty();
      instance.toJson().containsKey('serial_number').should.beFalse();
    });
  });
}
