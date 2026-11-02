# Usage

## What you get back

This package presents **FP-style tuples**, not exceptions: repository methods and
use case calls return a **lazy** fpdart `TaskEither<DomainFailure, T>`. Nothing
runs until you `.run()` it, and `.run()` gives you back a
`Future<Either<DomainFailure, T>>`.
`isRight()`/`isLeft()` are methods, and `getOrElse`/`fold` receive the failure.
Why this seam is a tuple rather than a `Future` is recorded in
[`AGENTS.md`](https://github.com/taybiz/sku_catalog/blob/main/AGENTS.md).

The failures are one vocabulary at two levels. `DomainFailure` is the **shared
root**, and it is deliberately **open**: a product's own failure family extends
it, so a consumer composes in the same channel instead of translating into it at
every call into the catalog. `CatalogFailure` is the **closed set** — every way
this package can fail — and is exhaustively switchable.


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

