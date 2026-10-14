# sku_catalog changelog

## 2.0.0

**Breaking.** A serial number is no longer a field on `Instance` — it is a trait
attribute value, and the trait's attribute is marked unique. Two halves of one
fact, and each now lives where it belongs: the *model* is serializable (a trait on
the SKU), the *article* carries one particular number (a value on the instance).

- **Removed:** `Instance.serialNumber`, its `copyWith` parameter, and the
  `serial_number` key in `Instance.toJson()`. Reading or setting the field no
  longer compiles, which is the point — the value has moved into the model. A
  stored record that still carries the key parses without it (the key is ignored
  and is not written back); migrate by moving the value into
  `attribute_values['serial_number']` under the serializable trait below.
- **New:** `TraitAttributeDefinition.isUnique` (`is_unique` on the wire, default
  `false`) — at most one instance in the catalog may hold a value for this
  attribute. A record written before the flag existed reads back as not unique.
- **New:** `SerializableTrait`, the one trait the package names.
  `SerializableTrait.define(traitMeta:, attributeMeta:, key:, displayLabel:)`
  returns the `sku`-scoped `Serializable` trait plus its `serial_number` attribute
  (`string`, `isUnique: true`); ids stay the caller's, like every other id here.
- **New:** `ResolveInstanceSchema` — the schema in scope for one article: the
  traits the instance carries itself plus the traits of the SKU it instantiates,
  each walked up its parent chain. It is what a form for that article renders, and
  what the uniqueness rule measures a write against.
- **New:** `AssertUniqueAttributeValues` (a use case: its contracts through the
  constructor, one `call()`). It resolves the schema through
  `ResolveInstanceSchema` and reads instances through
  `IInstanceRepository.fetchAll()`, so **no repository contract changed** and a
  backend needs nothing new to implement.
- **New:** `TraitAttributeDefinition.valuesMatch(a:, b:)` — the attribute decides
  what counts as the same value: strings trimmed and case-insensitive, numbers by
  value, different types as different values, and an unset value matching nothing.
- **New failure:** `DuplicateAttributeValueFailure`. `DomainFailure` is sealed and
  documented as exhaustively switchable, so a consumer that switches over it must
  add the case — the second half of the major bump.
- **Changed (breaking signatures):** `CreateInstance`, `UpdateInstance` and
  `DuplicateInstance` take their rules as dependencies — the attribute-value check,
  and for update the name rule, now `AssertUniqueInstanceName`, a use case class in
  place of the free function `assertUniqueInstanceName`; `CreateInstance` also
  moves from one positional repository to named `instanceRepository:`. The rule
  fires on create and update; `DuplicateInstance` instead drops every unique value,
  because a copy is a new article — it carries the classification and the
  non-unique values over and can never be refused for a serial number it should not
  have inherited.
- **The use-case layer now holds use cases only.** The pure helpers that were
  misfiled there moved to the domain, where the model's own rules live:
  `IdGenerator`, `newMeta`, the instance-naming rules and the `sequenceTaskEither`
  combinator are now `lib/src/domain/`, re-exported through the same barrel, and
  `attribute_uniqueness.dart` is gone (its rule is
  `TraitAttributeDefinition.valuesMatch`). One use case per file, each a class with
  a single public `call()` — `AssertUniqueAttributeValues` no longer carries a
  second public method for the copy path to reach for.
- **Changed (behaviour):** `CreateInstance` now applies the per-locate unique
  name rule the update path already applied, so a create is no longer a way to
  write a name clash into the store — it was recorded in `BACKLOG.md` as exactly
  that hole. A create that would clash at its locate fails with
  `AlreadyExistsFailure` (nothing is written); the same name at another locate is
  still accepted.
- **Removed:** `slotBoundTraitNames` — the trait-name convention that forced an
  instance's locate to null. It implemented the *caller's* structural rule inside
  `UpdateInstance` and `DuplicateInstance`, which made both depend on the SKU and
  trait repositories purely to compute it, and it sat against this package's own
  scope: a structural convention is the consumer's, and a consumer that wants an
  article with no place of its own leaves the locate unset. The catalog stores the
  place it is handed. With it go `isSlotBound`, `traitNamesForType` and
  `instanceHasTrait`, which existed only for it — `UpdateInstance` drops from five
  constructor dependencies to three, `DuplicateInstance` from four to two.
- **Removed:** the twelve aggregation barrels inside `lib/src/usecases/`
  (`sku_use_cases`, `trait_use_cases`, … `tree_use_cases`). Each re-exported files
  the area barrel already exported, except `sku_association_use_cases.dart`, whose
  three files the area barrel now exports directly — the public surface is
  unchanged, and `usecases.dart` is one alphabetical list.
- **Removed:** the naming **engine** — `defaultNameTemplate`,
  `validateNameTemplate`, `formatName`, `fillFixedTokens`, `nextSequenceStart`,
  `slugifyLocate`, `abbreviateSku`, `resolveAttributeAbbreviation` and the
  `collapseSeparators` helper. Generating a name for a new article from a template,
  a sequence token and a shortened model number is a settings/UI concern, and this
  package's README already said naming conventions are not here — the toolkit
  contradicted it. What stays is what the catalog's own rules need:
  `namesClash` (the case-insensitive comparison behind the per-locate rule) and
  `uniqueCopyName` (the name a copy gets, which is the only one that satisfies that
  rule). `instance_naming.dart` is now `instance_names.dart`, two rules instead of
  ten functions.
- **Changed:** `ResolveEffectiveAttributes.forSku` is its own use case now,
  `ResolveSkuAttributes` — a use case answers through `call()` and nothing else.
  Both questions (one article; one model inside its assemblies) resolve through
  `ResolveAttributeValues`, shared and deliberately **not exported**, so the
  precedence rule still lives in exactly one place and there is no duplicated
  orchestration. The rule is enforced by `test/usecase_shape_test.dart`: one public
  class per file, `call()` its only public method, no bare helpers in the ring.
- **Tests:** `test/attribute_uniqueness_test.dart`, 25 cases: the canonical
  serializable trait, a unique attribute on a trait of the caller's own, on one
  inherited from a parent trait, on a trait the instance carries itself, two
  articles of *different* SKUs sharing one trait, case/whitespace normalization,
  number vs. string, unset values, update-own/swap/reuse-after-delete, the copy
  rule, the JSON round-trip and a legacy record. Gate green: `analyze` clean, 131
  tests passing, `publish-dry` 0 warnings.

## 1.2.0

- Additive: a **labeled, directed relationship edge** — `SkuAssociation`
  (`source_sku_id`, `target_sku_id`, `kind`) — alongside the assembly edge.
  Unlike `SkuComponent`, an association carries no quantity, is never folded by
  the bill of materials, and has no cycle guard, so an ontology of relationships
  (`Smith --edited--> Anthology`, `Jones --contributed_to--> Anthology`) is
  representable as distinct rows without contaminating BOM semantics. New:
  `SkuAssociation`, `ISkuAssociationRepository`, and the `AddSkuAssociation`,
  `FetchAssociationsBySku` (matched on source *or* target, filterable by
  `kind`) and `DeleteSkuAssociation` use cases. Pure addition — every existing
  `call()` is unchanged. Gate green: `analyze` clean, `test` 6 new cases
  passing, `publish-dry` 0 warnings.

## 1.1.0

- Additive: an **injectable id seam**. `newMeta` takes an optional
  `IdGenerator` (`String Function()`, `lib/src/usecases/id_generator.dart`), and
  the four use cases that mint ids internally — `DuplicateSku`,
  `DuplicateInstance`, `AddSkuComponent`, `UpdateSkuComponent` — take an optional
  `idGenerator` constructor parameter, defaulting to the current random UUID v4.
  Signature additions only; every `call()` is unchanged. The rule that an id is
  **opaque** (never parsed, ordered, or arithmetically used) is now written down
  on `Meta.id`, on the typedef, and in the README's new "Identity" section.
  Gate green: `analyze` clean, `test` 8 new cases passing, `publish-dry` 0
  warnings.

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
