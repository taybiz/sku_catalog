import 'package:fpdart/fpdart.dart';

import '../domain/domain.dart';
import 'resolve_instance_schema.dart';

/// Duplicates an instance: a unique "copy" name, the notes and classification
/// carried over, and no value for any attribute marked unique.
///
/// The last rule is the one a copy would otherwise break: a serial number
/// identifies the article it was read from, so the copy inherits the
/// classification and every value that is *not* unique, and starts with the
/// unique ones unset. The unique keys come from [ResolveInstanceSchema], the same
/// schema `AssertUniqueAttributeValues` measures a write against, so a copy never
/// has to be refused — it simply carries nothing that identifies the original.
///
/// Where the copy sits is the caller's to decide, as it is on [UpdateInstance]:
/// the copy takes the original's locate, and a caller that wants it somewhere
/// else updates it.
class DuplicateInstance {
  /// Creates a [DuplicateInstance] use case.
  const DuplicateInstance({
    required IInstanceRepository instanceRepository,
    required ResolveInstanceSchema resolveInstanceSchema,
    this.idGenerator,
  }) : _instanceRepository = instanceRepository,
       _resolveInstanceSchema = resolveInstanceSchema;

  final IInstanceRepository _instanceRepository;
  final ResolveInstanceSchema _resolveInstanceSchema;

  /// Mints the copy's id; defaults to a random UUID v4 when null.
  final IdGenerator? idGenerator;

  /// Executes the use case.
  TaskEither<DomainFailure, Instance> call({required String id}) =>
      _instanceRepository
          .fetchById(id: id)
          .flatMap(
            (current) => _resolveInstanceSchema(instance: current)
                .map(
                  (schema) => {
                    for (final entry in schema)
                      if (entry.def.isUnique) entry.def.key,
                  },
                )
                .flatMap(
                  (uniqueKeys) => _instanceRepository.fetchAll().flatMap((all) {
                    final copy = Instance(
                      meta: newMeta(
                        notes: current.meta.notes,
                        idGenerator: idGenerator,
                      ),
                      skuId: current.skuId,
                      locateId: current.locateId,
                      name: uniqueCopyName(
                        baseName: current.name,
                        locateId: current.locateId,
                        all: all,
                      ),
                      traitIds: current.traitIds,
                      attributeValues: {
                        for (final entry in current.attributeValues.entries)
                          if (!uniqueKeys.contains(entry.key))
                            entry.key: entry.value,
                      },
                      icon: current.icon,
                    );
                    return _instanceRepository.create(instance: copy);
                  }),
                ),
          );
}
