import 'package:fpdart/fpdart.dart';

import '../domain/domain.dart';
import 'assert_unique_attribute_values.dart';
import 'attribute_uniqueness.dart';
import 'id_generator.dart';
import 'instance_naming.dart';
import 'new_meta.dart';

/// Duplicates an instance: a unique "copy" name, notes and classification carried
/// over, no locate when the SKU is bound to a slot (a copy is not fitted to
/// anything yet), and no value for any attribute marked unique.
///
/// The last rule is the one a copy would otherwise break: a serial number
/// identifies the article it was read from, so the copy inherits the
/// classification and every value that is *not* unique, and starts with the
/// unique ones unset — exactly like the locate, which a copy does not inherit.
/// The unique keys come from [AssertUniqueAttributeValues], the same rule the
/// create and update paths enforce, so a copy never has to be refused: it simply
/// carries nothing that identifies the original.
///
/// See [UpdateInstance] on [slotBoundTraitNames] — the rule is the caller's
/// convention, never the catalog's vocabulary.
class DuplicateInstance {
  /// Creates a [DuplicateInstance] use case.
  const DuplicateInstance({
    required IInstanceRepository instanceRepository,
    required ISkuRepository skuRepository,
    required ITraitRepository traitRepository,
    required AssertUniqueAttributeValues assertUniqueAttributeValues,
    this.slotBoundTraitNames = const <String>{},
    this.idGenerator,
  }) : _instanceRepository = instanceRepository,
       _skuRepository = skuRepository,
       _traitRepository = traitRepository,
       _assertUniqueAttributeValues = assertUniqueAttributeValues;

  final IInstanceRepository _instanceRepository;
  final ISkuRepository _skuRepository;
  final ITraitRepository _traitRepository;
  final AssertUniqueAttributeValues _assertUniqueAttributeValues;

  /// Trait names (matched case-insensitively) whose instances carry no locate.
  final Set<String> slotBoundTraitNames;

  /// Mints the copy's id; defaults to a random UUID v4 when null.
  final IdGenerator? idGenerator;

  /// Executes the use case.
  TaskEither<DomainFailure, Instance> call({required String id}) =>
      _instanceRepository
          .fetchById(id: id)
          .flatMap(
            (current) => _traitRepository.fetchAll().flatMap(
              (traits) => _skuRepository.fetchAll().flatMap((types) {
                final bound =
                    slotBoundTraitNames.isNotEmpty &&
                    isSlotBound(
                      typeId: current.skuId,
                      skus: types,
                      traits: traits,
                      traitNames: slotBoundTraitNames,
                    );
                final copyLocate = bound ? null : current.locateId;
                return _assertUniqueAttributeValues
                    .uniqueKeysFor(instance: current)
                    .flatMap(
                      (uniqueKeys) =>
                          _instanceRepository.fetchAll().flatMap((all) {
                            final copy = Instance(
                              meta: newMeta(
                                notes: current.meta.notes,
                                idGenerator: idGenerator,
                              ),
                              skuId: current.skuId,
                              locateId: copyLocate,
                              name: uniqueCopyName(
                                baseName: current.name,
                                locateId: copyLocate,
                                all: all,
                              ),
                              skuModelNumber: current.skuModelNumber,
                              traitIds: current.traitIds,
                              attributeValues: withoutKeys(
                                values: current.attributeValues,
                                keys: uniqueKeys,
                              ),
                              icon: current.icon,
                            );
                            return _instanceRepository.create(instance: copy);
                          }),
                    );
              }),
            ),
          );
}
