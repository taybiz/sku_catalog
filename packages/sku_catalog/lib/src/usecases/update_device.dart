import 'package:fpdart/fpdart.dart';

import '../domain/domain.dart';
import 'assert_unique_device_name.dart';
import 'device_naming.dart';

/// Updates an existing device: names stay unique within their locate, and a
/// SKU bound to a slot never carries a locate of its own.
///
/// [slotBoundTraitNames] is the caller's convention, not the catalog's — a
/// product that slots devices into a host (a rack, a chassis, a board) passes the
/// trait names that mean "this thing lives inside another thing", and the
/// locate is forced null for those. The default (empty) applies no rule, so the
/// catalog model carries no product vocabulary.
class UpdateDevice {
  /// Creates an [UpdateDevice] use case.
  const UpdateDevice({
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
  TaskEither<DomainFailure, Device> call(Device device) => _deviceRepository
      .fetchById(device.meta.id)
      .flatMap(
        (original) => _traitRepository.fetchAll().flatMap(
          (traits) => _deviceTypeRepository.fetchAll().flatMap((types) {
            final bound =
                slotBoundTraitNames.isNotEmpty &&
                isSlotBound(
                  device.deviceTypeId,
                  types,
                  traits,
                  slotBoundTraitNames,
                );
            final effective = bound ? device.copyWith(locateId: null) : device;
            return assertUniqueDeviceName(
              _deviceRepository,
              name: effective.name,
              locateId: effective.locateId,
              excludeId: effective.meta.id,
            ).flatMap((_) => _deviceRepository.update(effective));
          }),
        ),
      );
}
