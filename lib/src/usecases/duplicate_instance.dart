import 'package:fpdart/fpdart.dart';

import '../domain/domain.dart';
import 'instance_naming.dart';
import 'new_meta.dart';

/// Duplicates an instance: a unique "copy" name, notes and classification carried
/// over, and no locate when the SKU is bound to a slot (a copy is not fitted to
/// anything yet).
///
/// See [UpdateInstance] on [slotBoundTraitNames] — the rule is the caller's
/// convention, never the catalog's vocabulary.
class DuplicateInstance {
  /// Creates a [DuplicateInstance] use case.
  const DuplicateInstance({
    required IInstanceRepository instanceRepository,
    required ISkuRepository skuRepository,
    required ITraitRepository traitRepository,
    this.slotBoundTraitNames = const <String>{},
  }) : _instanceRepository = instanceRepository,
       _skuRepository = skuRepository,
       _traitRepository = traitRepository;

  final IInstanceRepository _instanceRepository;
  final ISkuRepository _skuRepository;
  final ITraitRepository _traitRepository;

  /// Trait names (matched case-insensitively) whose instances carry no locate.
  final Set<String> slotBoundTraitNames;

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
                      current.skuId,
                      types,
                      traits,
                      slotBoundTraitNames,
                    );
                final copyLocate = bound ? null : current.locateId;
                return _instanceRepository.fetchAll().flatMap((all) {
                  final copy = Instance(
                    meta: newMeta(current.meta.notes),
                    skuId: current.skuId,
                    locateId: copyLocate,
                    name: uniqueCopyName(current.name, copyLocate, all),
                    skuModelNumber: current.skuModelNumber,
                    traitIds: current.traitIds,
                    attributeValues: current.attributeValues,
                    icon: current.icon,
                  );
                  return _instanceRepository.create(instance: copy);
                });
              }),
            ),
          );
}
