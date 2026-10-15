import 'package:fpdart/fpdart.dart';

import '../domain/domain.dart';
import 'resolve_instance_schema.dart';
import 'resolve_schema.dart';

/// Enforces the one rule a unique attribute carries: at most one **holder** in
/// the catalog may hold a value for it.
///
/// Three kinds of record hold trait values — an article ([Instance]), the place
/// it sits at ([Locate]) and the maker of its model ([Manufacturer]) — and a
/// unique attribute is unique across all three at once: a serial number an
/// article holds cannot be minted by a place or a maker either. A SKU is not a
/// holder here: the values on a model describe the class, not one article, so
/// nothing on a model is unique in this sense.
///
/// The value is measured against the schema in scope for the record being
/// written — [ResolveInstanceSchema] for an article (its own traits plus its
/// model's, walked up their parent chains), [ResolveSchema] over the traits a
/// place or a maker carries itself — so a unique attribute declared on a parent
/// trait holds for every trait below it.
///
/// Three boundaries are deliberate:
///
/// - **The record's own values only**, not the ones it would resolve by
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

  /// Executes the use case: pass the one record being written, as [article],
  /// [place] or [maker].
  ///
  /// Fails with [DuplicateAttributeValueFailure] when another holder — of any of
  /// the three kinds — already holds a value this one claims, naming it. The
  /// record's own id is excluded, so an update that keeps a value, or rewrites
  /// everything but the serial number, is not a clash with itself.
  TaskEither<DomainFailure, Unit> call({
    Instance? article,
    Locate? place,
    Manufacturer? maker,
  }) {
    final holder = _holder(article: article, place: place, maker: maker);
    return _schemaInScope(holder).flatMap(
      (schema) => _holders().flatMap((others) {
        final clash = _clash(holder: holder, schema: schema, others: others);
        return clash == null
            ? TaskEither<DomainFailure, Unit>.of(unit)
            : TaskEither<DomainFailure, Unit>.left(clash);
      }),
    );
  }

  /// The schema in scope for [holder]: an article's own plus its model's, or the
  /// traits a place or a maker carries itself.
  TaskEither<DomainFailure, List<ResolvedAttribute>> _schemaInScope(
    _Holder holder,
  ) {
    final article = holder.article;
    if (article != null) return _resolveInstanceSchema(instance: article);
    return _resolveSchema(traitIds: holder.traitIds);
  }

  /// Every holder in the catalog, of every kind, as the rule compares them.
  TaskEither<DomainFailure, List<_Holder>> _holders() =>
      _instances.fetchAll().flatMap(
        (instances) => _locates.fetchAll().flatMap(
          (locates) => _manufacturers.fetchAll().map(
            (makers) => [
              for (final instance in instances)
                _Holder(
                  kind: 'instance',
                  id: instance.meta.id,
                  label: instance.name,
                  values: instance.attributeValues,
                ),
              for (final locate in locates)
                _Holder(
                  kind: 'place',
                  id: locate.meta.id,
                  label: locate.name,
                  values: locate.attributeValues,
                ),
              for (final maker in makers)
                _Holder(
                  kind: 'maker',
                  id: maker.meta.id,
                  label: maker.name,
                  values: maker.attributeValues,
                ),
            ],
          ),
        ),
      );

  /// The first clash between the unique values [holder] claims and [others].
  DomainFailure? _clash({
    required _Holder holder,
    required List<ResolvedAttribute> schema,
    required List<_Holder> others,
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
            'already held by ${other.kind} "${other.label}" (${other.id})',
          );
        }
      }
    }
    return null;
  }

  /// The record being written, from whichever of the three was passed.
  static _Holder _holder({
    Instance? article,
    Locate? place,
    Manufacturer? maker,
  }) {
    final passed = [
      article,
      place,
      maker,
    ].where((record) => record != null).length;
    if (passed != 1) {
      throw ArgumentError.value(
        passed,
        'passed',
        'Pass exactly one of article, place or maker',
      );
    }
    if (article != null) {
      return _Holder(
        kind: 'instance',
        id: article.meta.id,
        label: article.name,
        values: article.attributeValues,
        article: article,
      );
    }
    if (place != null) {
      return _Holder(
        kind: 'place',
        id: place.meta.id,
        label: place.name,
        values: place.attributeValues,
        traitIds: place.traitIds,
      );
    }
    return _Holder(
      kind: 'maker',
      id: maker!.meta.id,
      label: maker.name,
      values: maker.attributeValues,
      traitIds: maker.traitIds,
    );
  }
}

/// One record that holds trait values, as this rule sees it.
class _Holder {
  const _Holder({
    required this.kind,
    required this.id,
    required this.label,
    required this.values,
    this.article,
    this.traitIds = const [],
  });

  /// The word a failure message calls this kind of record.
  final String kind;

  /// The record's id.
  final String id;

  /// The name to show when a claim clashes.
  final String label;

  /// The values this record claims.
  final Map<String, dynamic> values;

  /// The article, when the record is one — its schema needs its model.
  final Instance? article;

  /// The traits the record carries itself, for a place or a maker.
  final List<String> traitIds;

  /// Identifies the record across kinds: an article and a place may share an id.
  String get key => '$kind:$id';
}
