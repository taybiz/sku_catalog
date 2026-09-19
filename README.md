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

## The packages

This repo publishes four packages, so you can take exactly as much as you need:

| Package | What it is |
|---|---|
| `sku_catalog` | The front door — re-exports the model **and** the operations. One dependency gets you everything. |
| [`sku_catalog_domain`](https://pub.dev/packages/sku_catalog_domain) | The model and the repository contracts, no operations. |
| [`sku_catalog_usecases`](https://pub.dev/packages/sku_catalog_usecases) | The operations, typed against those contracts. |
| [`sku_catalog_memory`](https://pub.dev/packages/sku_catalog_memory) | An in-memory implementation of every contract, for tests and prototypes. |

```yaml
dependencies:
  sku_catalog: ^0.1.0          # everything…
  # …or pick the halves you want:
  # sku_catalog_domain: ^0.1.0
  # sku_catalog_usecases: ^0.1.0
  # sku_catalog_memory: ^0.1.0
```

```dart
import 'package:sku_catalog/sku_catalog.dart';
```

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
domain. `IUnitOfWork` is the transaction seam for adapters that have one — pass
it to the use cases that write more than once (`DeleteDeviceType`,
`DeleteDevice`) and a failure half-way through rolls back. `runEither` bridges
the two conventions: a returned `Left` becomes the throw that triggers rollback,
and is handed back as a `Left` afterwards. `NoOpUnitOfWork` is the honest
implementation for a store that cannot roll back.

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
.                          the front-door package `sku_catalog` (published)
  lib/sku_catalog.dart     re-exports the model and the operations
  example/                 a runnable tour, with a copyable in-memory backend
  test/
packages/
  sku_catalog_domain/      lib/src/{entities,enums,value_objects,failures,contracts}
  sku_catalog_usecases/    lib/src/  (one file per operation)
  sku_catalog_memory/      lib/src/memory_*_repository.dart
```

The repo root is both the front-door package and the pub workspace root, so
`README.md`, `LICENSE` and `lib/` sit where a reader expects them.

`lib/src/` is internal in every package — import the package barrel.

**One sharp edge, documented rather than discovered:** melos does not treat the
workspace root as a package (`dart run melos list` shows only the three members,
and a `packages:` key in the melos config does not change that). So the
`melos run` scripts cover the members, while the root's own analyze, test and
publish are run explicitly by `melos run verify` — which is what CI calls.
Nothing is silently skipped; add any new root-level check to that script.

## Working on the packages

Melos is a dev dependency of the workspace root, so `dart run melos` works with
nothing installed globally. Each script runs every package in turn, so adding a
sibling package needs no workflow change.

```bash
dart pub get
dart run melos run verify          # format, analyze, test, publish-check — all of it
dart run melos run analyze         # zero diagnostics, fatal on infos and warnings
dart run melos run test
dart run melos run publish-check   # what pub.dev would see, per package
```

### Publishing

Melos publishes unpublished packages, dry-run by default, and `--scope` narrows
it to one member:

```bash
dart run melos publish -n -y                                  # validate every member
dart run melos publish --dry-run --scope=sku_catalog_domain   # validate one
dart run melos publish --scope=sku_catalog_domain             # the real thing
# or without melos:
dart pub -C packages/sku_catalog_domain publish
```

Melos does not see the root package, so `sku_catalog` itself is published from
the root:

```bash
dart pub publish --dry-run     # validate the front-door package
dart pub publish
```

Publish in dependency order — `sku_catalog_domain`, then `sku_catalog_usecases`
and `sku_catalog_memory`, then the root `sku_catalog` — because a published
package's sibling dependency resolves from pub.dev for its consumers. Note that
`dart pub publish --dry-run` does **not** warn when a sibling is not on pub.dev
yet: the ordering is on you.

CI runs those same scripts, so a broken script fails the build rather than
rotting. Note that melos configuration lives in the **workspace root's
`pubspec.yaml`** under `melos:` — melos 8 does not read a `melos.yaml`, and one
that looks authoritative but is ignored is worse than none.

The package holds one structural rule, enforced by `test/boundary_test.dart`:
**nothing in `lib/` may import or name anything product-specific.** If a
consumer's word shows up in this API, the boundary has moved without anyone
deciding it should.

## License

BSD 3-Clause — see [LICENSE](LICENSE).
