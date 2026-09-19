import 'package:sku_catalog/sku_catalog.dart';
import 'package:fpdart/fpdart.dart';

/// In-memory [IImageRepository] — canonical test double backed by a [Map].
class MemoryImageRepository implements IImageRepository {
  /// Creates an empty [MemoryImageRepository].
  MemoryImageRepository();

  final Map<String, Map<String, dynamic>> _store = {};

  @override
  TaskEither<DomainFailure, List<ImageRecord>> fetchAll() =>
      TaskEither.of(_store.values.map(ImageRecord.fromJson).toList());

  @override
  TaskEither<DomainFailure, List<ImageRecord>> fetchByOwner(
    ImageOwner owner,
    String ownerId,
  ) => TaskEither.of(
    _store.values
        .map(ImageRecord.fromJson)
        .where((i) => i.owner == owner && i.ownerId == ownerId)
        .toList(),
  );

  @override
  TaskEither<DomainFailure, ImageRecord> fetchById(String id) {
    final record = _store[id];
    if (record == null) {
      return TaskEither<DomainFailure, ImageRecord>.left(
        NotFoundFailure('ImageRecord "$id" not found'),
      );
    }
    return TaskEither.of(ImageRecord.fromJson(record));
  }

  @override
  TaskEither<DomainFailure, ImageRecord> create(
    ImageRecord image, {
    IUnitOfWork? uow,
  }) {
    _store[image.id] = image.toJson();
    return TaskEither.of(image);
  }

  @override
  TaskEither<DomainFailure, void> delete(String id, {IUnitOfWork? uow}) {
    if (_store.remove(id) == null) {
      return TaskEither<DomainFailure, void>.left(
        NotFoundFailure('ImageRecord "$id" not found'),
      );
    }
    return TaskEither.of(null);
  }

  @override
  TaskEither<DomainFailure, void> clearAll({IUnitOfWork? uow}) {
    _store.clear();
    return TaskEither.of(null);
  }
}
