import 'package:equatable/equatable.dart';

import '../entities/meta.dart';
import '../entities/trait.dart';
import '../entities/trait_attribute_definition.dart';
import '../enums/data_type.dart';
import '../enums/trait_scope.dart';

/// The `serializable` classification and the unique `serial_number` attribute it
/// contributes — a slot, a printed label, `SN-0001`.
///
/// A serial number was a field on `Instance` once. It is an attribute now,
/// because the two halves are two different facts: **the model** is serializable
/// (a trait on the SKU, which is why the trait is `sku`-scoped) and **the
/// article** carries one particular number (a value on the instance). Only the
/// second half is unique, so `serial_number` is defined `isUnique` and every
/// write that could claim it — an article, a place, a maker — is checked against
/// it: see `AssertUniqueAttributeValues`.
///
/// This is the one trait the package names, and it names it because the pair is
/// an invariant rather than a convention: a consumer that stores this definition
/// gets the rule with it. Every other trait stays the consumer's data —
/// [SerializableTrait.define] takes the two [Meta] records so ids stay yours,
/// and the key and label are parameters if you spell them differently. Persist
/// the pair the way you persist any other trait and attribute definition; the
/// catalog ships it as data, not as a seeded row.
class SerializableTrait extends Equatable {
  /// The trait's name.
  static const String traitName = 'Serializable';

  /// The key the serial number value is held under.
  static const String serialNumberKey = 'serial_number';

  /// The classification, to store alongside your own traits.
  final Trait trait;

  /// The unique string attribute the trait contributes.
  final TraitAttributeDefinition serialNumber;

  /// Creates a [SerializableTrait].
  const SerializableTrait({required this.trait, required this.serialNumber});

  /// Builds the canonical pair from the ids you mint for them.
  ///
  /// [key] and [displayLabel] are parameters because the words are the
  /// consumer's; the scope and the uniqueness flag are not.
  factory SerializableTrait.define({
    required Meta traitMeta,
    required Meta attributeMeta,
    String key = serialNumberKey,
    String displayLabel = 'Serial Number',
  }) => SerializableTrait(
    trait: Trait(
      meta: traitMeta,
      name: traitName,
      scope: const [TraitScope.sku],
    ),
    serialNumber: TraitAttributeDefinition(
      meta: attributeMeta,
      traitId: traitMeta.id,
      key: key,
      displayLabel: displayLabel,
      dataType: DataType.string,
      isUnique: true,
    ),
  );

  @override
  List<Object?> get props => [trait, serialNumber];
}
