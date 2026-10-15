import 'package:fpdart/fpdart.dart';

import '../../domain/domain.dart';
import 'in_memory_table.dart';

/// An in-memory [IImageRepository] — one row per image, tagged with its owner.
///
/// Records are kept as their JSON rows, so this reference persists exactly the
/// wire form the model round-trips. Nothing here stores the bytes: an
/// [ImageRecord] names where the file is (`storedPath`), and that is all the
/// catalog knows about pictures.
class InMemoryImageRepository
    with InMemoryRowSourceBy<ImageRecord>
    implements IImageRepository {
  /// Creates an empty [InMemoryImageRepository].
  InMemoryImageRepository()
    : table = InMemoryTable<ImageRecord>(
        decode: ImageRecord.fromJson,
        encode: (image) => image.toJson(),
        idOf: (image) => image.id,
      );

  /// The rows behind this repository — what a transaction snapshots.
  @override
  final InMemoryTable<ImageRecord> table;

  @override
  TaskEither<DomainFailure, List<ImageRecord>> fetchAll() =>
      TaskEither.of(table.all());

  @override
  TaskEither<DomainFailure, List<ImageRecord>> fetchByOwner({
    required ImageOwner owner,
    required String ownerId,
  }) => TaskEither.of(
    table
        .all()
        .where((image) => image.owner == owner && image.ownerId == ownerId)
        .toList(),
  );

  @override
  TaskEither<DomainFailure, ImageRecord> fetchById({required String id}) {
    final found = table.find(id);
    if (found == null) {
      return TaskEither<DomainFailure, ImageRecord>.left(
        NotFoundFailure('ImageRecord "$id" not found'),
      );
    }
    return TaskEither.of(found);
  }

  @override
  TaskEither<DomainFailure, ImageRecord> create({
    required ImageRecord image,
    IUnitOfWork? uow,
  }) {
    table.put(image);
    return TaskEither.of(image);
  }

  @override
  TaskEither<DomainFailure, void> delete({
    required String id,
    IUnitOfWork? uow,
  }) {
    if (!table.remove(id)) {
      return TaskEither<DomainFailure, void>.left(
        NotFoundFailure('ImageRecord "$id" not found'),
      );
    }
    return TaskEither.of(null);
  }

  @override
  TaskEither<DomainFailure, void> clearAll({IUnitOfWork? uow}) {
    table.replaceAll(const {});
    return TaskEither.of(null);
  }
}
