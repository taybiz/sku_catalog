import '../../domain/domain.dart';
import '../../usecases/usecases.dart';
import 'in_memory_image_repository.dart';
import 'in_memory_instance_association_repository.dart';
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
/// This is the reference an implementer reads. Swap the eleven stores for your own
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
///   and scans, which is correct and slow — and because the contracts *are* the
///   API, the only way to make it cheaper is a narrower contract
///   (see [AssertUniqueAttributeValues]).
///
/// Deliberately *not* wrapped: the one-liners. `FetchAllSkus(skus)` or
/// `CreateTrait(traits)` is already a single line with the store in hand, and
/// wrapping every operation would just be a second copy of the operations ring.
///
/// **What is here:** every operation that takes a `UnitOfWork` — one that steps
/// more than once, or decides a rule by reading and then writes. A transaction is a
/// composition decision, so a transaction-taking operation is *always* something the
/// composition root wires, and that is all fourteen of them. Add one to the package
/// without adding it here and this file stops being the worked example.
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

  /// Association edges between articles — a labeled relationship between two
  /// instances of SKUs.
  final InMemoryInstanceAssociationRepository instanceAssociations =
      InMemoryInstanceAssociationRepository();

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
  late final UnitOfWork unitOfWork = inMemoryUnitOfWork([
    traits,
    attributes,
    skus,
    assemblies,
    associations,
    instanceAssociations,
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

  /// The unique-value rule. It reads every holder — articles, places, makers —
  /// so a value marked unique is held once in the catalog, whatever kind holds
  /// it.
  late final AssertUniqueAttributeValues uniqueValues =
      AssertUniqueAttributeValues(
        instanceRepository: instances,
        locateRepository: locates,
        manufacturerRepository: manufacturers,
        resolveInstanceSchema: instanceSchema,
        resolveSchema: schema,
      );

  /// The per-place unique name rule.
  late final AssertUniqueInstanceName uniqueNames = AssertUniqueInstanceName(
    instances,
  );

  /// The per-manufacturer model-number rule.
  late final AssertUniqueModelNumber modelNumbers = AssertUniqueModelNumber(
    skus,
  );

  /// Creates a SKU, guarded by the model-number rule.
  late final CreateSku createSku = CreateSku(
    skuRepository: skus,
    assertUniqueModelNumber: modelNumbers,
  );

  /// Updates a SKU, guarded by the model-number rule.
  late final UpdateSku updateSku = UpdateSku(
    skuRepository: skus,
    assertUniqueModelNumber: modelNumbers,
  );

  /// Copies a SKU: a new model, with the next free model number for its maker.
  late final DuplicateSku duplicateSku = DuplicateSku(skus);

  /// Creates an instance, guarded by the model's rules.
  late final CreateInstance createInstance = CreateInstance(
    instanceRepository: instances,
    assertUniqueInstanceName: uniqueNames,
    assertUniqueAttributeValues: uniqueValues,
    unitOfWork: unitOfWork,
  );

  /// Updates an instance, guarded by the model's rules.
  late final UpdateInstance updateInstance = UpdateInstance(
    instanceRepository: instances,
    assertUniqueInstanceName: uniqueNames,
    assertUniqueAttributeValues: uniqueValues,
    unitOfWork: unitOfWork,
  );

  /// Copies an instance: a new article, with every unique value dropped.
  late final DuplicateInstance duplicateInstance = DuplicateInstance(
    instanceRepository: instances,
    resolveInstanceSchema: instanceSchema,
  );

  /// Creates a place, guarded by the unique-value rule — a place holds values
  /// like an article does.
  late final CreateLocate createLocate = CreateLocate(
    locateRepository: locates,
    assertUniqueAttributeValues: uniqueValues,
    unitOfWork: unitOfWork,
  );

  /// Updates a place, guarded by the tree rule and the unique-value rule.
  late final UpdateLocate updateLocate = UpdateLocate(
    locateRepository: locates,
    assertUniqueAttributeValues: uniqueValues,
    unitOfWork: unitOfWork,
  );

  /// Creates a maker, guarded by the unique-value rule.
  late final CreateManufacturer createManufacturer = CreateManufacturer(
    manufacturerRepository: manufacturers,
    assertUniqueAttributeValues: uniqueValues,
    unitOfWork: unitOfWork,
  );

  /// Updates a maker, guarded by the unique-value rule.
  late final UpdateManufacturer updateManufacturer = UpdateManufacturer(
    manufacturerRepository: manufacturers,
    assertUniqueAttributeValues: uniqueValues,
    unitOfWork: unitOfWork,
  );

  /// Deletes an instance, its images and its association edges in one
  /// transaction.
  late final DeleteInstance deleteInstance = DeleteInstance(
    instanceRepository: instances,
    imageRepository: images,
    instanceAssociationRepository: instanceAssociations,
    unitOfWork: unitOfWork,
  );

  /// Deletes an article and, when it was its model's last one, the model too —
  /// for a model nobody catalogues, which only its articles instantiate. It owns
  /// one transaction over both halves.
  late final DeleteInstanceAndUnusedSku deleteInstanceAndUnusedSku =
      DeleteInstanceAndUnusedSku(
        instanceRepository: instances,
        skuRepository: skus,
        skuComponentRepository: assemblies,
        imageRepository: images,
        instanceAssociationRepository: instanceAssociations,
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

  /// Deletes a trait and its attribute definitions in one transaction, refusing
  /// while it is somebody's parent or is attached to a SKU, a maker or a place.
  late final DeleteTrait deleteTrait = DeleteTrait(
    traitRepository: traits,
    skuRepository: skus,
    manufacturerRepository: manufacturers,
    locateRepository: locates,
    traitAttributeRepository: attributes,
    unitOfWork: unitOfWork,
  );

  /// Adds an assembly edge, refusing a cycle or a missing SKU.
  late final AddSkuComponent addSkuComponent = AddSkuComponent(
    repository: assemblies,
    skuRepository: skus,
    unitOfWork: unitOfWork,
  );

  /// Adds a relationship edge between two articles, refusing a self-edge, a
  /// missing article or a blank kind.
  late final AddInstanceAssociation addInstanceAssociation =
      AddInstanceAssociation(
        repository: instanceAssociations,
        instanceRepository: instances,
        unitOfWork: unitOfWork,
      );

  /// Adds a relationship edge between two models, refusing a missing SKU or a blank
  /// kind. A relationship graph may cycle, so there is no cycle guard here.
  late final AddSkuAssociation addSkuAssociation = AddSkuAssociation(
    repository: associations,
    skuRepository: skus,
    unitOfWork: unitOfWork,
  );

  /// Updates an assembly edge's quantity. The component contract has no update
  /// path, so the row is deleted and re-created — two writes, one transaction.
  late final UpdateSkuComponent updateSkuComponent = UpdateSkuComponent(
    assemblies,
    unitOfWork: unitOfWork,
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
