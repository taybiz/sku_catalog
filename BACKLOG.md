# Backlog or Bugs

When complete, mark each off and include a sentence as to disposition.

## Done

- [x] A memory repository package (`packages/sku_catalog_memory`) as a sibling, so
  consumers and tests share one canonical in-memory backend instead of every test
  writing its own. The workspace already has room for it.
  **Disposition:** shipped. Nine contracts, nine implementations, every one
  `MemoryBacked`, and `MemoryUnitOfWork` snapshots and restores the registered
  stores on rollback.

- [x] `ResolveEffectiveAttributes`: resolve a value per attribute key across
  instance -> SKU -> parent SKU (assembly, nearest wins) -> trait default, with
  provenance. `ResolvedAttribute` already carries `source` and `inheritedFrom`
  and nothing produces them yet. `ResolveSchema` returns definitions only.
  **Disposition:** shipped. `ResolveEffectiveAttributes` fills both fields, and
  `TraitAttributeDefinition.defaultValue` gives the bottom rung something to
  read — without it "trait default" had no source. An assembly graph with a cycle
  terminates instead of hanging (the write path refuses to create one; the
  resolver is the backstop).

- [x] Assembly-aware attribute inheritance: a component SKU that does not set a
  value should be able to inherit it from the assembly it is used in.
  **Disposition:** shipped with the item above — `forSku` resolves a component
  inside the assemblies it belongs to, nearest first. When a SKU sits in more
  than one assembly the edge order decides, which is deterministic but not
  meaningful; a caller that cares must resolve per assembly.

## Open

None of these block a 0.1.0 publish. The first two are doctrine deltas found in
the dart-flutter-bible review, not features.

- [ ] **Public seam is `TaskEither`, the bible says `Future<Either>`.** Every
  repository contract and use case `call()` returns a `TaskEither`, so consumers
  build and `run()` chains — exactly what §4 ("Where the chain ends") forbids.
  Fixing it is a signature change across all four packages plus every test, and
  it is a breaking change for anyone who has already imported the published
  package, so it belongs in 0.2.0 (`@deprecated` shims) or in 0.1.0 if it
  happens before the first publish.

- [ ] **One repository adapter, doctrine wants at least two plus a shared
  contract suite** run against all of them. `sku_catalog_memory` is the only
  one. The JSON bundle package below is the natural second adapter, which would
  satisfy both items at once.

- [ ] BOM aggregation: fold a SKU's assembly tree with quantities (how many of
  each part does this build need). Distinct operation from resolution — that is
  a merge, this is a fold.

- [ ] A JSON bundle package: slug-stable export/import of a whole catalog
  (stable ids, referential integrity, idempotent re-import). Currently
  product-side in Circuit Planner.

- [ ] Device composition: a `parentId` on `Device` so a device can be an
  assembly of devices (a trough is a coil plus switches; a flipper is a
  mechanism plus a button). Deliberately left out of 0.1.0 — the ask was SKU
  assemblies, which `SkuComponent` already covers.
