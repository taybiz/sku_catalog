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
| `SkuAssociation` | A **labeled relationship edge**: this SKU acts *as `kind`* on that SKU (an author `edited` an anthology). A fact of the models. |
| `InstanceAssociation` | A **labeled relationship edge between two articles**: this article acts *as `kind`* on that one (a copy `bound_with` its neighbour). A fact of particular articles — an edge connects peers. |
| `Manufacturer` | Who makes it, with its own traits (`is_preferred`) and attributes. |
| `Locate` | A **place**, as a tree — a hole, a mount, a rack slot, a room. Places outlive their occupants. |
| `Instance` | An **instance of a SKU**, sitting at exactly one `Locate`, holding the attribute values of the traits in scope for it. |
| `ImageRecord` | A photo attached to a SKU, an instance or a place — **the only home for an entity's images**; none of the three carries a list of its own. |

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
  build (an author `edited` an anthology). `InstanceAssociation` is the same
  relation one level down, between two *articles*, for facts the models cannot
  state at all: this copy is `bound_with` that copy, this copy was `replaced_by`
  that one. Both edges are real and neither store sees the other's rows, and both
  connect peers — an edge names two things of the same level, never a SKU on one
  end and an article on the other.

## Serial numbers, and the one trait the package names

A serial number is not a field on `Instance`. It is an attribute value, because the
two halves are different facts: the **model** is serializable — a trait on the SKU,
which is why the trait is `sku`-scoped — and the **article** carries one particular
number. The package names that pair, because the rule that comes with it is a
catalog invariant rather than your spelling of it: `SerializableTrait.define` mints
that pair — the trait `Serializable`, scoped to SKUs, and its one attribute
`serial_number`, a string marked `isUnique`.

`isUnique` is a flag **any** trait's attribute can carry — `serializable` is not
special. It means *at most one **holder** in the catalog may hold a value for this
attribute*, and three kinds of record are holders: an **article** (an `Instance`),
the **place** it sits at (a `Locate`) and the **maker** of its model (a
`Manufacturer`). All four records — a SKU too — carry an `attributeValues` map;
being a holder is about the rule, not about the field. A unique value is unique
across all three at once, so a serial number one article holds cannot be minted by
a place or a maker either.

The rule is one object, built where your stores are. `AssertUniqueAttributeValues`
takes the three holder repositories and two schema resolvers — an article's schema is
its own traits plus its model's, walked up their parent chains, while a place's or a
maker's is the traits it carries itself — and every write path that can claim a value
takes it: `CreateInstance` and `UpdateInstance`, and the same rule guards
`CreateLocate`, `UpdateLocate`, `CreateManufacturer` and `UpdateManufacturer`. The
first article to take `SN-0001` gets it; anything else claiming it — a second article,
a place, a maker — is refused with a `DuplicateAttributeValueFailure` instead of being
stored, and the reference backend hands you all of those paths already wired.

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
stays a use case rather than a storage feature.

## One package

`sku_catalog` is the whole thing — the model **and** the operations:

```dart
import 'package:sku_catalog/sku_catalog.dart';
```

There are no narrow sibling packages to choose between, and no half of it that
makes sense on its own: if you take the domain you take the operations with it.
They are typed against the repository contracts below, and they are what makes
the model usable.

## Quick start

There is no wiring ceremony to learn: define the traits and their typed attributes,
build SKUs that carry them, then construct the operations over your stores. The
runnable version is in
[`example/sku_catalog_example.dart`](https://github.com/taybiz/sku_catalog/blob/main/example/sku_catalog_example.dart)
— it implements two contracts over its own little store and wires `CreateSku`,
`AddSkuComponent` and the rest to them, so `dart run example/sku_catalog_example.dart`
works from the archive as well as from a clone.

Resolving what can be said about a SKU is two calls: walk the trait tree, then
merge the attribute definitions. `ResolveSchema(traitRepository:,
attributeRepository:)` answers for a set of traits, and `ResolveInstanceSchema` adds
the model's own to an article's.

Adding an assembly edge is guarded — it refuses a loop, and refuses edges to
SKUs that do not exist. `AddSkuComponent(repository:, skuRepository:, unitOfWork:)`
reads the graph the guard walks, which is why it takes the transaction.

Folding an assembly into the parts a build needs is a separate operation from
resolving attributes: resolution *merges* the layers that describe one thing,
this *folds* the tree that builds one thing.
`AggregateBillOfMaterials(skuRepository:, skuComponentRepository:)(skuId:, units:)`
answers one line per distinct part — quantity, level, and whether the part is itself
an assembly. A part reached by two paths is one line whose quantity is the sum of
both, and a loop is a failure rather than a number.

## Bringing your own storage

Every aggregate has a repository contract under `lib/src/domain/contracts/`,
re-exported by the front door, and the use cases are typed against those
contracts only — this package ships **no database**. Implement the contracts over
whatever you have (a map, a file, SQLite, an HTTP service, an object store) and
pass them in; the next section is a working one to copy.

```dart
abstract interface class ISkuRepository {
  TaskEither<DomainFailure, List<Sku>> fetchAll();
  TaskEither<DomainFailure, List<Sku>> fetchByManufacturer({
    required String manufacturerId,
  });
  TaskEither<DomainFailure, Sku> fetchById({required String id});
  TaskEither<DomainFailure, Sku> create({required Sku sku});
  TaskEither<DomainFailure, Sku> update({required Sku sku});
  TaskEither<DomainFailure, void> delete({required String id});
}
```

**The backend is yours.** The package publishes none: a working one lives in this
repository (the next section) so the contracts can be read as a running system,
and a consumer is expected to build their own against these contracts. That
reference is an example: no durability, no indexes, no concurrency.

Failures are values (`TaskEither<DomainFailure, T>`), never thrown from the
domain. `UnitOfWork` is the transaction seam: a function an adapter writes as a
closure over its client, checked where it is handed over. Its body returns
`Either`, and a `Left` is the rollback signal handed back unchanged, so **rollback
is a value, not a thrown error** — the adapter undoes the writes and the domain
never throws.

It is a **required constructor dependency** of every operation whose correctness
depends on more than one store interaction being one step: the three cascading
deletes (`DeleteSku`, `DeleteInstance`, `DeleteInstanceAndUnusedSku`), `DeleteTrait`,
`UpdateSkuComponent`, the six rule-carrying create/update paths (instance, locate,
manufacturer) and the three edge writers. There is no optional form and no default,
because the optional one had an unsafe shape: `DeleteInstance(id: x)` compiled,
defaulted to a no-op, and silently meant *no transaction*. A store that cannot roll
back is wired with `noOpUnitOfWork` — a statement the composition root makes out
loud. An operation that composes others owns the only transaction, and its pieces
are wired with the no-op so nothing nests. Repositories never take it: the use case
that wraps the writes enrolls them, and a store just writes.

## A reference backend (in the repository)

The package ships **no storage**. What it carries instead is a working in-memory
backend in this repository — **the thing to copy** — so the contracts and the
operations can be read as a running system instead of imagined. It is *not* in
the published archive: `.pubignore` keeps `lib/in_memory.dart` and
`lib/src/adapters/` out, because a domain package that ships one storage story makes
that story look like its own. (`example/` ships: it runs on the published import
alone, with its own store.)

```yaml
dependencies:
  sku_catalog: ^3.0.0        # the model and the operations
```

In a clone of this repository, a second barrel reaches the reference backend —
`package:sku_catalog/in_memory.dart`, and not from pub.dev, because the backend is
not published. Every store it holds *is* a contract, so it goes anywhere one is
expected, and the rules and operations come wired over those stores:
`catalog.createInstance(...)` applies the model's rules, and `catalog.deleteSku(...)`
does its two writes in one transaction.

Three things it is worth reading — in
[`lib/src/adapters/in_memory/`](https://github.com/taybiz/sku_catalog/tree/main/lib/src/adapters/in_memory),
which is where the published package stops:

- **One `InMemoryTable<T>` per aggregate**, holding `id → toJson()` and decoding
  with `fromJson()` on every read. That is what an adapter should persist: the
  wire form the model round-trips, so a record written before a field existed
  still parses.
- **`inMemoryUnitOfWork`** takes the stores and returns a `UnitOfWork` that rolls
  them back by snapshot when a body answers `Left`; `catalog.unitOfWork` is one
  built over *every* table the catalog holds, which is how a multi-write operation
  stops depending on someone remembering to register a store.
- **`InMemoryCatalog` is a composition root**: it holds the stores, the
  transaction, the schema resolvers and the operations that need more than one
  store, so `catalog.createInstance(...)` is a write with the model's rules
  already in place. The single-store use cases are not wrapped —
  `FetchAllSkus(catalog.skus)` is already one line.

It is an example, not a promise: nothing there is durable, indexed or
isolate-safe. The rules read what they need — one locate group, one maker's models,
one model's articles — but the unique-value rule reads every holder, which is the
read a backend has to serve cheaply if a catalog ever grows that far.

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

**A model number is the maker's production number, unique against the maker.**
`AssertUniqueModelNumber` keeps that rule on the SKU write paths, so a second model
from the same `manufacturerId` cannot take a number another model already holds, and
an edit that keeps its own number is not a clash with itself. The comparison is
**exact** — a production number is an identifier, so `QO120` and `qo120` are two
different numbers, unlike an instance name, which the per-locate rule compares
case-insensitively because it is prose a person reads. `DuplicateSku` mints the next
free "(copy)" number rather than being refused. What a maker *calls* a thing, when
that differs from its production number, is a different fact: optional, with no rule
to keep, so it is a trait you declare rather than a field here.

Two deliberate consequences worth knowing:

- **Domain vocabulary stays out.** What a short code on an article means, and
  which trait holds it, are *your* words and *your* screen. The package names
  exactly one pair, `serializable` and its `serial_number`, because `isUnique`
  turns it into a catalog-wide rule rather than a convention (see above).
- **The catalog cascades only what it owns.** `DeleteInstance` removes the article,
  its images and the `InstanceAssociation` edges that name it — everything the
  catalog itself stores *about* that article. If something else references instances
  — a wiring graph, a harness, a bill of materials — that is yours to cascade, and
  the use case documents it.
- **A model that exists only for its articles goes with the last one.**
  `DeleteInstanceAndUnusedSku` is for a book's *edition*: nobody catalogues it, its
  copies only instantiate it, and two copies share it — so the model is removed when
  nothing else names it, not when the first copy leaves. There is no flag for that:
  choosing the operation is the assertion.

## What is deliberately not here

The package is the instance/SKU heart plus the places and assemblies around it,
and nothing else. Left out on purpose, because they belong to a consumer's
domain: electrical concepts (panels, breakers, slot layouts, ampacity),
topology graphs, reports, import/export bundles, and any naming convention. If
you need one of those, compose it around this package rather than inside it.

The one backend in the repository is the **reference** one
(`lib/in_memory.dart`, repo-only): it exists to be read and copied, and it is not
a supported storage layer — no durability, no indexes, no concurrency.

## Layout

```
lib/sku_catalog.dart        the front door: the model and the operations
lib/in_memory.dart          the other door: the reference in-memory backend
                            (repo-only — not in the published archive)
lib/src/domain/             entities, enums, value objects, failures, contracts
lib/src/usecases/           one file per operation
lib/src/adapters/in_memory/ the reference backend: stores, transaction, catalogue
                            (repo-only)
example/                    a runnable tour of the contracts, on its own tiny store
test/                       the suite (repo-only — not published)
```

`lib/src/` is internal — import the barrel. `package:sku_catalog/sku_catalog.dart`
is the published package: the model and its operations, one dependency, and it
cannot be split. In a clone there is a second barrel,
`package:sku_catalog/in_memory.dart`, for the reference backend that the suite and
the tour run on — a consumer writing their own storage never carries it, because
it is not in the archive.

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
prints: the pubspec, `lib/` (minus the adapter ring and its door), `README.md`,
`CHANGELOG.md`, `LICENSE` and `example/` belong there; `test/`,
`lib/in_memory.dart`, `lib/src/adapters/`, `AGENTS.md` and `BACKLOG.md` do not.

The package holds its structural rules in `test/boundary_test.dart`, and they fail
the build rather than waiting for review:

- **nothing in `lib/` may import or name anything product-specific** — if a
  consumer's word shows up in this API, the boundary has moved without anyone
  deciding it should;
- **the model and the operations may never reach for the adapter** — the reference
  backend lives in this repository (outside the published archive), so the model
  cannot start depending on it;
- **the areas of `lib/src/` may only depend in the allowed direction** — the
  dependency table lives in that test (`domain`, `usecases`, `adapters`, each with
  the packages it may use; `adapters -> usecases -> domain` and never back), and an
  import that crosses an area, or reaches either public entry point from inside
  `lib/src/`, fails. That is the guarantee package separation used to give for
  free; with one package, the suite says it out loud.

## License

MIT — see [LICENSE](LICENSE).
