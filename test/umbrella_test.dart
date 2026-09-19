import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'package:sku_catalog_memory/sku_catalog_memory.dart';
import 'package:test/test.dart';

/// The umbrella package exists so one dependency gets you everything. This
/// file reaches the model, the contracts and the operations through that one
/// import: if either half stops being re-exported it stops compiling, and a
/// name that resolves but does not work is caught here rather than by a user.
void main() {
  group('Given the umbrella package', () {
    group('When the model is reached through it alone', () {
      test('Then a new entity carries its identity metadata', () {
        final meta = newMeta();

        meta.id.isEmpty.should.be(false);
        meta.createdAt.isEmpty.should.be(false);
        meta.createdAt.should.be(meta.updatedAt);
      });

      test('Then entities, traits and value objects are constructed', () {
        final meta = newMeta();
        final trait = Trait(meta: meta, name: 'Fastener');
        final attribute = TraitAttributeDefinition(
          meta: meta,
          traitId: trait.meta.id,
          key: 'thread',
          displayLabel: 'Thread',
          dataType: DataType.string,
        );
        final sku = DeviceType(
          meta: meta,
          manufacturerId: 'acme',
          modelNumber: 'BOLT-1',
          traitIds: [trait.meta.id],
          attributeValues: {'thread': 'M6'},
        );
        final component = SkuComponent(
          meta: meta,
          parentDeviceTypeId: 'assembly',
          childDeviceTypeId: sku.meta.id,
          quantity: 4,
        );
        final device = Device(
          meta: meta,
          deviceTypeId: sku.meta.id,
          locateId: null,
          name: 'left bolt',
        );

        trait.name.should.be('Fastener');
        attribute.dataType.should.be(DataType.string);
        (sku.attributeValues['thread'] as String).should.be('M6');
        component.quantity.should.be(4);
        device.isPlaced.should.be(false);
      });

      test('Then the pure helpers behave', () {
        collapseSeparators('bolt__m6--x').should.be('bolt_m6-x');
      });
    });

    group('When the contracts and operations are reached through it', () {
      test(
        'Then a shipped backend satisfies a contract and an operation runs',
        () async {
          // The contract-typed local is the check: it only compiles if the
          // umbrella re-exports both the interface and the memory adapter.
          final IDeviceTypeRepository repository = MemoryDeviceTypeRepository();
          final created = await CreateDeviceType(repository)(
            DeviceType(
              meta: newMeta(),
              manufacturerId: 'acme',
              modelNumber: 'NUT-1',
            ),
          ).run();

          created.isRight().should.be(true);
          final stored = await repository.fetchAll().run();
          stored.getOrElse((_) => []).length.should.be(1);
        },
      );

      test('Then every operation name resolves', () {
        final IDeviceTypeRepository repository = MemoryDeviceTypeRepository();
        final operations = <Object>[
          CreateDeviceType(repository),
          CreateTrait(MemoryTraitRepository()),
          CreateTraitAttributeDefinition(
            MemoryTraitAttributeDefinitionRepository(),
          ),
          ResolveTraitChain(MemoryTraitRepository()),
          ResolveSchema(
            traitRepository: MemoryTraitRepository(),
            attributeRepository: MemoryTraitAttributeDefinitionRepository(),
          ),
          ResolveEffectiveAttributes(
            deviceRepository: MemoryDeviceRepository(),
            deviceTypeRepository: repository,
            skuComponentRepository: MemorySkuComponentRepository(),
            resolveSchema: ResolveSchema(
              traitRepository: MemoryTraitRepository(),
              attributeRepository: MemoryTraitAttributeDefinitionRepository(),
            ),
          ),
          AddSkuComponent(
            repository: MemorySkuComponentRepository(),
            deviceTypeRepository: repository,
          ),
          WouldCreateAssemblyCycle(MemorySkuComponentRepository()),
          DeleteDeviceType(
            deviceTypeRepository: repository,
            deviceRepository: MemoryDeviceRepository(),
            skuComponentRepository: MemorySkuComponentRepository(),
          ),
        ];

        operations.length.should.be(9);
      });
    });
  });
}
