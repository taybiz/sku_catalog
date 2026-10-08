# Backlog or Bugs

## Open

Nothing here blocks a publish.

- [ ] **One repository adapter, doctrine wants at least two plus a shared
  contract suite** run against all of them. The in-memory test doubles in
  `test/support/` are one (test-only) implementation; the first real adapter will
  be a consumer's — Circuit Planner's, over SQLite/JSON — and the shared contract
  suite is what proves the two agree.

- [ ] **An injectable id seam**, and a stated rule that ids are opaque. Today
  `newMeta()` hardcodes UUID v4 and is called from five internal write paths
  (duplicate instance, duplicate SKU, add/update assembly edge); every *create*
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

- [ ] Instance composition: a `parentId` on `Instance` so an instance can be an
  assembly of instances (a trough is a coil plus switches; a flipper is a
  mechanism plus a button). Deliberately left out of 0.1.0 — the ask was SKU
  assemblies, which `SkuComponent` already covers.

## Deviations from the Bible (flagged for review — do NOT auto-fix)

`dart-flutter-bible` (`taybiz/dart-flutter-bible`, `docs/01`–`docs/12`) is the
standard this repo is built to. Everything below is a place the code and the
bible disagree. A deviation is **not** automatically a bug in the code: the
bible may itself be wrong, so each one is recorded for a human decision rather
than fixed by the auditor. Nothing here blocks a publish.

**Re-checked 2026-10-08** against the bible at `taybiz/dart-flutter-bible`
`main` (`5680607`, the first revision with the `S.N.N` rule codes). Doctrine has
moved since this list was written, and the move **resolves three items in the
code's favour, rewrites one, and adds one**: the `dart_arch_test` boundary rule
and the pub-workspace mandate are gone (§2.8 now enforces boundaries by lint +
review only; §3.3 "Topology C" sanctions a single-package repo), which clears the
two boundary/cycle items and half the workspace item; and the same revision makes
melos mandatory for a single-package repo — a new gap, **met the same day** (the
`melos:` block in `pubspec.yaml`).

- **Deviation: `import_rules.yaml` + `test/boundary_test.dart`** — the layer
  graph is enforced by the `import_rules` analyzer plugin (wired in
  `analysis_options.yaml`; its rule was proved to fire by planting a wrong-way
  import and reading the reason `dart analyze` reported) plus a
  hand-rolled text-scanning test. `docs/02` ("Package-boundary rules:
  `dart_arch_test`, not melos (and not `import_rules`)") says the gate is a
  `dart_arch_test` test over the **resolved import graph**, and that
  `import_rules` "is at most an optional as-you-type nicety, never the gate".
  Doctrine and repo are flatly opposed; note the repo keeps the plugin honest by
  failing CI at `info` severity (`dart analyze --fatal-infos`), which is the
  part `docs/02` distrusts about it. With one package there are no cross-package
  `package:` URIs for `dart_arch_test`'s boundary assertions to key on, so the
  bible's rule may not fit a single-package repo at all.
  **Resolved 2026-10-08:** the current §2.8 enforces boundaries by lint + review
  only, prescribes no architecture test, and says nothing about `import_rules`
  either way — doctrine moved to the code, so this is no longer a deviation. The
  plugin plus `boundary_test.dart` stay as extra hygiene.

- **Deviation: `test/boundary_test.dart` (cycle-freedom)** — cycle-freedom is
  asserted by area-level import-direction scanning and the plugin's rules, not
  by `shouldBeFreeOfCycles(allFiles(), graph)` over the resolved graph as
  `docs/02` prescribes. Same root cause as the item above — **and resolved with
  it (2026-10-08):** with no `dart_arch_test` rule in the current §2.8, the
  area-level scan is not competing with a prescribed cycle gate.

- **Deviation: `test/support/` — one repository adapter, no shared contract
  suite** — `docs/01` calls the at-least-two-adapter rule "the one we never
  skip" and `docs/05` requires a shared contract suite run against every
  adapter; here there is exactly one (test-only, in-memory) implementation and
  no contract suite. Already an Open item above for the adapter count; listed
  here because `docs/10`'s review checklist asks for it explicitly.

