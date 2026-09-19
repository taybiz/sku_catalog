import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Folds a SKU's assembly tree into the parts a build needs, quantities
/// included.
///
/// [ResolveEffectiveAttributes] *merges* the layers that describe one thing to
/// find a value; this *folds* the tree that builds one thing to find a total.
/// Two operations on purpose: a form resolves, a purchase order folds.
///
/// Quantities multiply down the tree — [units] of a SKU holding 2 of a
/// sub-assembly holding 8 of a part needs `16 × units` of that part — so a loop
/// in the graph has no finite answer. The write path refuses to create one, and
/// this reports [WouldCreateCycleFailure] rather than a number that looks
/// plausible and is not.
class AggregateBillOfMaterials {
  /// Creates an [AggregateBillOfMaterials] use case.
  const AggregateBillOfMaterials({
    required IDeviceTypeRepository deviceTypeRepository,
    required ISkuComponentRepository skuComponentRepository,
  }) : _deviceTypeRepository = deviceTypeRepository,
       _skuComponentRepository = skuComponentRepository;

  final IDeviceTypeRepository _deviceTypeRepository;
  final ISkuComponentRepository _skuComponentRepository;

  /// Folds the assembly tree of the SKU [deviceTypeId] into a
  /// [BillOfMaterials] for [units] units of it.
  ///
  /// Fails with [NotFoundFailure] when the catalog has no such SKU, and with
  /// [InvalidInputFailure] when [units] is below one.
  TaskEither<DomainFailure, BillOfMaterials> call(
    String deviceTypeId, {
    int units = 1,
  }) {
    if (units < 1) {
      return TaskEither.left(
        InvalidInputFailure(
          'Cannot build $units of "$deviceTypeId": units must be at least 1',
        ),
      );
    }

    return _deviceTypeRepository.fetchAll().flatMap(
      (skus) => _skuComponentRepository.fetchAll().flatMap(
        (components) => _fold(deviceTypeId, units, skus, components),
      ),
    );
  }

  TaskEither<DomainFailure, BillOfMaterials> _fold(
    String deviceTypeId,
    int units,
    List<DeviceType> skus,
    List<SkuComponent> components,
  ) {
    final byId = {for (final sku in skus) sku.meta.id: sku};
    final root = byId[deviceTypeId];
    if (root == null) {
      return TaskEither.left(NotFoundFailure('SKU "$deviceTypeId" not found'));
    }

    final componentsOf = <String, List<SkuComponent>>{};
    for (final component in components) {
      (componentsOf[component.parentDeviceTypeId] ??= []).add(component);
    }

    final fold = _AssemblyFold(componentsOf);
    final failure = fold.explode(deviceTypeId, units);
    if (failure != null) return TaskEither.left(failure);

    final lines = [
      for (final entry in fold.totals.entries)
        BomLine(
          deviceTypeId: entry.key,
          modelNumber: byId[entry.key]?.modelNumber,
          quantity: entry.value.quantity,
          depth: entry.value.depth,
          isAssembly: componentsOf.containsKey(entry.key),
        ),
    ]..sort(_inLevelOrder);

    return TaskEither.of(
      BillOfMaterials(
        deviceTypeId: root.meta.id,
        modelNumber: root.modelNumber,
        units: units,
        lines: lines,
      ),
    );
  }

  /// Level first, so a report prints the tree top down; then model number and
  /// id, so the order does not depend on how a store handed its rows back.
  int _inLevelOrder(BomLine a, BomLine b) {
    final byDepth = a.depth.compareTo(b.depth);
    if (byDepth != 0) return byDepth;

    final byName = (a.modelNumber ?? a.deviceTypeId).compareTo(
      b.modelNumber ?? b.deviceTypeId,
    );
    return byName != 0 ? byName : a.deviceTypeId.compareTo(b.deviceTypeId);
  }
}

/// The fold: running totals for the parts reached, and the path being walked.
///
/// The path is what separates a shared part from a loop. A part reached twice is
/// summed twice and keeps the closest level it was reached at; an id reached
/// while it is already on the path is a loop, and the fold stops rather than
/// multiplying itself forever.
class _AssemblyFold {
  _AssemblyFold(this._componentsOf);

  final Map<String, List<SkuComponent>> _componentsOf;

  /// Quantity per part id, and the closest level it was reached at.
  final Map<String, _Total> totals = {};

  final Set<String> _path = {};

  /// Totals [units] of [deviceTypeId] and everything below it.
  ///
  /// Returns the failure that stopped it, or null when the whole tree folded.
  DomainFailure? explode(String deviceTypeId, int units) =>
      _explode(deviceTypeId, units, 0);

  DomainFailure? _explode(String id, int quantity, int depth) {
    _path.add(id);
    for (final component in _componentsOf[id] ?? const <SkuComponent>[]) {
      final childId = component.childDeviceTypeId;
      if (_path.contains(childId)) {
        return WouldCreateCycleFailure(
          'The assembly tree loops back to "$childId", so the quantity of '
          'parts it needs has no finite answer',
        );
      }

      final needed = quantity * component.quantity;
      _add(childId, needed, depth + 1);
      final failure = _explode(childId, needed, depth + 1);
      if (failure != null) return failure;
    }

    _path.remove(id);
    return null;
  }

  void _add(String deviceTypeId, int quantity, int depth) {
    final total = totals[deviceTypeId];
    if (total == null) {
      totals[deviceTypeId] = _Total(quantity, depth);
      return;
    }

    total.quantity += quantity;
    if (depth < total.depth) total.depth = depth;
  }
}

/// A running total for one part: how many the build needs, and the closest
/// level it is used at.
class _Total {
  _Total(this.quantity, this.depth);

  int quantity;
  int depth;
}
