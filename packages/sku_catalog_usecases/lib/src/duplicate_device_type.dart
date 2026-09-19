import 'package:sku_catalog_domain/sku_catalog_domain.dart';
import 'package:fpdart/fpdart.dart';

import 'new_meta.dart';

/// Duplicates a device type: fresh meta and a "(copy)" model number.
class DuplicateDeviceType {
  /// Creates a [DuplicateDeviceType] use case.
  const DuplicateDeviceType(this._deviceTypeRepository);

  final IDeviceTypeRepository _deviceTypeRepository;

  /// Executes the use case.
  TaskEither<DomainFailure, DeviceType> call(String id) =>
      _deviceTypeRepository.fetchById(id).flatMap((current) {
        final copy = current.copyWith(
          meta: newMeta(),
          modelNumber: '${current.modelNumber} (copy)',
        );
        return _deviceTypeRepository.create(copy);
      });
}
