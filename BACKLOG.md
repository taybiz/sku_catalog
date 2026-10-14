# Backlog or Bugs

## Open

- [ ] **Twelve aggregation barrels inside `lib/src/usecases/`** (`sku_use_cases`,
  `trait_use_cases`, `locate_use_cases`, …, each re-exporting its neighbours) are
  redundant with the area barrel, which already exports those files individually —
  every one is imported by `usecases.dart` alone. Delete them and their export
  lines, or state what the grouping buys now that the area barrel covers it.

- [ ] **Two use cases carry a second public method** beside `call()`:
  `AggregateBillOfMaterials.explode` and `ResolveEffectiveAttributes.forSku`. Each
  is a distinct operation with its own inputs, so each wants its own use case class
  with one `call()`; the shared resolution they sit on is what needs splitting
  first, not the method.

- [ ] **`isUnique` is enforced on the instance layer only.** `CreateInstance`,
  `UpdateInstance` and `DuplicateInstance` assert it against instances; a value
  written on a SKU, a `Locate` or a `Manufacturer` — all three hold
  `attributeValues` — is not asserted, because uniqueness is a statement about
  articles. If a unique attribute on a place or a maker is wanted, the same
  `AssertUniqueAttributeValues` shape extends to those write paths.

- [ ] **One repository adapter, doctrine wants at least two plus a shared
  contract suite** run against all of them. The in-memory test doubles are one
  (test-only) implementation; the first real adapter will be Circuit Planner's,
  over SQLite/JSON, and the shared contract suite proves the two agree.

- [ ] A JSON bundle adapter: slug-stable export/import of a whole catalog
  (stable ids, referential integrity, idempotent re-import). Currently
  product-side in Circuit Planner.

- [ ] Instance composition: a `parentId` on `Instance` so an instance can be an
  assembly of instances (a trough is a coil plus switches; a flipper is a
  mechanism plus a button).

## Deviations from the Bible (flagged for review — do NOT auto-fix)

A deviation is a place the code and the bible disagree; it is recorded for a
human decision, not auto-fixed.

- **Deviation: one repository adapter, no shared contract suite** — `docs/01`
  calls the at-least-two-adapter rule "the one we never skip" and `docs/05`
  requires a shared contract suite run against every adapter; here there is
  exactly one (test-only, in-memory) implementation and no contract suite.

