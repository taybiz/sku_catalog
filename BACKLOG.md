# Backlog or Bugs

## Open

Nothing here blocks a publish.

- [ ] **One repository adapter, doctrine wants at least two plus a shared
  contract suite** run against all of them. The in-memory test doubles in
  `test/support/` are one (test-only) implementation; the first real adapter will
  be a consumer's — Circuit Planner's, over SQLite/JSON — and the shared contract
  suite is what proves the two agree.

- [x] **An injectable id seam, and the rule that ids are opaque** — **done**.
  `newMeta` and the four internal-minting use cases take an optional
  `IdGenerator` (`String Function()`, default UUID v4); `Meta.id` and the README
  state the opacity rule. (The original note said "five internal write paths";
  the real count is four call sites plus the definition — corrected when the item
  was closed. `String` stays: an id is opaque, mapped at the adapter.)

- [ ] A JSON bundle adapter: slug-stable export/import of a whole catalog
  (stable ids, referential integrity, idempotent re-import). Currently
  product-side in Circuit Planner. If it ever becomes a *published* package
  rather than a consumer-side adapter or a second entry point, remember what that
  costs: a path dependency cannot be published, so siblings mean publishing in
  order with version lockstep (see `AGENTS.md`).

- [ ] Instance composition: a `parentId` on `Instance` so an instance can be an
  assembly of instances (a trough is a coil plus switches; a flipper is a
  mechanism plus a button). Deliberately left out of 0.1.0 — the ask was SKU
  assemblies, which `SkuComponent` already covers.

## Deviations from the Bible (flagged for review — do NOT auto-fix)

`dart-flutter-bible` (`taybiz/dart-flutter-bible`, `docs/01`–`docs/12`) is the
standard this repo is built to. Each entry below is a place the code and the bible
disagree. A deviation is **not** automatically a bug in the code: the bible may
itself be wrong, so each one is recorded for a human decision rather than fixed by
the auditor. None blocks a publish.

- **Deviation: `test/support/` — one repository adapter, no shared contract
  suite** — `docs/01` calls the at-least-two-adapter rule "the one we never
  skip" and `docs/05` requires a shared contract suite run against every
  adapter; here there is exactly one (test-only, in-memory) implementation and
  no contract suite. Already an Open item above for the adapter count; listed
  here because `docs/10`'s review checklist asks for it explicitly.

