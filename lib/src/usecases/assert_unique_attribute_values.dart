import 'package:fpdart/fpdart.dart';

import '../domain/domain.dart';
import 'resolve_instance_schema.dart';
import 'resolve_schema.dart';

/// Enforces the one rule a unique attribute carries: at most one **holder** in
/// the catalog may hold a value for it.
///
/// A holder is one of the three records that carry trait values — an article
/// ([ArticleHolder]), a place ([PlaceHolder]) or a maker ([MakerHolder]) — and a
/// unique attribute is unique across all three at once: a serial number one
/// article holds cannot be minted by a place or a maker either. A SKU is not a
/// holder here: the values on a model describe the class, not one article, so
/// nothing on a model is unique in this sense.
///
/// The value is measured against the schema in scope for the holder being written
/// — [ResolveInstanceSchema] for an article (its own traits plus its model's,
/// walked up their parent chains), [ResolveSchema] over the traits a place or a
/// maker carries itself — so a unique attribute declared on a parent trait holds
/// for every trait below it.
///
/// Three boundaries are deliberate:
///
/// - **The holder's own values only**, not the ones it would resolve by
///   inheritance from the SKUs above it: what is written is what is claimed;
/// - **The claimer's definition decides equality.** Two holders compare their
///   values the way this package compares values anywhere: strings trimmed and
///   case-insensitively, numbers by value, different types as different values,
///   and a value nobody set never clashes with anything;
/// - **Nothing extra to implement.** The check reads through `fetchAll()` on the
///   three contracts, so a backend needs only the contracts it already
///   implements. An adapter that wants this cheap can index the unique keys on
///   its own side; the rule stays a use case, not a storage feature.
class AssertUniqueAttributeValues {
  /// Creates an [AssertUniqueAttributeValues] use case.
  const AssertUniqueAttributeValues({
    required IInstanceRepository instanceRepository,
    required ILocateRepository locateRepository,
    required IManufacturerRepository manufacturerRepository,
    required ResolveInstanceSchema resolveInstanceSchema,
    required ResolveSchema resolveSchema,
  }) : _instances = instanceRepository,
       _locates = locateRepository,
       _manufacturers = manufacturerRepository,
       _resolveInstanceSchema = resolveInstanceSchema,
       _resolveSchema = resolveSchema;

  final IInstanceRepository _instances;
  final ILocateRepository _locates;
  final IManufacturerRepository _manufacturers;
  final ResolveInstanceSchema _resolveInstanceSchema;
  final ResolveSchema _resolveSchema;

  /// Executes the use case for [holder] — the one record being written, wrapped
  /// as an [ArticleHolder], a [PlaceHolder] or a [MakerHolder].
  ///
  /// Fails with [DuplicateAttributeValueFailure] when another holder, of any of
  /// the three kinds, already holds a value this one claims, naming it. The
  /// holder's own key is excluded, so an update that keeps a value, or rewrites
  /// everything but the serial number, is not a clash with itself.
  TaskEither<DomainFailure, Unit> call({required AttributeHolder holder}) =>
      _schemaInScope(holder).flatMap(
        (schema) => _holders().flatMap((others) {
          final clash = _clash(holder: holder, schema: schema, others: others);
          return clash == null
              ? TaskEither<DomainFailure, Unit>.of(unit)
              : TaskEither<DomainFailure, Unit>.left(clash);
        }),
      );

  /// The schema in scope for [holder]: an article's own traits plus its model's,
  /// or the traits a place or a maker carries itself.
  TaskEither<DomainFailure, List<ResolvedAttribute>> _schemaInScope(
    AttributeHolder holder,
  ) => switch (holder) {
    ArticleHolder(:final instance) => _resolveInstanceSchema(
      instance: instance,
    ),
    PlaceHolder(:final locate) => _resolveSchema(traitIds: locate.traitIds),
    MakerHolder(:final manufacturer) => _resolveSchema(
      traitIds: manufacturer.traitIds,
    ),
  };

  /// Every holder in the catalog, of every kind, as the rule compares them.
  TaskEither<DomainFailure, List<AttributeHolder>> _holders() =>
      _instances.fetchAll().flatMap(
        (instances) => _locates.fetchAll().flatMap(
          (locates) => _manufacturers.fetchAll().map(
            (makers) => <AttributeHolder>[
              for (final instance in instances) ArticleHolder(instance),
              for (final locate in locates) PlaceHolder(locate),
              for (final maker in makers) MakerHolder(maker),
            ],
          ),
        ),
      );

  /// The first clash between the unique values [holder] claims and [others].
  DomainFailure? _clash({
    required AttributeHolder holder,
    required List<ResolvedAttribute> schema,
    required List<AttributeHolder> others,
  }) {
    for (final entry in schema) {
      final definition = entry.def;
      if (!definition.isUnique) continue;
      final value = holder.values[definition.key];
      if (value == null) continue;
      for (final other in others) {
        if (other.key == holder.key) continue;
        if (definition.valuesMatch(a: other.values[definition.key], b: value)) {
          return DuplicateAttributeValueFailure(
            'The value "$value" for the unique attribute "${definition.key}" is '
            'already held by ${other.kindName} "${other.label}" (${other.id})',
          );
        }
      }
    }
    return null;
  }
}
