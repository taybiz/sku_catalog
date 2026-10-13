import 'package:fpdart/fpdart.dart';

import '../domain/domain.dart';

/// The `key` of every [ResolvedAttribute] whose definition marks it required
/// but which resolves to no value — empty when all required attributes are
/// satisfied.
///
/// "Satisfied" means the attribute has an effective value by the time it is
/// used. A required attribute backed by a
/// [TraitAttributeDefinition.defaultValue] is satisfied by that default (the
/// resolver fills it), so it is never reported here; only attributes that are
/// still null after resolution come back. The result is in schema order and
/// keyed by [TraitAttributeDefinition.key], so a caller can render or address
/// each missing field.
List<String> missingRequiredAttributeKeys({
  required List<ResolvedAttribute> attributes,
}) => [
  for (final attribute in attributes)
    if (attribute.def.isRequired && attribute.value == null) attribute.def.key,
];

/// Returns `Right(unit)` when every required attribute in [attributes] has a
/// resolved value, otherwise `Left([InvalidInputFailure])` naming the missing
/// keys.
///
/// This is the enforcement leaf over [missingRequiredAttributeKeys]: a write
/// path (or form submit) that has resolved effective attributes feeds them
/// here and rejects the operation when the result is `Left`. The probe is kept
/// separate so a caller that only wants to *render* a "required" prompt without
/// failing can read the missing keys directly.
Either<DomainFailure, Unit> assertRequiredAttributes({
  required List<ResolvedAttribute> attributes,
}) {
  final missing = missingRequiredAttributeKeys(attributes: attributes);
  if (missing.isEmpty) return right(unit);
  return left(
    InvalidInputFailure('Required attributes missing: ${missing.join(', ')}'),
  );
}
