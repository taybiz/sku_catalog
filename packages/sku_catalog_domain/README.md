# sku_catalog_domain

The **model** behind [`sku_catalog`](https://pub.dev/packages/sku_catalog):
traits with typed attributes, SKUs, assemblies of SKUs, manufacturers, places
(`Locate`), devices, images, failures, and the repository contracts.

No operations and no storage. Depend on this package when you are implementing
a backend or your own application layer and do not want the bundled use cases
in scope.

```yaml
dependencies:
  sku_catalog_domain: ^0.1.0
```

## What is here

- `Meta`, `Trait`, `TraitAttributeDefinition`, `DataType`, `TraitScope`
- `DeviceType` (a SKU), `SkuComponent` (an assembly edge: parent SKU, child SKU, quantity)
- `Manufacturer`, `Locate` (a place, as a tree), `Device` (an instance of a SKU at one place)
- `ImageRecord`, `ResolvedAttribute`
- `I*Repository` contracts for every aggregate, plus `IUnitOfWork`
- `DomainFailure` and its leaves

## Implementing a backend

```dart
class MySkuRepository implements IDeviceTypeRepository {
  @override
  TaskEither<DomainFailure, List<DeviceType>> fetchAll() async => ...;
  // fetchById, create, update, delete, clearAll — failures are values,
  // never thrown.
}
```

An in-memory implementation of every contract is published as
[`sku_catalog_memory`](https://pub.dev/packages/sku_catalog_memory).

## Transactions

`IUnitOfWork` is the seam that makes a multi-write operation atomic, and it is
part of *this* package because the repository contracts take it:

```dart
TaskEither<DomainFailure, DeviceType> create(DeviceType d, {IUnitOfWork? uow});
```

Two things about it are worth knowing before you implement one:

- **Rollback is triggered by a thrown error**, not by a returned failure. A store
  that cannot roll back is `NoOpUnitOfWork`, which just runs the body.
- Because this codebase reports problems as values, the bridging extension
  `runEither` turns a returned `Left` into a throw for the duration of the
  transaction and gives it back afterwards:

```dart
final result = await uow.runEither(() async {
  await removeTheLines().run();      // a Left here ...
  return removeTheSku().run();       // ... means this never commits
});
```

Use cases that write more than once — `DeleteDeviceType`, `DeleteDevice` — take
an optional `unitOfWork` for exactly this reason. Pass a real one and a failure
half-way through leaves nothing behind; pass nothing and the first write stands.

## License

MIT.
