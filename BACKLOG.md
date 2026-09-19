# Backlog or Bugs

When complete, mark each off and include a sentence as to disposition.

- [ ] `ResolveEffectiveAttributes`: resolve a value per attribute key across
  instance -> SKU -> parent SKU (assembly, nearest wins) -> trait default, with
  provenance. `ResolvedAttribute` already carries `source` and `inheritedFrom`
  and nothing produces them yet. `ResolveSchema` returns definitions only.

- [ ] BOM aggregation: fold a SKU's assembly tree with quantities (how many of
  each part does this build need). Distinct operation from resolution — that is
  a merge, this is a fold.

- [ ] Assembly-aware attribute inheritance: a component SKU that does not set a
  value should be able to inherit it from the assembly it is used in.

- [ ] A memory repository package (`packages/sku_catalog_memory`) as a sibling,
  so consumers and tests share one canonical in-memory backend instead of every
  test writing its own. The workspace already has room for it.

- [ ] A JSON bundle package: slug-stable export/import of a whole catalog
  (stable ids, referential integrity, idempotent re-import). Currently
  product-side in Circuit Planner.

- [ ] Device composition: a `parentId` on `Device` so a device can be an
  assembly of devices (a trough is a coil plus switches; a flipper is a
  mechanism plus a button). Deliberately left out of 0.1.0 — the ask was SKU
  assemblies, which `SkuComponent` already covers.
