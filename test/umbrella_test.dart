import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/in_memory.dart';
import 'package:sku_catalog/sku_catalog.dart';
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
        final sku = Sku(
          meta: meta,
          manufacturerId: 'acme',
          modelNumber: 'BOLT-1',
          traitIds: [trait.meta.id],
          attributeValues: {'thread': 'M6'},
        );
        final component = SkuComponent(
          meta: meta,
          parentSkuId: 'assembly',
          childSkuId: sku.meta.id,
          quantity: 4,
        );
        final instance = Instance(
          meta: meta,
          skuId: sku.meta.id,
          locateId: null,
          name: 'left bolt',
        );

        trait.name.should.be('Fastener');
        attribute.dataType.should.be(DataType.string);
        (sku.attributeValues['thread'] as String).should.be('M6');
        component.quantity.should.be(4);
        instance.isPlaced.should.be(false);
      });

      test('Then the pure helpers behave', () {
        namesClash(a: 'Sensor 1', b: ' sensor 1 ').should.beTrue();
      });
    });

    group('When the contracts and operations are reached through it', () {
      test(
        'Then a shipped backend satisfies a contract and an operation runs',
        () async {
          // The contract-typed local is the check: it only compiles if the
          // umbrella re-exports both the interface and the memory adapter.
          final ISkuRepository repository = InMemorySkuRepository();
          final created =
              await CreateSku(
                    skuRepository: repository,
                    assertUniqueModelNumber: AssertUniqueModelNumber(
                      repository,
                    ),
                  )(
                    sku: Sku(
                      meta: newMeta(),
                      manufacturerId: 'acme',
                      modelNumber: 'NUT-1',
                    ),
                  )
                  .run();

          created.isRight().should.be(true);
          final stored = await repository.fetchAll().run();
          stored.getOrElse((_) => []).length.should.be(1);
        },
      );

      test('Then every operation name resolves', () {
        final ISkuRepository repository = InMemorySkuRepository();
        final operations = <Object>[
          CreateSku(
            skuRepository: repository,
            assertUniqueModelNumber: AssertUniqueModelNumber(repository),
          ),
          CreateTrait(InMemoryTraitRepository()),
          CreateTraitAttributeDefinition(
            InMemoryTraitAttributeDefinitionRepository(),
          ),
          ResolveTraitChain(InMemoryTraitRepository()),
          ResolveSchema(
            traitRepository: InMemoryTraitRepository(),
            attributeRepository: InMemoryTraitAttributeDefinitionRepository(),
          ),
          ResolveEffectiveAttributes(
            instanceRepository: InMemoryInstanceRepository(),
            skuRepository: repository,
            skuComponentRepository: InMemorySkuComponentRepository(),
            resolveSchema: ResolveSchema(
              traitRepository: InMemoryTraitRepository(),
              attributeRepository: InMemoryTraitAttributeDefinitionRepository(),
            ),
          ),
          AddSkuComponent(
            unitOfWork: noOpUnitOfWork,
            repository: InMemorySkuComponentRepository(),
            skuRepository: repository,
          ),
          AddInstanceAssociation(
            unitOfWork: noOpUnitOfWork,
            repository: InMemoryInstanceAssociationRepository(),
            instanceRepository: InMemoryInstanceRepository(),
          ),
          AssertUniqueModelNumber(InMemorySkuRepository()),
          DeleteInstanceAndUnusedSku(
            unitOfWork: noOpUnitOfWork,
            instanceRepository: InMemoryInstanceRepository(),
            skuRepository: repository,
            skuComponentRepository: InMemorySkuComponentRepository(),
            imageRepository: InMemoryImageRepository(),
            instanceAssociationRepository:
                InMemoryInstanceAssociationRepository(),
          ),
          AggregateBillOfMaterials(
            skuRepository: repository,
            skuComponentRepository: InMemorySkuComponentRepository(),
          ),
          WouldCreateAssemblyCycle(InMemorySkuComponentRepository()),
          DeleteSku(
            unitOfWork: noOpUnitOfWork,
            skuRepository: repository,
            instanceRepository: InMemoryInstanceRepository(),
            skuComponentRepository: InMemorySkuComponentRepository(),
          ),
        ];

        operations.length.should.be(13);
      });
    });

    group('When the reference backend is reached through its own door', () {
      test('Then a catalog runs an operation end to end', () async {
        // The in-memory backend has a door of its own, so a consumer who builds
        // their own storage never has to carry it.
        final InMemoryCatalog catalog = InMemoryCatalog();
        final created = await catalog.skus
            .create(
              sku: Sku(
                meta: newMeta(),
                manufacturerId: 'acme',
                modelNumber: 'NUT-1',
              ),
            )
            .run();

        created.isRight().should.be(true);
        (await catalog.skus.fetchAll().run())
            .getOrElse((_) => [])
            .length
            .should
            .be(1);
      });
    });
  });
}
