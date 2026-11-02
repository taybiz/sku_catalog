# Reference backend

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

