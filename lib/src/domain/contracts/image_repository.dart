import 'package:fpdart/fpdart.dart';

import '../entities/image_record.dart';
import '../enums/image_owner.dart';
import '../failures/catalog_failures.dart';

/// Contract for image record persistence (instance/locate/SKU images).
///
/// Replaces the former `IInstanceImageRepository` + `ILocateImageRepository`
/// pair with one owner-tagged contract.
abstract interface class IImageRepository {
  /// Fetch all image records.
  TaskEither<DomainFailure, List<ImageRecord>> fetchAll();

  /// Fetch images for a single owner entity.
  TaskEither<DomainFailure, List<ImageRecord>> fetchByOwner({
    required ImageOwner owner,
    required String ownerId,
  });

  /// Fetch a single image record by id.
  TaskEither<DomainFailure, ImageRecord> fetchById({required String id});

  /// Create a new image record.
  TaskEither<DomainFailure, ImageRecord> create({required ImageRecord image});

  /// Delete an image record by id.
  TaskEither<DomainFailure, void> delete({required String id});
}
