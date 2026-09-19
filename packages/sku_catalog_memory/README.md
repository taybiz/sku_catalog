# sku_catalog_memory

An **in-memory implementation** of every
[`sku_catalog_domain`](https://pub.dev/packages/sku_catalog_domain) repository
contract — for tests, prototypes, demos and fixtures.

```yaml
dependencies:
  sku_catalog_memory: ^0.1.0
```

```dart
final skus = MemoryDeviceTypeRepository();
final locates = MemoryLocateRepository();

await CreateDeviceType(skus)(someSku).run();
await CreateLocate(locates)(Locate(meta: meta, name: 'Rack 1')).run();
```

One class per contract, each backed by a `Map`:

`MemoryTraitRepository`, `MemoryTraitAttributeDefinitionRepository`,
`MemoryDeviceTypeRepository`, `MemorySkuComponentRepository`,
`MemoryLocateRepository`, `MemoryManufacturerRepository`,
`MemoryDeviceRepository`, `MemoryImageRepository`, `MemoryMetaRepository`.

## Transactions

`MemoryUnitOfWork` snapshots the rows of every store you register and puts them
back when the body throws — so an atomic operation is testable with no database:

```dart
final uow = MemoryUnitOfWork([skus, edges]);

final result = await DeleteDeviceType(
  deviceTypeRepository: skus,
  deviceRepository: devices,
  skuComponentRepository: edges,
  unitOfWork: uow,                 // a failed delete leaves the edges intact
)('some-sku').run();
```

Its test suite pins both halves: with a unit of work the partial write is undone,
and without one it is not. Register the stores the operation touches — a store
that is not registered is not rolled back.

State is per-instance and disappears with the object; records round-trip
through the entities' `toJson`/`fromJson`, so an entity that cannot serialise
will not store. This is deliberately **not** a production store: nothing is
persisted and nothing is shared between instances.

## License

MIT.
