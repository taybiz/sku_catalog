# sku_catalog

A catalog model for physical parts: **SKUs with traits and typed attributes,
assemblies of SKUs, the manufacturers behind them, the places they go, and the
devices that instantiate them.**

Published from `taybiz/sku_catalog`. Built for the case where the things you are cataloguing are real, varied, and
described by different people in different words — electrical gear, pinball
machine boards and mechanisms, lab equipment, whatever you happen to be
assembling and wiring. Nothing in the package is specific to one of those.

## What you get back

This package presents **FP-style tuples**, not exceptions: repository methods and
use case calls return a **lazy** fpdart `TaskEither<DomainFailure, T>`. Nothing
runs until you `.run()` it, and `.run()` gives you back a
`Future<Either<DomainFailure, T>>`.
`isRight()`/`isLeft()` are methods, and `getOrElse`/`fold` receive the failure.
Why this seam is a tuple rather than a `Future` is recorded in
[`AGENTS.md`](https://github.com/taybiz/sku_catalog/blob/main/AGENTS.md).

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

## One package

`sku_catalog` is the whole thing — the model **and** the operations:

```yaml
dependencies:
  sku_catalog: ^0.1.0
```

```dart
import 'package:sku_catalog/sku_catalog.dart';
```

There are no narrow sibling packages to choose between, and no half of it that
makes sense on its own: if you take the domain you take the operations with it.
They are typed against the repository contracts below, and they are what makes
the model usable.

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

Every aggregate has a repository contract under `lib/src/domain/contracts/`,
re-exported by the front door, and the use cases are typed against those
contracts only — this package ships **no** persistence. Implement the contracts
over whatever you have (a map, a file, SQLite, an HTTP service, an object store)
and pass them in.

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

**The backend is yours.** The in-memory implementation in this repo exists for
this package's own tests: it is a test double under `test/support/`, and it is
deliberately excluded from the published package (see `.pubignore`). It is
readable in the repository at
[`test/support/`](https://github.com/taybiz/sku_catalog/tree/main/test/support)
if you want a reference for writing your own — consumers are expected to build
their own backend against these contracts.

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
lib/sku_catalog.dart        the front door: re-exports the model and the operations
lib/src/domain/             entities, enums, value objects, failures, contracts
lib/src/usecases/           one file per operation
example/                    a runnable tour, with a copyable in-memory backend
test/                       the suite
test/support/memory_*.dart  the in-memory test doubles — NOT published
```

`lib/src/` is internal — import the package barrel,
`package:sku_catalog/sku_catalog.dart`. There is exactly one public entry point,
so there is no question of which half to depend on.

## Working on it

Plain Dart commands, no task runner:

```bash
dart pub get
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos --fatal-warnings
dart test
dart pub publish --dry-run     # what pub.dev would see
```

CI runs exactly those, in that order, so a broken step fails the build rather
than rotting.

### Publishing

```bash
dart pub publish --dry-run
dart pub publish
```

One package, one version, one publish — there is no dependency order to get
right and no sibling constraint to keep in step. Check the file list the dry run
prints: `lib/`, `example/`, `README.md`, `CHANGELOG.md`, `LICENSE` and the
pubspec belong there; `test/support/` does not.

The package holds one structural rule, enforced by `test/boundary_test.dart`:
**nothing in `lib/` may import or name anything product-specific, and nothing in
`lib/` may reach for the test doubles.** If a consumer's word shows up in this
API — or the published library starts depending on the in-memory backend — the
boundary has moved without anyone deciding it should.

## License

MIT — see [LICENSE](LICENSE).
