import 'package:fpdart/fpdart.dart';

import '../domain/domain.dart';
import 'resolve_instance_schema.dart';

/// Duplicates an instance: a unique "copy" name, notes and classification carried
/// over, no locate when the SKU is bound to a slot (a copy is not fitted to
/// anything yet), and no value for any attribute marked unique.
///
/// The last rule is the one a copy would otherwise break: a serial number
/// identifies the article it was read from, so the copy inherits the
/// classification and every value that is *not* unique, and starts with the
/// unique ones unset — exactly like the locate, which a copy does not inherit.
/// The unique keys come from [ResolveInstanceSchema], the same schema
/// `AssertUniqueAttributeValues` measures a write against, so a copy never has to
/// be refused: it simply carries nothing that identifies the original.
///
/// See [UpdateInstance] on [slotBoundTraitNames] — the rule is the caller's
/// convention, never the catalog's vocabulary.
class DuplicateInstance {
  /// Creates a [DuplicateInstance] use case.
  const DuplicateInstance({
    required IInstanceRepository instanceRepository,
    required ISkuRepository skuRepository,
    required ITraitRepository traitRepository,
    required ResolveInstanceSchema resolveInstanceSchema,
    this.slotBoundTraitNames = const <String>{},
    this.idGenerator,
  }) : _instanceRepository = instanceRepository,
       _skuRepository = skuRepository,
       _traitRepository = traitRepository,
       _resolveInstanceSchema = resolveInstanceSchema;

  final IInstanceRepository _instanceRepository;
  final ISkuRepository _skuRepository;
  final ITraitRepository _traitRepository;
  final ResolveInstanceSchema _resolveInstanceSchema;

  /// Trait names (matched case-insensitively) whose instances carry no locate.
  final Set<String> slotBoundTraitNames;

  /// Mints the copy's id; defaults to a random UUID v4 when null.
  final IdGenerator? idGenerator;

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
                      typeId: current.skuId,
                      skus: types,
                      traits: traits,
                      traitNames: slotBoundTraitNames,
                    );
                final copyLocate = bound ? null : current.locateId;
                return _resolveInstanceSchema(instance: current)
                    .map(
                      (schema) => {
                        for (final entry in schema)
                          if (entry.def.isUnique) entry.def.key,
                      },
                    )
                    .flatMap(
                      (uniqueKeys) => _instanceRepository.fetchAll().flatMap((
                        all,
                      ) {
                        final copy = Instance(
                          meta: newMeta(
                            notes: current.meta.notes,
                            idGenerator: idGenerator,
                          ),
                          skuId: current.skuId,
                          locateId: copyLocate,
                          name: uniqueCopyName(
                            baseName: current.name,
                            locateId: copyLocate,
                            all: all,
                          ),
                          skuModelNumber: current.skuModelNumber,
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
                    );
              }),
            ),
          );
}
