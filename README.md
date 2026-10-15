# sku_catalog

A catalog model for physical parts: **SKUs with traits and typed attributes,
assemblies of SKUs, the manufacturers behind them, the places they go, and the
instances that instantiate them.**

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
| `Sku` | A **SKU** (product model) made by a manufacturer (`QO120`, `ESP32-S3 IO node rev B`). |
| `Trait` | A **classification attached to a SKU, a place or a manufacturer** — never to an instance: an article holds the *values* of the traits in scope for it. Traits form a tree: `Switch → Breaker` inherits `Switch`'s attributes and may override them. |
| `TraitAttributeDefinition` | A **typed field** a trait contributes: `rated_amps` (number, `A`, required), `gfci` (boolean), `load_type` (enum). |
| `SkuComponent` | An **assembly edge**: this SKU contains *n* of that SKU. |
| `SkuAssociation` | A **labeled relationship edge**: this SKU acts *as `kind`* on that SKU (an author `edited` an anthology). |
| `Manufacturer` | Who makes it, with its own traits (`is_preferred`) and attributes. |
| `Locate` | A **place**, as a tree — a hole, a mount, a rack slot, a room. Places outlive their occupants. |
| `Instance` | An **instance of a SKU**, sitting at exactly one `Locate`, holding the attribute values of the traits in scope for it. |
| `ImageRecord` | A photo attached to a SKU, an instance or a place. |

Two ideas do most of the work:

- **Traits + typed attributes** instead of a wide table per kind of thing. A new
  kind of part is data, not a schema change. Inheritance means the shared
  vocabulary (`Switch`) is written once and the specific case (`Breaker`) adds
  only what differs.
- **SKUs assemble from SKUs.** A panel is a SKU containing breakers, a machine
  is a SKU containing boards and mechanisms. The assembly is a graph with a
  quantity per edge, and a cycle guard that refuses to close a loop.
- **Edges come in two kinds.** `SkuComponent` is *composition* — "this is made
  of N of that", folded into a bill of materials with a cycle guard.
  `SkuAssociation` is *relationship* — "this acts as `kind` on that", a labeled,
  directed edge with no quantity and no fold, for facts that are not parts of a
  build (an author `edited` an anthology).

## Serial numbers, and the one trait the package names

A serial number is not a field on `Instance`. It is an attribute value, because the
two halves are different facts: the **model** is serializable — a trait on the SKU,
which is why the trait is `sku`-scoped — and the **article** carries one particular
number. The package names that pair, because the rule that comes with it is a
catalog invariant rather than your spelling of it:

```dart
final serializable = SerializableTrait.define(
  traitMeta: Meta(id: 'serializable', notes: '', createdAt: now, updatedAt: now),
  attributeMeta: Meta(
    id: 'serializable-serial_number', notes: '', createdAt: now, updatedAt: now,
  ),
);
// serializable.trait        → Trait('Serializable', scope: [TraitScope.sku])
// serializable.serialNumber → TraitAttributeDefinition('serial_number', string, isUnique: true)
```

`isUnique` is a flag **any** trait's attribute can carry — `serializable` is not
special. It means *at most one **holder** in the catalog may hold a value for this
attribute*, and three kinds of record are holders: an **article** (an `Instance`),
the **place** it sits at (a `Locate`) and the **maker** of its model (a
`Manufacturer`). All four records — a SKU too — carry an `attributeValues` map;
being a holder is about the rule, not about the field. A unique value is unique
across all three at once, so a serial number one article holds cannot be minted by
a place or a maker either:

```dart
final rule = AssertUniqueAttributeValues(
  instanceRepository: myInstanceRepository,
  locateRepository: myLocateRepository,
  manufacturerRepository: myManufacturerRepository,
  // An article's schema is its own traits plus its model's, walked up their
  // parent chains; a place's or a maker's is the traits it carries itself.
  resolveInstanceSchema: ResolveInstanceSchema(
    skuRepository: mySkuRepository,
    resolveSchema: myResolveSchema,
  ),
  resolveSchema: myResolveSchema,
);

final createInstance = CreateInstance(
  instanceRepository: myInstanceRepository,
  assertUniqueInstanceName: AssertUniqueInstanceName(myInstanceRepository),
  assertUniqueAttributeValues: rule,
);

// The first article takes SN-0001...
await createInstance(instance: panelWithSerial('SN-0001')).run();
// ...so anything else claiming it is refused with a
// DuplicateAttributeValueFailure rather than stored — a second article, a place,
// or a maker. `CreateLocate`, `UpdateLocate`, `CreateManufacturer` and
// `UpdateManufacturer` are guarded by the same rule, and the reference backend
// hands all of them to you wired (`catalog.createLocate(...)`).
```

A **model** is not a holder: a value on a SKU describes the class, not one article,
so nothing on a SKU is unique in this sense — a model *declares* that serial numbers
exist (that is the trait), and holding one is an article's, a place's or a maker's
act. A place or a maker that carries the trait is checked like an article.

**`Trait.scope` is not consulted here.** A trait records which carrier it is for
(`sku`, `locate`, `manufacturer`) as data; the package stores that and does not gate
on it, so this rule does not either. What makes a clash a clash is a **value under a
key**, not a declared carrier: a place holding a stray value under a key whose
definition is not in its own scope still blocks that value — the number is taken,
and refusing the write is the answer that needs no interpretation.

Values compare the way this package's other identity rules compare them: strings
trimmed and case-insensitively, numbers by value, different types as different
values, and a value nobody set never clashes with anything. A copy is a new
article, so `DuplicateInstance` carries the classification and the non-unique
values over and starts with the unique ones unset — the same shape as the locate a
copy does not inherit. Deleting the holder frees its value.

Nothing new to implement in a backend: the check reads through `fetchAll()` on the
three contracts, so the contracts you already implement are enough, and the rule
stays a use case rather than a storage feature. An adapter that wants it cheap can
index the unique keys on its own side.

## One package

`sku_catalog` is the whole thing — the model **and** the operations:

```yaml
dependencies:
  sku_catalog: ^1.0.0
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
final breaker = Sku(
  meta: Meta(id: 'qo120', notes: '', createdAt: now, updatedAt: now),
  manufacturerId: 'square-d',
  modelNumber: 'QO120',
  traitIds: const ['switch'],
  attributeValues: const {'rated_amps': 20},
);

// A SKU assembled from other SKUs.
final panel = Sku(
  meta: Meta(id: 'pnl-1', notes: '', createdAt: now, updatedAt: now),
  manufacturerId: 'square-d',
  modelNumber: 'QO-16',
  traitIds: const ['panel'],
);

final assembly = SkuComponent(
  meta: Meta(id: 'pnl-1-holds-qo120', notes: '', createdAt: now, updatedAt: now),
  parentSkuId: 'pnl-1',
  childSkuId: 'qo120',
  quantity: 16,
);
```

Resolving what can be said about a SKU is two calls: walk the trait tree, then
merge the attribute definitions.

```dart
final attributes = await ResolveSchema(
  traitRepository: myTraitRepository,
  attributeRepository: myAttributeRepository,
)(traitIds: breaker.traitIds).run();
// attributes: [Rated Amperage (number, A, required)]
```

Adding an assembly edge is guarded — it refuses a loop, and refuses edges to
SKUs that do not exist.

```dart
await AddSkuComponent(
  repository: mySkuComponentRepository,
  skuRepository: mySkuRepository,
)(
  parentSkuId: 'pnl-1',
  childSkuId: 'qo120',
  quantity: 16,
).run();
```

Folding an assembly into the parts a build needs is a separate operation from
resolving attributes: resolution *merges* the layers that describe one thing,
this *folds* the tree that builds one thing.

```dart
final bom = await AggregateBillOfMaterials(
  skuRepository: mySkuRepository,
  skuComponentRepository: mySkuComponentRepository,
)(skuId: panel.meta.id, units: 12).run();
// → one line per distinct part: quantity, level, and whether it is itself
//   an assembly. A part reached by two paths is one line whose quantity is the
//   sum of both; a loop is a failure, not a number.
```

A runnable end-to-end version — on the package's own reference backend — is in
[`example/sku_catalog_example.dart`](example/sku_catalog_example.dart).

## Bringing your own storage

Every aggregate has a repository contract under `lib/src/domain/contracts/`,
re-exported by the front door, and the use cases are typed against those
contracts only — this package ships **no database**. Implement the contracts over
whatever you have (a map, a file, SQLite, an HTTP service, an object store) and
pass them in; the next section is a working one to copy.

```dart
abstract interface class ISkuRepository {
  TaskEither<DomainFailure, List<Sku>> fetchAll();
  TaskEither<DomainFailure, Sku> fetchById({required String id});
  TaskEither<DomainFailure, Sku> create({required Sku sku});
  TaskEither<DomainFailure, Sku> update({required Sku sku});
  TaskEither<DomainFailure, void> delete({required String id});
}
```

**The backend is yours.** The package ships one so the contracts can be read as a
running system — the reference in-memory adapter in the next section — but a
consumer is expected to build their own against these contracts. It is an
example: no durability, no indexes, no concurrency.

Failures are values (`TaskEither<DomainFailure, T>`), never thrown from the
domain. `IUnitOfWork` is the transaction seam for adapters that have one — pass
it to the use cases that write more than once (`DeleteSku`,
`DeleteInstance`) and a failure half-way through rolls back. Repositories do not
take it: the use case that wraps the writes is the one that enrolls them, and a
store just writes. `runEither` takes a
body that returns `Either`; a `Left` is the rollback signal and is handed back
unchanged, so **rollback is a value, not a thrown error** — the adapter undoes the
writes and the domain never throws. `NoOpUnitOfWork` is the honest implementation
for a store that cannot roll back.

## A reference backend

The package also ships a working in-memory backend — **the thing to copy** — so
the contracts and the operations can be read as a running system instead of
imagined:

```yaml
dependencies:
  sku_catalog: ^2.0.0
```

```dart
import 'package:sku_catalog/in_memory.dart';
import 'package:sku_catalog/sku_catalog.dart';

final catalog = InMemoryCatalog();

// Every store is a contract, so it goes anywhere one is expected.
final ISkuRepository skus = catalog.skus;

// Rules and operations come wired, over those stores.
await catalog.createInstance(instance: panel).run();   // the model's rules apply
await catalog.deleteSku(id: 'qo-16').run();            // two writes, one transaction
```

Three things it is worth reading:

- **One `InMemoryTable<T>` per aggregate**, holding `id → toJson()` and decoding
  with `fromJson()` on every read. That is what an adapter should persist: the
  wire form the model round-trips, so a record written before a field existed
  still parses.
- **`InMemoryUnitOfWork`** takes the stores and rolls them back by snapshot when a
  body returns a `Left`; `catalog.unitOfWork` is one built over *every* table the
  catalog holds, which is how a multi-write operation stops depending on someone
  remembering to register a store.
- **`InMemoryCatalog` is a composition root**: it holds the stores, the
  transaction, the schema resolvers and the operations that need more than one
  store, so `catalog.createInstance(...)` is a write with the model's rules
  already in place. The single-store use cases are not wrapped —
  `FetchAllSkus(catalog.skus)` is already one line.

It is an example, not a promise: nothing there is durable, indexed or
isolate-safe, and the unique-value rule *scans* five stores per write because it
reads through `fetchAll()`. A real adapter that wants that cheap indexes the
unique keys on its own side; the rule stays a use case.

## Identity

**An id is an opaque string.** The catalog stores, returns and compares ids and
does nothing else with them: nothing in `lib/` parses an id, sorts on it, or does
arithmetic on it. So the shape is yours — a UUID, an int-backed string, a
prefixed `DEV-0007`.

You already choose the id wherever you hand a whole entity to a create use case
(`CreateSku`, `CreateInstance`, `CreateSkuComponent`, …). For the four operations
that mint ids *internally* — `DuplicateSku`, `DuplicateInstance`,
`AddSkuComponent`, `UpdateSkuComponent` — pass an optional `IdGenerator`
(a `String Function()`) to the constructor; the default is a random UUID v4. The
one rule the catalog asks of a generator is **stability**: whatever an adapter
stores must read back unchanged.

Two deliberate consequences worth knowing:

- **Domain vocabulary stays out.** What a short code on an article means, and
  which trait holds it, are *your* words and *your* screen. The package names
  exactly one pair, `serializable` and its `serial_number`, because `isUnique`
  turns it into a catalog-wide rule rather than a convention (see above).
- **The catalog does not cascade what it cannot see.** `DeleteInstance` removes the
  instance and its images. If something else references instances — a wiring graph,
  a harness, a bill of materials — that is yours to cascade, and the use case
  documents it.

## What is deliberately not here

The package is the instance/SKU heart plus the places and assemblies around it,
and nothing else. Left out on purpose, because they belong to a consumer's
domain: electrical concepts (panels, breakers, slot layouts, ampacity),
topology graphs, reports, import/export bundles, and any naming convention. If
you need one of those, compose it around this package rather than inside it.

The one backend in the repository is the **reference** one
(`package:sku_catalog/in_memory.dart`): it exists to be read and copied, and it is
not a supported storage layer — no durability, no indexes, no concurrency.

## Layout

```
lib/sku_catalog.dart        the front door: the model and the operations
lib/in_memory.dart          the other door: the reference in-memory backend
lib/src/domain/             entities, enums, value objects, failures, contracts
lib/src/usecases/           one file per operation
lib/src/adapters/in_memory/ the reference backend: stores, transaction, catalogue
example/                    a runnable tour, on the reference backend
test/                       the suite (repo-only — not published)
```

`lib/src/` is internal — import one of the two barrels,
`package:sku_catalog/sku_catalog.dart` for the model and its operations or
`package:sku_catalog/in_memory.dart` for the reference backend. The model and the
operations are one dependency and cannot be split; the adapter is a separate door
so a consumer who writes their own storage never carries it.

## Working on it

This package is a **melos workspace of one**: the package *is* the workspace root,
so the scripts live in `pubspec.yaml` under `melos:`. There is no `melos.yaml`.

```bash
dart pub get
dart run melos bootstrap       # once per clone; also writes melos_<pkg>.iml
dart run melos run format      # dart format --output=none --set-exit-if-changed .
dart run melos run analyze     # dart analyze --fatal-infos --fatal-warnings
dart run melos run test        # dart test
dart run melos run publish-dry # dart pub publish --dry-run
```

CI runs exactly those scripts, in that order, so a broken step fails the build
rather than rotting.

### Publishing

```bash
dart pub publish --dry-run
dart pub publish
```

One package, one version, one publish — there is no dependency order to get
right and no sibling constraint to keep in step. Check the file list the dry run
prints: `lib/`, `example/`, `README.md`, `CHANGELOG.md`, `LICENSE` and the
pubspec belong there; `test/support/` does not.

The package holds its structural rules in `test/boundary_test.dart`, and they fail
the build rather than waiting for review:

- **nothing in `lib/` may import or name anything product-specific** — if a
  consumer's word shows up in this API, the boundary has moved without anyone
  deciding it should;
- **the model and the operations may never reach for the adapter** — the reference
  backend ships inside this package, so the model cannot start depending on it;
- **the areas of `lib/src/` may only depend in the allowed direction** — the
  dependency table lives in that test (`domain`, `usecases`, `adapters`, each with
  the packages it may use; `adapters -> usecases -> domain` and never back), and an
  import that crosses an area, or reaches either public entry point from inside
  `lib/src/`, fails. That is the guarantee package separation used to give for
  free; with one package, the suite says it out loud.

## License

MIT — see [LICENSE](LICENSE).
