## Unreleased

- Finished the bible §2.5 parameter pass. The earlier "named params across
  contracts + use cases" refactor left the *helpers* positional; they are named
  now too: every function in `instance_naming.dart`, `sequenceTaskEither`,
  `newMeta` (plus its local hex helper), the private methods in
  `resolve_effective_attributes.dart` and `aggregate_bill_of_materials.dart`,
  and the domain wire-parse helpers (`asStringMap`, `stringListFromWire`,
  `DataType.fromWire`, the entity `_parseOwner`/`_parseScope`). Constructor
  field-formals (a single injected dependency) and the one `List.sort`
  comparator stay positional — §2.5 exempts framework-mandated signatures.
  Signature-only, no behaviour change: gate green (`dart analyze --fatal-infos
  --fatal-warnings` clean, `dart test` passing).
- Audited against the Dart/Flutter Bible (`taybiz/dart-flutter-bible`,
  `docs/01`–`docs/12`) and rebuilt on the Windows lane, Dart 3.13.1. Gate is
  green with zero diagnostics: `dart pub get`, `dart format --output=none
  --set-exit-if-changed .`, `dart analyze --fatal-infos --fatal-warnings`,
  `dart test` (86 tests) and `dart pub publish --dry-run` (0 warnings, 36 KB
  archive). `dart pub outdated` reports nothing outdated. No build, analysis or
  dependency problem was found, so nothing was added to `BACKLOG.md` on that
  account.
- Decided: the bible divergences found by that audit are **recorded, not
  fixed**. Each is a place the code and the bible disagree where the bible may
  itself be wrong (positional/entity-shaped use-case params, the domain's
  rollback bridge in `unit_of_work.dart`, `abstract base` failures,
  `import_rules` as the boundary gate, one package instead of a workspace, no
  `mocktail`). They live in `BACKLOG.md` under "Deviations from the Bible
  (flagged for review)" for a human call.
- Re-checked that deviation list on 2026-10-08 against the bible at
  `taybiz/dart-flutter-bible` `main` (`5680607`). Doctrine had moved: the
  `dart_arch_test` boundary rule and the pub-workspace mandate are gone (§2.8 now
  enforces boundaries by lint + review only; §3.3 "Topology C" sanctions a
  single-package repo), which resolves the two boundary/cycle items and half the
  workspace item, while the same revision makes melos mandatory for a
  single-package repo — a gap this repo does not yet meet. `BACKLOG.md` is the one
  home for the list and now records the resolutions; `AGENTS.md` points at it and
  otherwise carries only the local wiring. Documentation only: no code, dependency or
  CI change, and the gate stays green (`dart analyze --fatal-infos
  --fatal-warnings` clean, `dart test` 86 passing, `dart pub publish --dry-run`
  0 warnings).
- Adopted the bible's §3.3 "Topology C" for this single-package repo: it is now a
  **melos workspace of one**. `melos: ^8.8.0` is a dev dependency and the gate
  lives in a `melos:` block in `pubspec.yaml` (`useRootAsPackage: true`; scripts
  `format`, `analyze`, `test`, `publish-dry`) — no `melos.yaml`. CI now calls
  `dart run melos run <script>` instead of the raw commands, so a script that rots
  fails the build. `*.iml` (written by `melos bootstrap`) is ignored in both
  `.gitignore` and `.pubignore` so it cannot ride into the archive. This closes
  the melos deviation the same-day re-check added; `AGENTS.md`, `README.md` and
  `BACKLOG.md` updated to match. Gate green after the change: `dart run melos run
  analyze` clean, `dart run melos run test` 86 passing, `dart run melos run
  publish-dry` 0 warnings on a committed tree, `dart run melos bootstrap` links
  one package.

## 1.0.0

- **Breaking (major):** the SKU entity is renamed `DeviceType` → `Sku` and the instance
  entity `Device` → `Instance` — the files, classes, contracts, use cases, and the JSON key
  `device_type_id` → `sku_id`. The model and its behaviour are unchanged; only the
  vocabulary. What the package called a device is now an `Instance` (a physical article of a
  `Sku`, at a `Locate`), so a book copy and a breaker instance read the same way. `Locate`
  is untouched. No deprecation shims: adopters rename, in one step. This release also marks
  the vocabulary as final (1.0).
- **Breaking (major):** every repository method and use-case `call()` now takes **named**
  parameters (`fetchById({required String id})`, `create({required Sku sku})`,
  `FetchInstancesByLocate(repo)(locateId: …)`), per bible §2.5. Positional call sites must
  be updated. `IUnitOfWork` is reshaped with them: `runEither({required … body})` returns
  `Future<Either<F, T>>` and the adapter rolls back on a `Left` — rollback is a **value**,
  not a thrown error, so no `throw`/`try`/`catch` remains anywhere in `lib/` (§4.8).
- `DomainFailure` is now a **sealed** hierarchy (§4.2), so a `switch` over it is exhaustive;
  the analyzer runs the **strict** flags (`strict-casts` / `strict-inference` /
  `strict-raw-types`, §9.7).

## 0.2.0

- `AggregateBillOfMaterials`: folds a SKU's assembly tree into a
  `BillOfMaterials` — one `BomLine` per distinct part, with the total quantity a
  build of *n* units needs, the level it sits at, and whether it is itself an
  assembly. The flip side of resolution: `ResolveEffectiveAttributes` merges the
  layers that describe one thing, this folds the tree that builds one thing.
  Quantities multiply down the tree; a part reached by more than one path is one
  line whose quantity is the sum; a loop in the graph reports
  `WouldCreateCycleFailure` rather than a finite quantity that looks plausible.
- `BillOfMaterials` and `BomLine` value objects, exported with the model.
- An assembly edge pointing at a SKU the catalog does not have is still
  reported, with no model number, instead of dropping the part from the build.

## 0.1.0

- First release: the catalog model extracted from Circuit Planner.
- One package: the model and the operations together, with no sibling packages.
  Persistence is the consumer's — implement the repository contracts over
  whatever you have.
- Entities: `Meta`, `Trait`, `TraitAttributeDefinition`, `DeviceType` (SKU),
  `SkuComponent` (assembly edge), `Manufacturer`, `Locate` (place tree),
  `Device` (instance), `ImageRecord`.
- Traits form a tree and carry typed attribute definitions (`DataType`,
  `TraitScope`); `ResolveTraitChain` walks the tree and `ResolveSchema` merges a
  trait set's attributes, child overriding parent.
- `ResolveEffectiveAttributes` resolves values rather than definitions, with
  provenance: the instance, its SKU, an assembly above it, or the definition's
  default.
- SKUs assemble from other SKUs, quantity included, with a cycle guard.
- Repository contracts for every aggregate, plus `IUnitOfWork`.
- Use cases for SKUs, assemblies, manufacturers, places, devices, traits,
  attribute definitions, images and meta.
- The in-memory backend used by this repo's own tests lives in `test/support/`
  and is **not** part of the published package.
