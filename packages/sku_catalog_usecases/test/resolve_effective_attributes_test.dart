import 'package:fpdart/fpdart.dart';
import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog_domain/sku_catalog_domain.dart';
import 'package:sku_catalog_memory/sku_catalog_memory.dart';
import 'package:sku_catalog_usecases/sku_catalog_usecases.dart';
import 'package:test/test.dart';

/// Pins who wins when several layers claim the same attribute.
///
/// The precedence is the whole point of the operation and every rung of it has a
/// way to be silently wrong: an instance that loses to its SKU, an assembly that
/// overrides the part it is built from, a farther ancestor beating a nearer one,
/// or a default that gets invented where none was declared.
void main() {
  late MemoryTraitRepository traits;
  late MemoryTraitAttributeDefinitionRepository attributes;
  late MemoryDeviceTypeRepository skus;
  late MemorySkuComponentRepository components;
  late MemoryDeviceRepository devices;
  late ResolveEffectiveAttributes resolve;

  Meta meta(String id) => Meta(
    id: id,
    notes: '',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  );

  TraitAttributeDefinition definition(
    String traitId,
    String key, {
    String? unit,
    Object? defaultValue,
    DataType type = DataType.number,
  }) => TraitAttributeDefinition(
    meta: meta('$traitId-$key'),
    traitId: traitId,
    key: key,
    displayLabel: key,
    dataType: type,
    unit: unit,
    defaultValue: defaultValue,
  );

  DeviceType sku(
    String id,
    List<String> traitIds, [
    Map<String, dynamic> values = const {},
  ]) => DeviceType(
    meta: meta(id),
    manufacturerId: 'acme',
    modelNumber: id,
    traitIds: traitIds,
    attributeValues: values,
  );

  Device device(
    String id,
    String skuId, [
    Map<String, dynamic> values = const {},
  ]) => Device(
    meta: meta(id),
    deviceTypeId: skuId,
    locateId: null,
    name: id,
    attributeValues: values,
  );

  Future<void> create(TaskEither<DomainFailure, Object> write) =>
      write.run().then((_) {});

  /// The attribute for [key], or a failure naming the keys that did come back.
  ResolvedAttribute attribute(List<ResolvedAttribute> resolved, String key) =>
      resolved.firstWhere(
        (a) => a.def.key == key,
        orElse: () => fail(
          'no "$key" among ${resolved.map((a) => a.def.key).join(', ')}',
        ),
      );

  Future<List<ResolvedAttribute>> effective(String deviceId) async {
    final result = await resolve(deviceId).run();
    result.isRight().should.be(true);
    return result.getOrElse((_) => []);
  }

  Future<List<ResolvedAttribute>> effectiveForSku(String skuId) async {
    final result = await resolve.forSku(skuId).run();
    result.isRight().should.be(true);
    return result.getOrElse((_) => []);
  }

  setUp(() async {
    traits = MemoryTraitRepository();
    attributes = MemoryTraitAttributeDefinitionRepository();
    skus = MemoryDeviceTypeRepository();
    components = MemorySkuComponentRepository();
    devices = MemoryDeviceRepository();

    resolve = ResolveEffectiveAttributes(
      deviceRepository: devices,
      deviceTypeRepository: skus,
      skuComponentRepository: components,
      resolveSchema: ResolveSchema(
        traitRepository: traits,
        attributeRepository: attributes,
      ),
    );

    await create(traits.create(Trait(meta: meta('mech'), name: 'Mech')));
    await create(
      traits.create(
        Trait(meta: meta('flipper'), name: 'Flipper', parentTraitId: 'mech'),
      ),
    );
    await create(
      attributes.create(
        definition('mech', 'travel', unit: 'mm', defaultValue: 10),
      ),
    );
    await create(
      attributes.create(
        definition(
          'mech',
          'label',
          type: DataType.string,
          defaultValue: 'part',
        ),
      ),
    );
    await create(
      attributes.create(definition('flipper', 'coil_ohms', unit: 'ohm')),
    );

    // `flipper-set` claims travel; `flipper-plain` claims nothing. Both are
    // components of `assembly`, which is itself a component of `top-assembly`.
    await create(skus.create(sku('flipper-set', ['flipper'], {'travel': 40})));
    await create(skus.create(sku('flipper-plain', ['flipper'])));
    await create(skus.create(sku('assembly', ['mech'], {'travel': 55})));
    await create(skus.create(sku('top-assembly', ['mech'], {'travel': 99})));

    await create(
      components.create(
        SkuComponent(
          meta: meta('edge-assembly-flipper-set'),
          parentDeviceTypeId: 'assembly',
          childDeviceTypeId: 'flipper-set',
          quantity: 2,
        ),
      ),
    );
    await create(
      components.create(
        SkuComponent(
          meta: meta('edge-assembly-flipper-plain'),
          parentDeviceTypeId: 'assembly',
          childDeviceTypeId: 'flipper-plain',
          quantity: 1,
        ),
      ),
    );
    await create(
      components.create(
        SkuComponent(
          meta: meta('edge-top-assembly'),
          parentDeviceTypeId: 'top-assembly',
          childDeviceTypeId: 'assembly',
          quantity: 1,
        ),
      ),
    );

    await create(
      devices.create(device('d-instance', 'flipper-set', {'travel': 42})),
    );
    await create(devices.create(device('d-plain', 'flipper-set')));
  });

  group('Given ResolveEffectiveAttributes', () {
    group('When the instance sets a value', () {
      test('Then the instance wins and says so', () async {
        final travel = attribute(await effective('d-instance'), 'travel');

        travel.source.should.be('device');
        (travel.value as int).should.be(42);
        travel.unit.should.be('mm');
        travel.inheritedFrom.should.beNull();
      });
    });

    group('When the instance sets nothing', () {
      test('Then the SKU supplies the value', () async {
        final travel = attribute(await effective('d-plain'), 'travel');

        travel.source.should.be('device_type');
        (travel.value as int).should.be(40);
        travel.inheritedFrom.should.beNull();
      });
    });

    group('When nobody sets a value but an assembly above does', () {
      test('Then the nearest assembly wins and is named', () async {
        final travel = attribute(
          await effectiveForSku('flipper-plain'),
          'travel',
        );

        travel.source.should.be('device_type');
        (travel.value as int).should.be(55);
        travel.inheritedFrom.should.be('assembly');
      });
    });

    group('When a definition declares a default', () {
      test('Then an unclaimed attribute reports the default', () async {
        final label = attribute(await effective('d-plain'), 'label');

        label.source.should.be('default');
        (label.value as String).should.be('part');
      });
    });

    group('When nothing supplies a value at any layer', () {
      test(
        'Then the attribute stays unset and reports the schema only',
        () async {
          final ohms = attribute(await effective('d-plain'), 'coil_ohms');

          ohms.source.should.be('trait');
          (ohms.value as Object?).should.beNull();
        },
      );
    });

    group('When a value has no definition behind it', () {
      test('Then it is not returned as an attribute', () async {
        await create(
          devices.create(
            device('d-stray', 'flipper-set', {'no_trait_defines_this': 7}),
          ),
        );

        final resolved = await effective('d-stray');
        resolved
            .any((a) => a.def.key == 'no_trait_defines_this')
            .should
            .be(false);
      });
    });

    group('When the instance carries a trait of its own', () {
      test('Then that trait attributes join the resolved set', () async {
        await create(
          devices.create(
            Device(
              meta: meta('d-classified'),
              deviceTypeId: 'flipper-plain',
              locateId: null,
              name: 'classified',
              traitIds: const ['mech'],
            ),
          ),
        );

        final keys = (await effective(
          'd-classified',
        )).map((a) => a.def.key).toList();
        keys.should.containAll(['travel', 'label', 'coil_ohms']);
      });
    });

    group('When the assembly graph contains a cycle', () {
      test('Then resolution terminates instead of hanging', () async {
        await create(
          components.create(
            SkuComponent(
              meta: meta('edge-back'),
              parentDeviceTypeId: 'flipper-set',
              childDeviceTypeId: 'assembly',
              quantity: 1,
            ),
          ),
        );

        final travel = attribute(
          await effectiveForSku('flipper-set'),
          'travel',
        );
        (travel.value as int).should.be(40);
      });
    });

    group('When the device does not exist', () {
      test('Then the failure comes back on the Left', () async {
        final result = await resolve('nope').run();

        result.isLeft().should.be(true);
        final failure = result.fold((f) => f, (_) => fail('expected Left'));
        (failure is NotFoundFailure).should.be(true);
      });
    });

    group('When a SKU does not exist', () {
      test('Then the definition set is empty rather than an error', () async {
        final resolved = await resolve.forSku('nope').run();

        resolved.isRight().should.be(true);
        resolved.getOrElse((_) => []).should.beEmpty();
      });
    });
  });
}
