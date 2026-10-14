import 'package:fpdart/fpdart.dart';

import '../domain/domain.dart';
import 'assert_unique_attribute_values.dart';
import 'assert_unique_instance_name.dart';

/// Updates an existing instance: names stay unique within their locate, unique
/// attribute values stay unique across the catalog, and a SKU bound to a slot
/// never carries a locate of its own.
///
/// [slotBoundTraitNames] is the caller's convention, not the catalog's — a
/// product that slots instances into a host (a rack, a chassis, a board) passes the
/// trait names that mean "this thing lives inside another thing", and the
/// locate is forced null for those. The default (empty) applies no rule, so the
/// catalog model carries no product vocabulary.
class UpdateInstance {
  /// Creates an [UpdateInstance] use case.
  const UpdateInstance({
    required IInstanceRepository instanceRepository,
    required ISkuRepository skuRepository,
    required ITraitRepository traitRepository,
    required AssertUniqueInstanceName assertUniqueInstanceName,
    required AssertUniqueAttributeValues assertUniqueAttributeValues,
    this.slotBoundTraitNames = const <String>{},
  }) : _instanceRepository = instanceRepository,
       _skuRepository = skuRepository,
       _traitRepository = traitRepository,
       _assertUniqueInstanceName = assertUniqueInstanceName,
       _assertUniqueAttributeValues = assertUniqueAttributeValues;

  final IInstanceRepository _instanceRepository;
  final ISkuRepository _skuRepository;
  final ITraitRepository _traitRepository;
  final AssertUniqueInstanceName _assertUniqueInstanceName;
  final AssertUniqueAttributeValues _assertUniqueAttributeValues;

  /// Trait names (matched case-insensitively) whose instances carry no locate.
  final Set<String> slotBoundTraitNames;

  /// Executes the use case.
  TaskEither<DomainFailure, Instance> call({required Instance instance}) =>
      _instanceRepository
          .fetchById(id: instance.meta.id)
          .flatMap(
            (original) => _traitRepository.fetchAll().flatMap(
              (traits) => _skuRepository.fetchAll().flatMap((types) {
                final bound =
                    slotBoundTraitNames.isNotEmpty &&
                    isSlotBound(
                      typeId: instance.skuId,
                      skus: types,
                      traits: traits,
                      traitNames: slotBoundTraitNames,
                    );
                final effective = bound
                    ? instance.copyWith(locateId: null)
                    : instance;
                return _assertUniqueInstanceName(
                      name: effective.name,
                      locateId: effective.locateId,
                      excludeId: effective.meta.id,
                    )
                    .flatMap(
                      (_) => _assertUniqueAttributeValues(instance: effective),
                    )
                    .flatMap(
                      (_) => _instanceRepository.update(instance: effective),
                    );
              }),
            ),
          );
}
