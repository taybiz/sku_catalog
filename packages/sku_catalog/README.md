# sku_catalog

A catalog model for physical parts: **SKUs with traits and typed attributes,
assemblies of SKUs, the manufacturers behind them, the places they go, and the
devices that instantiate them.**

Published from `taybiz/sku_catalog`. Built for the case where the things you are cataloguing are real, varied, and
described by different people in different words — electrical gear, pinball
machine boards and mechanisms, lab equipment, whatever you happen to be
assembling and wiring. Nothing in the package is specific to one of those.

## The model in one screen

| Concept | What it is |
|---|---|
| `DeviceType` | A **SKU** — a product model made by a manufacturer (`QO120`, `ESP32-S3 IO node rev B`). |
| `Trait` | A **classification attached to a SKU, a device, a place or a manufacturer**. Traits form a tree: `Switch → Breaker` inherits `Switch`'s attributes and may override them. |
| `TraitAttributeDefinition` | A **typed field** a trait contributes: `rated_amps` (number, `A`, required), `gfci` (boolean), `load_type` (enum). |
| `SkuComponent` | An **assembly edge**: this SKU contains *n* of that SKU. |
| `Manufacturer` | Who makes it, with its own traits (`is_preferred`) and attributes. |
| `Locate` | A **place**, as a tree — a hole, a mount, a rack slot, a room. Places outlive their occupants. |
| `Device` | An **instance of a SKU**, sitting at exactly one `Locate`, with its own traits and attribute values. |
| `ImageRecord` | A photo attached to a SKU, a device or a place. |

Two ideas do most of the work:

- **Traits + typed attributes** instead of a wide table per kind of thing. A new
  kind of part is data, not a schema change. Inheritance means the shared
  vocabulary (`Switch`) is written once and the specific case (`Breaker`) adds
  only what differs.
- **SKUs assemble from SKUs.** A panel is a SKU containing breakers, a machine
  is a SKU containing boards and mechanisms. The assembly is a graph with a
  quantity per edge, and a cycle guard that refuses to close a loop.

## Install

```yaml
dependencies:
  sku_catalog: ^0.1.0
```

```dart
import 'package:sku_catalog/sku_catalog.dart';
```

Need the model without the operations (implementing your own backend, or your
own application layer)? Import `package:sku_catalog/sku_catalog_domain.dart`.

## Quick start

```dart
final now = DateTime.now().toUtc().toIso8601String();

// A classification, and the typed field it contributes.
final switchTrait = Trait(
  meta: Meta(id: 'switch', notes: '', createdAt: now, updatedAt: now),
  name: 'Switch',
  scope: const [TraitScope.sku],
);

final ratedAmps = TraitAttributeDefinition(
  meta: Meta(id: 'switch-rated_amps', notes: '', createdAt: now, updatedAt: now),
  traitId: 'switch',
  key: 'rated_amps',
  displayLabel: 'Rated Amperage',
  dataType: DataType.number,
  unit: 'A',
  isRequired: true,
);

// A SKU carrying that trait, and the value for it.
final breaker = DeviceType(
  meta: Meta(id: 'qo120', notes: '', createdAt: now, updatedAt: now),
  manufacturerId: 'square-d',
  modelNumber: 'QO120',
  traitIds: const ['switch'],
  attributeValues: const {'rated_amps': 20},
);

// A SKU assembled from other SKUs.
final panel = DeviceType(
  meta: Meta(id: 'pnl-1', notes: '', createdAt: now, updatedAt: now),
  manufacturerId: 'square-d',
  modelNumber: 'QO-16',
  traitIds: const ['panel'],
);

final assembly = SkuComponent(
  meta: Meta(id: 'pnl-1-holds-qo120', notes: '', createdAt: now, updatedAt: now),
  parentDeviceTypeId: 'pnl-1',
  childDeviceTypeId: 'qo120',
  quantity: 16,
);
```

Resolving what can be said about a SKU is two calls: walk the trait tree, then
merge the attribute definitions.

```dart
final attributes = await ResolveSchema(
  traitRepository: myTraitRepository,
  attributeRepository: myAttributeRepository,
)(breaker.traitIds).run();
// attributes: [Rated Amperage (number, A, required)]
```

Adding an assembly edge is guarded — it refuses a loop, and refuses edges to
SKUs that do not exist.

```dart
await AddSkuComponent(
  repository: mySkuComponentRepository,
  deviceTypeRepository: myDeviceTypeRepository,
)(
  parentDeviceTypeId: 'pnl-1',
  childDeviceTypeId: 'qo120',
  quantity: 16,
).run();
```

A runnable end-to-end version — with a small in-memory backend you can copy —
is in [`example/sku_catalog_example.dart`](example/sku_catalog_example.dart).

## Bringing your own storage

Every aggregate has a repository contract in `sku_catalog_domain.dart`, and the
use cases are typed against those contracts only — this package ships **no**
persistence. Implement the contracts over whatever you have (a map, a file,
SQLite, an HTTP service, an object store) and pass them in.

```dart
abstract interface class IDeviceTypeRepository {
  TaskEither<DomainFailure, List<DeviceType>> fetchAll();
  TaskEither<DomainFailure, DeviceType> fetchById(String id);
  TaskEither<DomainFailure, DeviceType> create(DeviceType deviceType, {IUnitOfWork? uow});
  TaskEither<DomainFailure, DeviceType> update(DeviceType deviceType, {IUnitOfWork? uow});
  TaskEither<DomainFailure, void> delete(String id, {IUnitOfWork? uow});
  TaskEither<DomainFailure, void> clearAll({IUnitOfWork? uow});
}
```

Failures are values (`TaskEither<DomainFailure, T>`), never thrown from the
domain. `IUnitOfWork` is the optional transaction seam for adapters that have
one.

Two deliberate consequences worth knowing:

- **Domain vocabulary stays out.** Which trait means "this SKU lives inside
  another device", and which attribute holds a short code, are *your* words —
  they are parameters (`slotBoundTraitNames`, `resolveAttributeAbbreviation`),
  not constants.
- **The catalog does not cascade what it cannot see.** `DeleteDevice` removes the
  device and its images. If something else references devices — a wiring graph,
  a harness, a bill of materials — that is yours to cascade, and the use case
  documents it.

## What is deliberately not here

The package is the device/SKU heart plus the places and assemblies around it,
and nothing else. Left out on purpose, because they belong to a consumer's
domain: electrical concepts (panels, breakers, slot layouts, ampacity),
topology graphs, reports, import/export bundles, and any naming convention. If
you need one of those, compose it around this package rather than inside it.

## Layout

```
lib/
  sku_catalog.dart            everything (model + use cases)
  sku_catalog_domain.dart     the model alone
  src/
    domain/
      entities/               Meta, Trait, TraitAttributeDefinition, DeviceType,
                              SkuComponent, Manufacturer, Locate, Device,
                              ImageRecord
      enums/                  DataType, TraitScope, ImageOwner
      value_objects/          ResolvedAttribute, DeviceReportProperty
      failures/               DomainFailure and its leaves
      contracts/              the I*Repository contracts + IUnitOfWork
    usecases/                 SKUs, assemblies, manufacturers, places, devices,
                              traits, attribute definitions, images, meta
```

`lib/src/` is internal — import the two barrels above.

## Working on the package

```bash
dart pub get
melos run analyze   # dart analyze --fatal-infos --fatal-warnings, zero diagnostics
melos run test
melos run publish-check
```

The package holds one structural rule, enforced by `test/boundary_test.dart`:
**nothing in `lib/` may import or name anything product-specific.** If a
consumer's word shows up in this API, the boundary has moved without anyone
deciding it should.

## License

BSD 3-Clause — see [LICENSE](LICENSE).
