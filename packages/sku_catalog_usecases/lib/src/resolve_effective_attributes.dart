import 'package:sku_catalog_domain/sku_catalog_domain.dart';
import 'package:fpdart/fpdart.dart';

import 'resolve_schema.dart';

/// Resolves the *value* of every attribute in scope for a device or a SKU.
///
/// [ResolveSchema] answers "which attributes apply, and how are they defined";
/// this answers "what is the value, and who said so". They are deliberately
/// separate operations: a form renders the schema, a report reads the values,
/// and only the report cares who supplied one.
///
/// Precedence, nearest claim wins:
///
/// 1. the device instance — `source: 'device'`;
/// 2. the SKU that device instantiates — `source: 'device_type'`;
/// 3. every SKU above it in an assembly, nearest first, so a component can
///    inherit a value the assembly sets — `source: 'device_type'`, with
///    `inheritedFrom` naming the ancestor's model number;
/// 4. the attribute definition's own default — `source: 'default'`;
/// 5. nothing supplies a value: the entry keeps `value: null` and
///    `source: 'trait'`, which is exactly what [ResolveSchema] alone reports.
///
/// Values whose key no trait in scope defines are not returned. A trait is what
/// makes an attribute mean something, so a value with no definition behind it is
/// a data-integrity problem, not an attribute.
class ResolveEffectiveAttributes {
  /// Creates a [ResolveEffectiveAttributes] use case.
  const ResolveEffectiveAttributes({
    required IDeviceRepository deviceRepository,
    required IDeviceTypeRepository deviceTypeRepository,
    required ISkuComponentRepository skuComponentRepository,
    required ResolveSchema resolveSchema,
  }) : _deviceRepository = deviceRepository,
       _deviceTypeRepository = deviceTypeRepository,
       _skuComponentRepository = skuComponentRepository,
       _resolveSchema = resolveSchema;

  final IDeviceRepository _deviceRepository;
  final IDeviceTypeRepository _deviceTypeRepository;
  final ISkuComponentRepository _skuComponentRepository;
  final ResolveSchema _resolveSchema;

  /// Effective attributes for the device [deviceId], instance layer included.
  TaskEither<DomainFailure, List<ResolvedAttribute>> call(String deviceId) =>
      _deviceRepository
          .fetchById(deviceId)
          .flatMap((device) => _resolve(device.deviceTypeId, device: device));

  /// Effective attributes for a SKU with no instance layer.
  ///
  /// This is the "what does this part owe its assembly" question: a SKU used as
  /// a component resolves within the assemblies it belongs to, so it reports the
  /// values it would have in place.
  TaskEither<DomainFailure, List<ResolvedAttribute>> forSku(
    String deviceTypeId,
  ) => _resolve(deviceTypeId);

  TaskEither<DomainFailure, List<ResolvedAttribute>> _resolve(
    String deviceTypeId, {
    Device? device,
  }) => _assemblyChain(deviceTypeId).flatMap((chain) {
    final traitIds = <String>[
      ...?device?.traitIds,
      for (final sku in chain) ...sku.traitIds,
    ];
    return _resolveSchema(traitIds).map((schema) {
      final winners = _winners(device, chain);
      return [
        for (final entry in schema)
          _attribute(entry.def, winners[entry.def.key]),
      ];
    });
  });

  /// The SKU at [deviceTypeId] followed by the assemblies it belongs to,
  /// nearest first.
  ///
  /// Breadth-first, so the closest ancestor that sets a value is the one that
  /// wins. A SKU used in more than one assembly resolves against each of them in
  /// turn, in the order the edges come back. The visited set makes a cycle
  /// terminate instead of hanging: the write path refuses to create one, and
  /// this is only the backstop.
  TaskEither<DomainFailure, List<DeviceType>> _assemblyChain(
    String deviceTypeId,
  ) => _deviceTypeRepository.fetchAll().flatMap(
    (skus) => _skuComponentRepository.fetchAll().map((components) {
      final byId = {for (final sku in skus) sku.meta.id: sku};
      final parentsOf = <String, List<String>>{};
      for (final component in components) {
        (parentsOf[component.childDeviceTypeId] ??= []).add(
          component.parentDeviceTypeId,
        );
      }

      final chain = <DeviceType>[];
      final visited = <String>{};
      final queue = <String>[deviceTypeId];
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
  Map<String, _Value> _winners(Device? device, List<DeviceType> chain) {
    final winners = <String, _Value>{};
    final nearestId = chain.isEmpty ? null : chain.first.meta.id;

    for (final sku in chain.reversed) {
      final inheritedFrom = sku.meta.id == nearestId ? null : sku.modelNumber;
      for (final entry in sku.attributeValues.entries) {
        winners[entry.key] = _Value(entry.value, 'device_type', inheritedFrom);
      }
    }

    if (device != null) {
      for (final entry in device.attributeValues.entries) {
        winners[entry.key] = _Value(entry.value, 'device', null);
      }
    }
    return winners;
  }

  ResolvedAttribute _attribute(
    TraitAttributeDefinition definition,
    _Value? won,
  ) {
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
        source: 'default',
        def: definition,
      );
    }
    return ResolvedAttribute(
      attributeId: definition.meta.id,
      name: definition.displayLabel,
      value: null,
      unit: definition.unit,
      source: 'trait',
      def: definition,
    );
  }
}

/// A value that won a key, and who supplied it.
class _Value {
  const _Value(this.value, this.source, this.inheritedFrom);

  final dynamic value;
  final String source;
  final String? inheritedFrom;
}
