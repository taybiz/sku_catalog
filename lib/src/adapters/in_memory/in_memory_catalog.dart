import '../../domain/domain.dart';
import '../../usecases/usecases.dart';
import 'in_memory_image_repository.dart';
import 'in_memory_instance_repository.dart';
import 'in_memory_locate_repository.dart';
import 'in_memory_manufacturer_repository.dart';
import 'in_memory_meta_repository.dart';
import 'in_memory_sku_association_repository.dart';
import 'in_memory_sku_component_repository.dart';
import 'in_memory_sku_repository.dart';
import 'in_memory_trait_attribute_definition_repository.dart';
import 'in_memory_trait_repository.dart';
import 'in_memory_unit_of_work.dart';

/// An in-memory catalog: every store, one transaction over all of them, and the
/// model's rules and operations wired the way a composition root would.
///
/// This is the reference an implementer reads. Swap the ten stores for your own
/// implementations of the contracts and the operations below are unchanged — they
/// are typed against the interfaces, not against these classes.
///
/// Three things worth copying:
///
/// - **the stores are contracts**: [skus] *is* an [ISkuRepository], so it goes
///   anywhere a contract is expected;
/// - **the transaction covers every table** ([unitOfWork]), so a multi-write
///   operation cannot half-commit because someone forgot to register a store;
/// - **the unique-value rule needs nothing from a backend.** It reads `fetchAll()`
///   and scans, which is correct and slow; a real adapter that wants it cheap
///   indexes the unique keys on its own side (see [AssertUniqueAttributeValues]).
///
/// Deliberately *not* wrapped: the single-store use cases. `FetchAllSkus(skus)` or
/// `CreateTrait(traits)` is already one line with the store in hand, and wrapping
/// all of them would be a second copy of the operations ring.
class InMemoryCatalog {
  /// Creates an empty in-memory catalog.
  InMemoryCatalog();

  /// Traits.
  final InMemoryTraitRepository traits = InMemoryTraitRepository();

  /// Trait attribute definitions.
  final InMemoryTraitAttributeDefinitionRepository attributes =
      InMemoryTraitAttributeDefinitionRepository();

  /// SKUs.
  final InMemorySkuRepository skus = InMemorySkuRepository();

  /// Assembly edges — a SKU containing SKUs.
  final InMemorySkuComponentRepository assemblies =
      InMemorySkuComponentRepository();

  /// Association edges — a labeled relationship between SKUs.
  final InMemorySkuAssociationRepository associations =
      InMemorySkuAssociationRepository();

  /// Instances — the articles of a SKU.
  final InMemoryInstanceRepository instances = InMemoryInstanceRepository();

  /// Places, as a tree.
  final InMemoryLocateRepository locates = InMemoryLocateRepository();

  /// Manufacturers.
  final InMemoryManufacturerRepository manufacturers =
      InMemoryManufacturerRepository();

  /// Image records.
  final InMemoryImageRepository images = InMemoryImageRepository();

  /// The catalog's own meta record.
  final InMemoryMetaRepository meta = InMemoryMetaRepository();

  /// A transaction over every table above, for the use cases that write twice.
  late final InMemoryUnitOfWork unitOfWork = InMemoryUnitOfWork([
    traits,
    attributes,
    skus,
    assemblies,
    associations,
    instances,
    locates,
    manufacturers,
    images,
    meta,
  ]);

  /// The trait/attribute schema resolver.
  late final ResolveSchema schema = ResolveSchema(
    traitRepository: traits,
    attributeRepository: attributes,
  );

  /// The schema in scope for one article: its own traits plus its model's.
  late final ResolveInstanceSchema instanceSchema = ResolveInstanceSchema(
    skuRepository: skus,
    resolveSchema: schema,
  );

  /// The unique-value rule.
  late final AssertUniqueAttributeValues uniqueValues =
      AssertUniqueAttributeValues(
        instanceRepository: instances,
        resolveInstanceSchema: instanceSchema,
      );

  /// The per-place unique name rule.
  late final AssertUniqueInstanceName uniqueNames = AssertUniqueInstanceName(
    instances,
  );

  /// Creates an instance, guarded by the model's rules.
  late final CreateInstance createInstance = CreateInstance(
    instanceRepository: instances,
    assertUniqueInstanceName: uniqueNames,
    assertUniqueAttributeValues: uniqueValues,
  );

  /// Updates an instance, guarded by the model's rules.
  late final UpdateInstance updateInstance = UpdateInstance(
    instanceRepository: instances,
    assertUniqueInstanceName: uniqueNames,
    assertUniqueAttributeValues: uniqueValues,
  );

  /// Copies an instance: a new article, with every unique value dropped.
  late final DuplicateInstance duplicateInstance = DuplicateInstance(
    instanceRepository: instances,
    resolveInstanceSchema: instanceSchema,
  );

  /// Deletes an instance and its images in one transaction.
  late final DeleteInstance deleteInstance = DeleteInstance(
    instanceRepository: instances,
    imageRepository: images,
    unitOfWork: unitOfWork,
  );

  /// Deletes a SKU and its assembly edges in one transaction, refusing while
  /// instances still use it.
  late final DeleteSku deleteSku = DeleteSku(
    skuRepository: skus,
    instanceRepository: instances,
    skuComponentRepository: assemblies,
    unitOfWork: unitOfWork,
  );

  /// Adds an assembly edge, refusing a cycle or a missing SKU.
  late final AddSkuComponent addSkuComponent = AddSkuComponent(
    repository: assemblies,
    skuRepository: skus,
  );

  /// Folds an assembly tree into the parts a build needs.
  late final AggregateBillOfMaterials billOfMaterials =
      AggregateBillOfMaterials(
        skuRepository: skus,
        skuComponentRepository: assemblies,
      );

  /// Resolves the values in scope for one article.
  late final ResolveEffectiveAttributes effectiveAttributes =
      ResolveEffectiveAttributes(
        instanceRepository: instances,
        skuRepository: skus,
        skuComponentRepository: assemblies,
        resolveSchema: schema,
      );

  /// Resolves the values in scope for one model, inside its assemblies.
  late final ResolveSkuAttributes skuAttributes = ResolveSkuAttributes(
    skuRepository: skus,
    skuComponentRepository: assemblies,
    resolveSchema: schema,
  );
}
