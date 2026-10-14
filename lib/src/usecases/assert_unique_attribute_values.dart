import 'package:fpdart/fpdart.dart';

import '../domain/domain.dart';
import 'attribute_uniqueness.dart';
import 'resolve_schema.dart';

/// Enforces the one rule a unique attribute carries: at most one instance in the
/// catalog may hold a value for it.
///
/// The definitions in scope are the instance's *own* traits plus the traits of the
/// SKU it instantiates, each walked up its parent chain — the same schema
/// `ResolveEffectiveAttributes` reads values through. So a unique attribute
/// declared once on a parent trait holds for every trait below it, a serializable
/// model is serializable through any trait that inherits it, and a trait the
/// instance carries itself counts exactly like one it gets from its model.
///
/// Three boundaries are deliberate:
///
/// - **The instance layer only.** "This value is unique" means one article holds
///   it. A value set on a SKU, a place or a manufacturer describes a model, a
///   place or a maker — not an article — so this rule does not assert it;
/// - **The entity's own values only**, not the ones it would resolve by
///   inheritance from the SKUs above it: what is written is what is claimed;
/// - **Nothing extra to implement.** The check reads instances through
///   `IInstanceRepository.fetchAll()`, so a backend needs only the contracts it
///   already implements. An adapter that wants this cheap can index the unique
///   keys on its own side; the rule stays the same shape.
class AssertUniqueAttributeValues {
  /// Creates an [AssertUniqueAttributeValues] use case.
  const AssertUniqueAttributeValues({
    required IInstanceRepository instanceRepository,
    required ISkuRepository skuRepository,
    required ITraitRepository traitRepository,
    required ITraitAttributeDefinitionRepository attributeRepository,
  }) : _instanceRepository = instanceRepository,
       _skuRepository = skuRepository,
       _traitRepository = traitRepository,
       _attributeRepository = attributeRepository;

  final IInstanceRepository _instanceRepository;
  final ISkuRepository _skuRepository;
  final ITraitRepository _traitRepository;
  final ITraitAttributeDefinitionRepository _attributeRepository;

  /// Executes the use case: fails with [DuplicateAttributeValueFailure] when
  /// [instance] claims a unique attribute value another instance already holds.
  ///
  /// The instance's own id is excluded, so an update that keeps a value (or
  /// rewrites everything but the serial number) is not a clash with itself.
  TaskEither<DomainFailure, Unit> call({required Instance instance}) =>
      uniqueKeysFor(instance: instance).flatMap(
        (keys) => _instanceRepository.fetchAll().flatMap((others) {
          final clash = _clash(keys: keys, instance: instance, others: others);
          return clash == null
              ? TaskEither<DomainFailure, Unit>.of(unit)
              : TaskEither<DomainFailure, Unit>.left(clash);
        }),
      );

  /// The keys in scope for [instance] that are marked unique.
  ///
  /// Exposed because a caller rewriting an instance rather than writing a new
  /// one needs the same answer for a different reason: a copy is a new article,
  /// so it takes the classification but none of the unique values with it (see
  /// `DuplicateInstance`).
  TaskEither<DomainFailure, Set<String>> uniqueKeysFor({
    required Instance instance,
  }) => _traitIdsInScope(instance: instance).flatMap(
    (traitIds) =>
        ResolveSchema(
          traitRepository: _traitRepository,
          attributeRepository: _attributeRepository,
        )(traitIds: traitIds).map(
          (schema) => uniqueAttributeKeys(
            definitions: [for (final entry in schema) entry.def],
          ),
        ),
  );

  /// The instance's own trait ids plus the trait ids of the SKU it instantiates.
  ///
  /// A SKU that is not there contributes nothing rather than failing the write:
  /// an instance pointing at a model nobody stored is that consumer's problem to
  /// surface, and this rule is not the place to start refusing writes over it.
  TaskEither<DomainFailure, List<String>> _traitIdsInScope({
    required Instance instance,
  }) => _skuRepository.fetchAll().map((skus) {
    final traitIds = <String>[...instance.traitIds];
    for (final sku in skus) {
      if (sku.meta.id == instance.skuId) traitIds.addAll(sku.traitIds);
    }
    return traitIds;
  });

  /// The first clash between [instance]'s own values and [others], or null.
  DomainFailure? _clash({
    required Set<String> keys,
    required Instance instance,
    required List<Instance> others,
  }) {
    for (final key in keys) {
      final value = instance.attributeValues[key];
      if (value == null) continue;
      for (final other in others) {
        if (other.meta.id == instance.meta.id) continue;
        if (attributeValuesClash(a: other.attributeValues[key], b: value)) {
          return DuplicateAttributeValueFailure(
            'The value "$value" for the unique attribute "$key" is already '
            'held by instance "${other.name}" (${other.meta.id})',
          );
        }
      }
    }
    return null;
  }
}
