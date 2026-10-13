import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Fails with [AlreadyExistsFailure] when a definition marked
/// [TraitAttributeDefinition.isUnique] would collide with an existing
/// instance value: another instance carrying the same trait already holds the
/// same value for the attribute's [TraitAttributeDefinition.key].
///
/// Uniqueness is scoped to every instance that carries the trait — the
/// attribute must differ across those instances, however the consumer chooses
/// to group them (each instance is identified by its SKU in the message). A
/// non-unique definition passes through untouched.
///
/// Instances that do not carry the trait, or that hold no value for the key,
/// are ignored. An attribute value is what the rule constrains, so an explicit
/// blank string is treated as unset rather than as a value competing for
/// uniqueness.
TaskEither<DomainFailure, Unit> assertUniqueTraitAttributeValue({
  required IInstanceRepository repository,
  required TraitAttributeDefinition definition,
}) {
  if (!definition.isUnique) {
    return TaskEither.of(unit);
  }
  return repository.fetchAll().flatMap((all) {
    // First-holder of each normalized value, keyed by the instance that holds it.
    final seen = <dynamic, Instance>{};
    for (final instance in all) {
      if (!instance.traitIds.contains(definition.traitId)) continue;
      final value = instance.attributeValues[definition.key];
      if (value == null) continue;
      if (value is String && value.trim().isEmpty) continue;
      final first = seen[value];
      if (first != null) {
        return TaskEither.left(
          AlreadyExistsFailure(
            'Trait attribute "${definition.key}" is marked unique, but '
            'instance "${first.name}" (SKU ${first.skuId}) already holds the '
            'same value "$value" as instance "${instance.name}" '
            '(SKU ${instance.skuId}) — the value must differ across '
            'instances that carry this trait.',
          ),
        );
      }
      seen[value] = instance;
    }
    return TaskEither.of(unit);
  });
}
