// A runnable tour of the package: classify, value, assemble, place, instantiate.
//
// It ships with a tiny in-memory backend so you can see the whole shape at
// once. Copy it as a starting point, or implement the same contracts over your
// own store — the use cases cannot tell the difference.
//
//   dart run example/sku_catalog_example.dart
import 'package:fpdart/fpdart.dart';
import 'package:sku_catalog/sku_catalog.dart';

Future<void> main() async {
  final traits = _Table<Trait>(
    Trait.fromJson,
    (t) => t.meta.id,
    (t) => t.toJson(),
  );
  final attributes = _Table<TraitAttributeDefinition>(
    TraitAttributeDefinition.fromJson,
    (a) => a.meta.id,
    (a) => a.toJson(),
  );
  final skus = _Table<DeviceType>(
    DeviceType.fromJson,
    (s) => s.meta.id,
    (s) => s.toJson(),
  );
  final assemblies = _Table<SkuComponent>(
    SkuComponent.fromJson,
    (c) => c.meta.id,
    (c) => c.toJson(),
  );
  final locates = _Table<Locate>(
    Locate.fromJson,
    (l) => l.meta.id,
    (l) => l.toJson(),
  );
  final devices = _Table<Device>(
    Device.fromJson,
    (d) => d.meta.id,
    (d) => d.toJson(),
  );

  final traitRepository = _Traits(traits);
  final attributeRepository = _Attributes(attributes);
  final skuRepository = _Skus(skus);
  final assemblyRepository = _Components(assemblies);
  final locateRepository = _Locates(locates);
  final deviceRepository = _Devices(devices);

  // 1. Classify. Traits form a tree: Breaker is a Switch with more to say.
  final switchTrait = Trait(
    meta: _meta('switch'),
    name: 'Switch',
    scope: const [TraitScope.sku],
  );
  final breakerTrait = Trait(
    meta: _meta('breaker'),
    name: 'Breaker',
    parentTraitId: switchTrait.meta.id,
    scope: const [TraitScope.sku],
  );
  await CreateTrait(traitRepository)(switchTrait).run();
  await CreateTrait(traitRepository)(breakerTrait).run();

  // 2. Value: each trait contributes typed fields, and a child overrides them.
  await CreateTraitAttributeDefinition(attributeRepository)(
    TraitAttributeDefinition(
      meta: _meta('switch-rated_amps'),
      traitId: switchTrait.meta.id,
      key: 'rated_amps',
      displayLabel: 'Rated Amperage',
      dataType: DataType.number,
      unit: 'A',
      isRequired: true,
    ),
  ).run();
  await CreateTraitAttributeDefinition(attributeRepository)(
    TraitAttributeDefinition(
      meta: _meta('breaker-trip_amperage'),
      traitId: breakerTrait.meta.id,
      key: 'trip_amperage',
      displayLabel: 'Trip Amperage',
      dataType: DataType.number,
      unit: 'A',
    ),
  ).run();

  // 3. Catalogue the SKUs. A panel and a breaker are both products.
  final breakerModel = DeviceType(
    meta: _meta('qo120'),
    manufacturerId: 'square-d',
    modelNumber: 'QO120',
    traitIds: [breakerTrait.meta.id],
    attributeValues: const {'rated_amps': 20, 'trip_amperage': 20},
  );
  final panelModel = DeviceType(
    meta: _meta('qo-16'),
    manufacturerId: 'square-d',
    modelNumber: 'QO-16',
  );
  await CreateDeviceType(skuRepository)(breakerModel).run();
  await CreateDeviceType(skuRepository)(panelModel).run();

  // 4. Assemble: the panel contains sixteen breakers. On purpose the edge is
  //    tried twice the other way round, to show the cycle guard refuse it.
  final addComponent = AddSkuComponent(
    repository: assemblyRepository,
    deviceTypeRepository: skuRepository,
  );
  await addComponent(
    parentDeviceTypeId: panelModel.meta.id,
    childDeviceTypeId: breakerModel.meta.id,
    quantity: 16,
  ).run();
  final loop = await addComponent(
    parentDeviceTypeId: breakerModel.meta.id,
    childDeviceTypeId: panelModel.meta.id,
    quantity: 1,
  ).run();

  // 5. Place: a Locate is a place, and places nest. The panel goes in a room.
  final garage = Locate(meta: _meta('garage'), name: 'Garage');
  final panelPlace = Locate(
    meta: _meta('garage.panel'),
    name: 'Panel Position',
    parentLocateId: garage.meta.id,
  );
  await CreateLocate(locateRepository)(garage).run();
  await CreateLocate(locateRepository)(panelPlace).run();

  // 6. Instantiate: a device is one article of a SKU, at one place.
  final panelDevice = Device(
    meta: _meta('pnl-1'),
    deviceTypeId: panelModel.meta.id,
    locateId: panelPlace.meta.id,
    name: 'Garage Panel 1',
  );
  await CreateDevice(deviceRepository)(panelDevice).run();

  // 7. Ask the model what it knows. Traits inherit, so the breaker's schema
  //    carries Switch's attributes too.
  final schema = await ResolveSchema(
    traitRepository: traitRepository,
    attributeRepository: attributeRepository,
  )(breakerModel.traitIds).run();

  final schemaLine = schema.fold(
    (failure) => 'failed: ${failure.message}',
    (resolved) => resolved
        .map((a) => '${a.name}${a.def.unit == null ? '' : ' (${a.def.unit})'}')
        .join(', '),
  );
  final partsCount = await FetchSkuComponentsByDeviceType(assemblyRepository)(
    panelModel.meta.id,
  ).run();
  final devicesAtPlace = await FetchDevicesByLocate(deviceRepository)(
    panelPlace.meta.id,
  ).run();

  print(
    'SKU        ${panelModel.modelNumber} — contains '
    '${partsCount.fold((f) => '?', (rows) => rows.first.quantity)} × '
    '${breakerModel.modelNumber}',
  );
  print('Schema     ${breakerModel.modelNumber} → $schemaLine');
  print(
    'Place      ${garage.name} / ${panelPlace.name} → '
    '${devicesAtPlace.fold((f) => '?', (rows) => rows.single.name)}',
  );
  print(
    'Assembly   panel in breaker? '
    '${loop.fold((failure) => 'refused (${failure.message})', (_) => 'allowed — BUG')}',
  );

  // 8. A device carries its own classification and values, independent of the
  //    model it came from — which is what lets one SKU be wired two ways.
  final spare = panelDevice.copyWith(
    name: 'Spare Panel',
    locateId: null,
    traitIds: const ['spare'],
    attributeValues: const {'note': 'not yet fitted'},
  );
  print('Instance   ${spare.name} is placed? ${spare.isPlaced}');
}

Meta _meta(String id) => Meta(
  id: id,
  notes: '',
  createdAt: '2026-01-01T00:00:00.000Z',
  updatedAt: '2026-01-01T00:00:00.000Z',
);

/// A trivial map-backed store, enough to demonstrate the contracts.
class _Table<T> {
  _Table(this.decode, this.idOf, this.encode);

  final T Function(Map<String, dynamic>) decode;
  final String Function(T) idOf;
  final Map<String, dynamic> Function(T) encode;
  final Map<String, Map<String, dynamic>> rows = {};

  Iterable<Map<String, dynamic>> all() => rows.values;
  void put(T entity) => rows[idOf(entity)] = encode(entity);
  bool remove(String id) => rows.remove(id) != null;
  T get(String id) => decode(rows[id]!);
  bool has(String id) => rows.containsKey(id);
}

class _Traits implements ITraitRepository {
  _Traits(this.table);
  final _Table<Trait> table;

  @override
  TaskEither<DomainFailure, List<Trait>> fetchAll() =>
      TaskEither.of(table.all().map(Trait.fromJson).toList());

  @override
  TaskEither<DomainFailure, Trait> fetchById(String id) => table.has(id)
      ? TaskEither.of(table.get(id))
      : _missing<Trait>('Trait', id);

  @override
  TaskEither<DomainFailure, Trait> create(Trait trait, {IUnitOfWork? uow}) {
    table.put(trait);
    return TaskEither.of(trait);
  }

  @override
  TaskEither<DomainFailure, Trait> update(Trait trait, {IUnitOfWork? uow}) =>
      create(trait);

  @override
  TaskEither<DomainFailure, void> delete(String id, {IUnitOfWork? uow}) {
    table.remove(id);
    return TaskEither.of(null);
  }

  @override
  TaskEither<DomainFailure, void> clearAll({IUnitOfWork? uow}) {
    table.rows.clear();
    return TaskEither.of(null);
  }
}

class _Attributes implements ITraitAttributeDefinitionRepository {
  _Attributes(this.table);
  final _Table<TraitAttributeDefinition> table;

  @override
  TaskEither<DomainFailure, List<TraitAttributeDefinition>> fetchAll() =>
      TaskEither.of(
        table.all().map(TraitAttributeDefinition.fromJson).toList(),
      );

  @override
  TaskEither<DomainFailure, List<TraitAttributeDefinition>> fetchByTrait(
    String traitId,
  ) => TaskEither.of(
    table
        .all()
        .map(TraitAttributeDefinition.fromJson)
        .where((a) => a.traitId == traitId)
        .toList(),
  );

  @override
  TaskEither<DomainFailure, TraitAttributeDefinition> fetchById(String id) =>
      table.has(id)
      ? TaskEither.of(table.get(id))
      : _missing<TraitAttributeDefinition>('Attribute', id);

  @override
  TaskEither<DomainFailure, TraitAttributeDefinition> create(
    TraitAttributeDefinition attribute, {
    IUnitOfWork? uow,
  }) {
    table.put(attribute);
    return TaskEither.of(attribute);
  }

  @override
  TaskEither<DomainFailure, TraitAttributeDefinition> update(
    TraitAttributeDefinition attribute, {
    IUnitOfWork? uow,
  }) => create(attribute);

  @override
  TaskEither<DomainFailure, void> delete(String id, {IUnitOfWork? uow}) {
    table.remove(id);
    return TaskEither.of(null);
  }

  @override
  TaskEither<DomainFailure, void> clearAll({IUnitOfWork? uow}) {
    table.rows.clear();
    return TaskEither.of(null);
  }
}

class _Skus implements IDeviceTypeRepository {
  _Skus(this.table);
  final _Table<DeviceType> table;

  @override
  TaskEither<DomainFailure, List<DeviceType>> fetchAll() =>
      TaskEither.of(table.all().map(DeviceType.fromJson).toList());

  @override
  TaskEither<DomainFailure, DeviceType> fetchById(String id) => table.has(id)
      ? TaskEither.of(table.get(id))
      : _missing<DeviceType>('SKU', id);

  @override
  TaskEither<DomainFailure, DeviceType> create(
    DeviceType deviceType, {
    IUnitOfWork? uow,
  }) {
    table.put(deviceType);
    return TaskEither.of(deviceType);
  }

  @override
  TaskEither<DomainFailure, DeviceType> update(
    DeviceType deviceType, {
    IUnitOfWork? uow,
  }) => create(deviceType);

  @override
  TaskEither<DomainFailure, void> delete(String id, {IUnitOfWork? uow}) {
    table.remove(id);
    return TaskEither.of(null);
  }

  @override
  TaskEither<DomainFailure, void> clearAll({IUnitOfWork? uow}) {
    table.rows.clear();
    return TaskEither.of(null);
  }
}

class _Components implements ISkuComponentRepository {
  _Components(this.table);
  final _Table<SkuComponent> table;

  @override
  TaskEither<DomainFailure, List<SkuComponent>> fetchAll() =>
      TaskEither.of(table.all().map(SkuComponent.fromJson).toList());

  @override
  TaskEither<DomainFailure, List<SkuComponent>> fetchByDeviceType(
    String deviceTypeId,
  ) => TaskEither.of(
    table
        .all()
        .map(SkuComponent.fromJson)
        .where((c) => c.parentDeviceTypeId == deviceTypeId)
        .toList(),
  );

  @override
  TaskEither<DomainFailure, SkuComponent> fetchById(String id) => table.has(id)
      ? TaskEither.of(table.get(id))
      : _missing<SkuComponent>('Assembly edge', id);

  @override
  TaskEither<DomainFailure, SkuComponent> create(
    SkuComponent component, {
    IUnitOfWork? uow,
  }) {
    table.put(component);
    return TaskEither.of(component);
  }

  @override
  TaskEither<DomainFailure, void> delete(String id, {IUnitOfWork? uow}) {
    table.remove(id);
    return TaskEither.of(null);
  }

  @override
  TaskEither<DomainFailure, void> clearAll({IUnitOfWork? uow}) {
    table.rows.clear();
    return TaskEither.of(null);
  }
}

class _Locates implements ILocateRepository {
  _Locates(this.table);
  final _Table<Locate> table;

  @override
  TaskEither<DomainFailure, List<Locate>> fetchAll() =>
      TaskEither.of(table.all().map(Locate.fromJson).toList());

  @override
  TaskEither<DomainFailure, Locate> fetchById(String id) => table.has(id)
      ? TaskEither.of(table.get(id))
      : _missing<Locate>('Locate', id);

  @override
  TaskEither<DomainFailure, Locate> create(Locate locate, {IUnitOfWork? uow}) {
    table.put(locate);
    return TaskEither.of(locate);
  }

  @override
  TaskEither<DomainFailure, Locate> update(Locate locate, {IUnitOfWork? uow}) =>
      create(locate);

  @override
  TaskEither<DomainFailure, void> delete(String id, {IUnitOfWork? uow}) {
    table.remove(id);
    return TaskEither.of(null);
  }

  @override
  TaskEither<DomainFailure, void> clearAll({IUnitOfWork? uow}) {
    table.rows.clear();
    return TaskEither.of(null);
  }
}

class _Devices implements IDeviceRepository {
  _Devices(this.table);
  final _Table<Device> table;

  @override
  TaskEither<DomainFailure, List<Device>> fetchAll() =>
      TaskEither.of(table.all().map(Device.fromJson).toList());

  @override
  TaskEither<DomainFailure, List<Device>> fetchByLocate(String locateId) =>
      TaskEither.of(
        table
            .all()
            .map(Device.fromJson)
            .where((d) => d.locateId == locateId)
            .toList(),
      );

  @override
  TaskEither<DomainFailure, Device> fetchById(String id) => table.has(id)
      ? TaskEither.of(table.get(id))
      : _missing<Device>('Device', id);

  @override
  TaskEither<DomainFailure, Device> create(Device device, {IUnitOfWork? uow}) {
    table.put(device);
    return TaskEither.of(device);
  }

  @override
  TaskEither<DomainFailure, Device> update(Device device, {IUnitOfWork? uow}) =>
      create(device);

  @override
  TaskEither<DomainFailure, void> delete(String id, {IUnitOfWork? uow}) {
    table.remove(id);
    return TaskEither.of(null);
  }

  @override
  TaskEither<DomainFailure, void> clearAll({IUnitOfWork? uow}) {
    table.rows.clear();
    return TaskEither.of(null);
  }
}

TaskEither<DomainFailure, T> _missing<T>(String what, String id) =>
    TaskEither<DomainFailure, T>.left(NotFoundFailure('$what "$id" not found'));
