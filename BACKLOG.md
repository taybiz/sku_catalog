# Backlog or Bugs

## Open

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

## Deviations from the Bible (flagged for review — do NOT auto-fix)

A deviation is a place the code and the bible disagree; it is recorded for a
human decision, not auto-fixed.

- **Deviation: one repository adapter, no shared contract suite** — `docs/01`
  calls the at-least-two-adapter rule "the one we never skip" and `docs/05`
  requires a shared contract suite run against every adapter; here there is
  exactly one (test-only, in-memory) implementation and no contract suite.

