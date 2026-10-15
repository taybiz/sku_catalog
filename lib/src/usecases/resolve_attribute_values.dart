import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

import 'resolve_schema.dart';

/// Resolves the value of every attribute in scope for a SKU and the layers on it.
///
/// This is the shared step under `ResolveEffectiveAttributes` (one article) and
/// `ResolveSkuAttributes` (one model, inside its assemblies), and it is the only
/// place the precedence rule lives. It is deliberately **not exported** by this
/// library: a consumer asks one of those two questions rather than assembling the
/// layers itself, so the answer stays a single rule instead of a DIY kit.
///
/// [ResolveSchema] answers "which attributes apply, and how are they defined";
/// this answers "what is the value, and who said so". They are deliberately
/// separate operations: a form renders the schema, a report reads the values, and
/// only the report cares who supplied one.
///
/// Precedence, nearest claim wins:
///
/// 1. the instance layer, when there is one — [AttributeValueSource.instance];
/// 2. the SKU itself — [AttributeValueSource.sku];
/// 3. every SKU above it in an assembly, nearest first, so a component can inherit
///    a value the assembly sets — [AttributeValueSource.sku], with `inheritedFrom`
///    naming the ancestor's model number;
/// 4. the attribute definition's own default — [AttributeValueSource.fallback];
/// 5. nothing supplies a value: the entry keeps `value: null` and
///    [AttributeValueSource.trait], which is exactly what [ResolveSchema] alone
///    reports.
///
/// Values whose key no trait in scope defines are not returned. A trait is what
/// makes an attribute mean something, so a value with no definition behind it is a
/// data-integrity problem, not an attribute.
class ResolveAttributeValues {
  /// Creates a [ResolveAttributeValues] use case.
  const ResolveAttributeValues({
    required ISkuRepository skuRepository,
    required ISkuComponentRepository skuComponentRepository,
    required ResolveSchema resolveSchema,
  }) : _skuRepository = skuRepository,
       _skuComponentRepository = skuComponentRepository,
       _resolveSchema = resolveSchema;

  final ISkuRepository _skuRepository;
  final ISkuComponentRepository _skuComponentRepository;
  final ResolveSchema _resolveSchema;

  /// Executes the use case: the values for [skuId] within its assemblies, with
  /// [traitIds] (classification the caller brings with it, such as an instance's
  /// own) added to the schema, and the [instance] layer winning where it sets one.
  TaskEither<DomainFailure, List<ResolvedAttribute>> call({
    required String skuId,
    List<String> traitIds = const <String>[],
    Instance? instance,
  }) => _assemblyChain(skuId: skuId).flatMap((chain) {
    final inScope = <String>[
      ...traitIds,
      for (final sku in chain) ...sku.traitIds,
    ];
    return _resolveSchema(traitIds: inScope).map((schema) {
      final winners = _winners(instance: instance, chain: chain);
      return [
        for (final entry in schema)
          _attribute(definition: entry.def, won: winners[entry.def.key]),
      ];
    });
  });

  /// The SKU at [skuId] followed by the assemblies it belongs to,
  /// nearest first.
  ///
  /// Breadth-first, so the closest ancestor that sets a value is the one that
  /// wins. A SKU used in more than one assembly resolves against each of them in
  /// turn, in the order the edges come back. The visited set makes a cycle
  /// terminate instead of hanging: the write path refuses to create one, and
  /// this is only the backstop.
  TaskEither<DomainFailure, List<Sku>> _assemblyChain({
    required String skuId,
  }) => _skuRepository.fetchAll().flatMap(
    (skus) => _skuComponentRepository.fetchAll().map((components) {
      final byId = {for (final sku in skus) sku.meta.id: sku};
      final parentsOf = <String, List<String>>{};
      for (final component in components) {
        (parentsOf[component.childSkuId] ??= []).add(component.parentSkuId);
      }

      final chain = <Sku>[];
      final visited = <String>{};
      final queue = <String>[skuId];
      while (queue.isNotEmpty) {
        final id = queue.removeAt(0);
        if (!visited.add(id)) continue;
        final sku = byId[id];
        if (sku == null) continue;
        chain.add(sku);
        queue.addAll(parentsOf[id] ?? const []);
      }
      return chain;
    }),
  );

  /// The value that wins each key, gathered from the weakest claim to the
  /// strongest so the last write is the nearest one.
  Map<String, _Value> _winners({
    required Instance? instance,
    required List<Sku> chain,
  }) {
    final winners = <String, _Value>{};
    final nearestId = chain.isEmpty ? null : chain.first.meta.id;

    for (final sku in chain.reversed) {
      final inheritedFrom = sku.meta.id == nearestId ? null : sku.modelNumber;
      for (final entry in sku.attributeValues.entries) {
        winners[entry.key] = _Value(
          entry.value,
          AttributeValueSource.sku,
          inheritedFrom,
        );
      }
    }

    if (instance != null) {
      for (final entry in instance.attributeValues.entries) {
        winners[entry.key] = _Value(
          entry.value,
          AttributeValueSource.instance,
          null,
        );
      }
    }
    return winners;
  }

  ResolvedAttribute _attribute({
    required TraitAttributeDefinition definition,
    _Value? won,
  }) {
    if (won != null) {
      return ResolvedAttribute(
        attributeId: definition.meta.id,
        name: definition.displayLabel,
        value: won.value,
        unit: definition.unit,
        source: won.source,
        def: definition,
        inheritedFrom: won.inheritedFrom,
      );
    }
    if (definition.defaultValue != null) {
      return ResolvedAttribute(
        attributeId: definition.meta.id,
        name: definition.displayLabel,
        value: definition.defaultValue,
        unit: definition.unit,
        source: AttributeValueSource.fallback,
        def: definition,
      );
    }
    return ResolvedAttribute(
      attributeId: definition.meta.id,
      name: definition.displayLabel,
      value: null,
      unit: definition.unit,
      source: AttributeValueSource.trait,
      def: definition,
    );
  }
}

/// A value that won a key, and who supplied it.
class _Value {
  const _Value(this.value, this.source, this.inheritedFrom);

  final dynamic value;
  final AttributeValueSource source;
  final String? inheritedFrom;
}
