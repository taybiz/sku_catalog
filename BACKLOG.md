# Backlog or Bugs

When complete, mark each off and include a sentence as to disposition.

## Done

- [x] A shared in-memory backend, so consumers and tests share one canonical
  implementation instead of every test writing its own.
  **Disposition:** shipped, then re-shaped. It was bumped around as a package
  (`packages/sku_catalog_memory`); on 2026-09-19 Steve settled it: the backend is
  for *this* repo's testing only — consumers build their own against the
  contracts — so it is now test doubles under `test/support/`, excluded from the
  published archive by `.pubignore`. Nine contracts, nine implementations, every
  one `MemoryBacked`, and `MemoryUnitOfWork` snapshots and restores the
  registered stores on rollback.

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

- [x] The public seam is `TaskEither` where the bible's `docs/04` prescribed
  `Future<Either<...>>`.
  **Disposition:** decided, not fixed — consumers get the tuple. The bible now
  requires every package to *declare* its error style loudly (`docs/04`,
  "Declare the error style, loudly"), so this is compliant rather than a delta:
  the README, the front door's doc comment and this repo's `AGENTS.md` state it in
  the same words. Doctrine moved to meet the code, which is the outcome we wanted.

- [x] BOM aggregation: fold a SKU's assembly tree with quantities (how many of
  each part does this build need). Distinct operation from resolution — that is
  a merge, this is a fold.
  **Disposition:** shipped in 0.2.0 as `AggregateBillOfMaterials` →
  `BillOfMaterials` of `BomLine`s. One line per distinct part, the quantity
  summed over every path the tree reaches it by, the level it sits at, and
  `isAssembly` so a caller can filter to what is bought rather than built.
  Decisions worth keeping: the level is the **shallowest** one, so a part used
  directly and inside a sub-assembly reads as a top-level part; lines are level
  order, then model number, then id, so a report's order does not depend on how
  a store handed its rows back; `units` below one is `InvalidInputFailure`; a
  loop is `WouldCreateCycleFailure`, because a walk with a plain visited set
  answers with a finite quantity that is silently wrong — for a purchase order
  that is worse than a failure; and an edge pointing at a SKU the catalog does
  not have is reported with a null model number rather than dropped from the
  build. Device composition stays out of scope: the ask was SKU assemblies,
  which `SkuComponent` already covers.

## Open

Nothing here blocks a publish.

- [ ] **One repository adapter, doctrine wants at least two plus a shared
  contract suite** run against all of them. The in-memory test doubles in
  `test/support/` are one (test-only) implementation; the first real adapter will
  be a consumer's — Circuit Planner's, over SQLite/JSON — and the shared contract
  suite is what proves the two agree.

- [ ] **An injectable id seam**, and a stated rule that ids are opaque. Today
  `newMeta()` hardcodes UUID v4 and is called from five internal write paths
  (duplicate device, duplicate SKU, add/update assembly edge); every *create*
  use case takes a fully formed entity, so a consumer already chooses the id
  shape there. A `String Function()` typedef passed like `IUnitOfWork`
  (optional, UUID default) covers those five, so a consumer can mint ids their
  own way — int-backed, prefixed (`DEV-0007`), or a custom class's string form.
  Do NOT make the id a type parameter: `String id` appears 50 times across 34
  files, every contract and use case takes one, and the rule everywhere else in
  the industry (Salesforce's 15/18-char strings, Odoo's ints) is a fixed opaque
  id mapped at the adapter. Nothing in `lib/` parses, orders or does arithmetic
  on an id today, so opacity holds — write it down. Decided 2026-09-19: keep
  `String` in 0.1.0; this item is the next additive change.

- [ ] A JSON bundle adapter: slug-stable export/import of a whole catalog
  (stable ids, referential integrity, idempotent re-import). Currently
  product-side in Circuit Planner. If it ever becomes a *published* package
  rather than a consumer-side adapter or a second entry point, remember what that
  costs: a path dependency cannot be published, so siblings mean publishing in
  order with version lockstep (see `AGENTS.md`).

- [ ] Device composition: a `parentId` on `Device` so a device can be an
  assembly of devices (a trough is a coil plus switches; a flipper is a
  mechanism plus a button). Deliberately left out of 0.1.0 — the ask was SKU
  assemblies, which `SkuComponent` already covers.
