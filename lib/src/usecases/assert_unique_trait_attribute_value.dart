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
///
/// The compared value is the attribute value itself, matched with Dart `==` —
/// so `5` and `5.0` collide as equal `num`s, while `"5"` and `5` do not.
/// [DataType] declares only scalars (`number`, `string`, `boolean`,
/// `enumType`), so a non-scalar value (a `List` or `Map`, e.g. one that arrived
/// from parsed JSON) is out of contract for a unique attribute: it is refused
/// with [InvalidInputFailure] instead of being compared, rather than silently
/// escaping the check on collection identity.
TaskEither<DomainFailure, Unit> assertUniqueTraitAttributeValue({
  required IInstanceRepository repository,
  required TraitAttributeDefinition definition,
}) {
  if (!definition.isUnique) {
    return TaskEither.of(unit);
  }
  return repository.fetchAll().flatMap((all) {
    // First holder of each scalar value, keyed by the value itself.
    final seen = <dynamic, Instance>{};
    for (final instance in all) {
      if (!instance.traitIds.contains(definition.traitId)) continue;
      final value = instance.attributeValues[definition.key];
      if (value == null) continue;
      if (value is String && value.trim().isEmpty) continue;
      if (value is! num && value is! String && value is! bool) {
        return TaskEither.left(
          InvalidInputFailure(
            'Trait attribute "${definition.key}" is marked unique, but '
            'instance "${instance.name}" (SKU ${instance.skuId}) holds a '
            'non-scalar value ($value) for it — a unique attribute value must '
            'be a scalar (number, string, boolean or enum).',
          ),
        );
      }
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
