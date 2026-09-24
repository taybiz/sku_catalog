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

## Deviations from the Bible (flagged for review — do NOT auto-fix)

`dart-flutter-bible` (`staylorx/dart-flutter-bible`, `docs/01`–`docs/12`) is the
standard this repo is built to. Everything below is a place the code and the
bible disagree. A deviation is **not** automatically a bug in the code: the
bible may itself be wrong, so each one is recorded for a human decision rather
than fixed by the auditor. Nothing here blocks a publish.

- **Deviation: `lib/src/domain/contracts/` (all nine repository contracts)** —
  methods take **positional** parameters (`fetchById(String id)`,
  `create(DeviceType deviceType, …)`, `delete(String id, …)`) and pass a whole
  entity into `create`/`update`. `docs/02` ("Dart parameter style") says named
  parameters always, "sole exceptions: a single positional `ref` or `message`",
  and `docs/04` ("business params, not cargo") bans cargo objects. The bible's
  own `IAccountRepository` sample uses `{required String id}`. Diverges in both
  directions at once — positional *and* entity-shaped.

- **Deviation: `lib/src/usecases/*.dart` (every use case)** — `call()` is
  positional: `call(String id)`, `call(DeviceType deviceType)`,
  `forSku(String deviceTypeId)`. Same `docs/02`/`docs/04` rules as above. The
  entity-shaped ones (`CreateDeviceType(DeviceType deviceType)`) are the cargo
  pattern `docs/04` names and bans by example.

- **Deviation: `lib/src/domain/contracts/unit_of_work.dart`** —
  `UnitOfWorkEither.runEither` does `throw _Rollback<F>(failure)` inside
  `run()` and recovers with `on _Rollback<F> catch`. That is a hand-rolled
  `throw` + `try/catch` **inside the domain package**, where `docs/04` ("the
  exception rule, stated once, loudly") and `docs/10` allow only `tryCatch`
  around a third-party call at an adapter boundary, or the UI ring. The gap is
  real — a transactional store rolls back on a *thrown* error while this
  codebase reports failure as a value, and the bible sanctions no bridge — so
  the bible may be wrong here rather than the code.

- **Deviation: `lib/src/domain/failures/catalog_failures.dart`** —
  `DomainFailure` is `abstract base`, not `sealed`. `docs/04` requires failure
  hierarchies to be **closed** ("abstract base + final/`sealed` leaves where the
  language allows — a `switch` over them must be exhaustive"). The in-file
  comment argues the opposite: a sealed root cannot be extended from a product's
  own library, and this type is the shared root every product's failure family
  descends from. Exhaustiveness and extensibility are genuinely in tension for a
  shared package; doctrine may need a carve-out.

- **Deviation: `analysis_options.yaml` (`prefer_initializing_formals: false`)** —
  a linter rule is disabled in the config file. `docs/02` ("Suppression is
  per-line or nothing") says never disable a rule in `analysis_options.yaml`;
  the offending lines should carry `// ignore: <rule>` with a reason, or the
  code should change. The comment above it records the intent (`: _repository =
  repository` reads better at the call site) — intent is not a mechanism the
  bible recognises.

- **Deviation: `analysis_options.yaml` (no `analyzer: language:` block)** —
  `docs/09` step 8 says to wire "lints, **strict**, `public_member_api_docs`,
  `todo: error`" at the root; `lints: recommended` is on and `todo: error` is
  set, but no `strict-casts` / `strict-inference` / `strict-raw-types` is.
  `docs/02` never names which strict flags it means, so the requirement is
  underspecified — flagging it rather than guessing a setting.

- **Deviation: repo root / `pubspec.yaml` (single package, no `workspace:`)** —
  `docs/03` and the `docs/09` bootstrap checklist mandate a pub workspace of
  `*_domain` + `*_usecases` + ≥2 `*_datasource_*` + the app. Here there is one
  published package on purpose, argued in `AGENTS.md` ("One package, on
  purpose"): a published package may not carry a `path:` dependency, so any
  split means publishing siblings in dependency order with version lockstep and
  no client-side check that catches a miss. The bible's checklist assumes
  unbounded publication; for a package whose consumers implement their own
  backend, the bible may be wrong.

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

- **Deviation: `test/boundary_test.dart` (cycle-freedom)** — cycle-freedom is
  asserted by area-level import-direction scanning and the plugin's rules, not
  by `shouldBeFreeOfCycles(allFiles(), graph)` over the resolved graph as
  `docs/02` prescribes. Same root cause as the item above.

- **Deviation: `test/` (all twelve test files) — no `mocktail`** — the
  application-layer tests run against the real in-memory doubles instead of
  mocking the repository interfaces. `docs/06` ("Where tests live" layer matrix)
  prescribes `mocktail` at the use-case seam, while the same section's mocktail
  rules say to *prefer* real in-memory doubles where one exists. The bible
  contradicts itself here; the repo took the second half.

- **Deviation: `test/support/` — one repository adapter, no shared contract
  suite** — `docs/01` calls the at-least-two-adapter rule "the one we never
  skip" and `docs/05` requires a shared contract suite run against every
  adapter; here there is exactly one (test-only, in-memory) implementation and
  no contract suite. Already an Open item above for the adapter count; listed
  here because `docs/10`'s review checklist asks for it explicitly.

- **Deviation: `pubspec.yaml` (`equatable: ^3.0.0`)** — the stack table in
  `docs/00-compact`/`docs/04` pins `equatable ^2.x`. The bible pin looks stale
  rather than the dependency wrong: 3.x is current, `dart pub outdated` reports
  nothing outdated, and the entities compile and test clean on it.

- **Deviation: `example/` (singular)** — `docs/02` ("Code placement") and
  `docs/03` call a published package's example directory `examples/`. Only the
  name diverges; the directory exists, is analyzer- and format-covered, and is
  shipped in the archive.
