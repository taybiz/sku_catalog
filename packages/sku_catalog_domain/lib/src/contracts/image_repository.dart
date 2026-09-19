import 'package:fpdart/fpdart.dart';

import '../entities/image_record.dart';
import '../enums/image_owner.dart';
import '../failures/catalog_failures.dart';
import 'unit_of_work.dart';

/// Contract for image record persistence (device/locate/SKU images).
///
/// Replaces the former `IDeviceImageRepository` + `ILocateImageRepository`
/// pair with one owner-tagged contract.
abstract interface class IImageRepository {
  /// Fetch all image records.
  TaskEither<DomainFailure, List<ImageRecord>> fetchAll();

  /// Fetch images for a single owner entity.
  TaskEither<DomainFailure, List<ImageRecord>> fetchByOwner(
    ImageOwner owner,
    String ownerId,
  );

  /// Fetch a single image record by id.
  TaskEither<DomainFailure, ImageRecord> fetchById(String id);

  /// Create a new image record.
  TaskEither<DomainFailure, ImageRecord> create(
    ImageRecord image, {
    IUnitOfWork? uow,
  });

  /// Delete an image record by id.
  TaskEither<DomainFailure, void> delete(String id, {IUnitOfWork? uow});

  /// Remove every record (factory reset support).
  TaskEither<DomainFailure, void> clearAll({IUnitOfWork? uow});
}
