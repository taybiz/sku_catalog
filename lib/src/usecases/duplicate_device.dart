import 'package:fpdart/fpdart.dart';

import '../domain/domain.dart';
import 'device_naming.dart';
import 'new_meta.dart';

/// Duplicates a device: a unique "copy" name, notes and classification carried
/// over, and no locate when the SKU is bound to a slot (a copy is not fitted to
/// anything yet).
///
/// See [UpdateDevice] on [slotBoundTraitNames] — the rule is the caller's
/// convention, never the catalog's vocabulary.
class DuplicateDevice {
  /// Creates a [DuplicateDevice] use case.
  const DuplicateDevice({
    required IDeviceRepository deviceRepository,
    required IDeviceTypeRepository deviceTypeRepository,
    required ITraitRepository traitRepository,
    this.slotBoundTraitNames = const <String>{},
  }) : _deviceRepository = deviceRepository,
       _deviceTypeRepository = deviceTypeRepository,
       _traitRepository = traitRepository;

  final IDeviceRepository _deviceRepository;
  final IDeviceTypeRepository _deviceTypeRepository;
  final ITraitRepository _traitRepository;

  /// Trait names (matched case-insensitively) whose devices carry no locate.
  final Set<String> slotBoundTraitNames;

  /// Executes the use case.
  TaskEither<DomainFailure, Device> call(String id) => _deviceRepository
      .fetchById(id)
      .flatMap(
        (current) => _traitRepository.fetchAll().flatMap(
          (traits) => _deviceTypeRepository.fetchAll().flatMap((types) {
            final bound =
                slotBoundTraitNames.isNotEmpty &&
                isSlotBound(
                  current.deviceTypeId,
                  types,
                  traits,
                  slotBoundTraitNames,
                );
            final copyLocate = bound ? null : current.locateId;
            return _deviceRepository.fetchAll().flatMap((all) {
              final copy = Device(
                meta: newMeta(current.meta.notes),
                deviceTypeId: current.deviceTypeId,
                locateId: copyLocate,
                name: uniqueCopyName(current.name, copyLocate, all),
                skuModelNumber: current.skuModelNumber,
                traitIds: current.traitIds,
                attributeValues: current.attributeValues,
                icon: current.icon,
              );
              return _deviceRepository.create(copy);
            });
          }),
        ),
      );
}
