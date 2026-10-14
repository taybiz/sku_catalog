import 'package:fpdart/fpdart.dart';

import '../domain/domain.dart';
import 'resolve_instance_schema.dart';

/// Enforces the one rule a unique attribute carries: at most one instance in the
/// catalog may hold a value for it.
///
/// A unique attribute means "one article holds this", and the check is measured
/// against the schema [ResolveInstanceSchema] returns for the article — so a
/// unique attribute declared on a parent trait holds for every trait below it, a
/// serializable model is serializable through any trait that inherits it, and a
/// trait the instance carries itself counts exactly like one it gets from its
/// model.
///
/// Three boundaries are deliberate:
///
/// - **The instance layer only.** A value set on a SKU, a place or a manufacturer
///   describes a model, a place or a maker — not an article — so this rule does
///   not assert it;
/// - **The entity's own values only**, not the ones it would resolve by
///   inheritance from the SKUs above it: what is written is what is claimed;
/// - **Nothing extra to implement.** The check reads instances through
///   `IInstanceRepository.fetchAll()`, so a backend needs only the contracts it
///   already implements. An adapter that wants this cheap can index the unique
///   keys on its own side; the rule stays a use case, not a storage feature.
class AssertUniqueAttributeValues {
  /// Creates an [AssertUniqueAttributeValues] use case.
  const AssertUniqueAttributeValues({
    required IInstanceRepository instanceRepository,
    required ResolveInstanceSchema resolveInstanceSchema,
  }) : _instanceRepository = instanceRepository,
       _resolveInstanceSchema = resolveInstanceSchema;

  final IInstanceRepository _instanceRepository;
  final ResolveInstanceSchema _resolveInstanceSchema;

  /// Executes the use case: fails with [DuplicateAttributeValueFailure] when
  /// [instance] claims a unique attribute value another instance already holds.
  ///
  /// The instance's own id is excluded, so an update that keeps a value — or
  /// rewrites everything but the serial number — is not a clash with itself.
  TaskEither<DomainFailure, Unit> call({required Instance instance}) =>
      _resolveInstanceSchema(instance: instance).flatMap(
        (schema) => _instanceRepository.fetchAll().flatMap((others) {
          final clash = _clash(
            schema: schema,
            instance: instance,
            others: others,
          );
          return clash == null
              ? TaskEither<DomainFailure, Unit>.of(unit)
              : TaskEither<DomainFailure, Unit>.left(clash);
        }),
      );

  /// The first clash between the unique values [instance] claims and [others].
  DomainFailure? _clash({
    required List<ResolvedAttribute> schema,
    required Instance instance,
    required List<Instance> others,
  }) {
    for (final entry in schema) {
      final definition = entry.def;
      if (!definition.isUnique) continue;
      final value = instance.attributeValues[definition.key];
      if (value == null) continue;
      for (final other in others) {
        if (other.meta.id == instance.meta.id) continue;
        if (definition.valuesMatch(
          a: other.attributeValues[definition.key],
          b: value,
        )) {
          return DuplicateAttributeValueFailure(
            'The value "$value" for the unique attribute "${definition.key}" is '
            'already held by instance "${other.name}" (${other.meta.id})',
          );
        }
      }
    }
    return null;
  }
}
