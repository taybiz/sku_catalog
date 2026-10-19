# sku_catalog changelog

## 3.0.0

**Breaking.** Two changes, and each is one half of the same idea: the edge model
gains the level it was missing, and the package stops publishing storage.

**An article can be related to another article.** `SkuComponent` and
`SkuAssociation` both name a SKU on either end, so every relationship the model
could state was a relationship of the *models*. A fact true of particular
articles — this copy is bound with that copy, this copy was replaced by that one —
had nowhere to live, and stating it on the models made it false for every other
article of them.

- **New:** `InstanceAssociation` (`meta`, `sourceInstanceId`, `targetInstanceId`,
  `kind`; `source_instance_id` / `target_instance_id` / `kind` on the wire) — the
  article-level sibling of `SkuAssociation`, with no quantity, no fold and no
  cycle guard. The two are **axes, not alternatives**: a fact of the models
  belongs on the SKUs, a fact of two particular articles belongs here, and neither
  store sees the other's rows.
- **New:** `IInstanceAssociationRepository` (`fetchAll`, `fetchByInstance`,
  `fetchById`, `create`, `delete`) and the use cases `AddInstanceAssociation`,
  `DeleteInstanceAssociation` and `FetchAssociationsByInstance`.
  `AddInstanceAssociation` refuses a blank kind, a missing article and a
  self-edge: **an edge connects peers**, and an article is not its own peer. No
  new `DomainFailure` leaf was needed — both refusals are `InvalidInputFailure`,
  the leaf the SKU-level edge already returns for a blank kind — so a consumer's
  exhaustive switch over the sealed hierarchy still compiles.
- **Changed (breaking signature):** `DeleteInstance` takes a required
  `instanceAssociationRepository` and deletes the edges that name the article
  along with its images, in one transaction. Deleting an article used to leave
  rows pointing at an id nothing held; the catalog's own data is now consistent
  with itself. References *outside* the catalog (a wiring graph, a bill of
  materials) remain the consumer's to cascade, as before.
- **New (reference backend):** `InMemoryInstanceAssociationRepository`, wired into
  `InMemoryCatalog` as `instanceAssociations`, registered in its transaction and
  exposed as `catalog.addInstanceAssociation` — a write that carries rules, so it
  is wrapped the way `catalog.createInstance` is.
- **Closed:** the BACKLOG item *"the edge model has no instance endpoints"*. The
  other route it named — generalizing both endpoints into a sealed node reference
  — was not taken: it changes every existing wire key, and it would erase the
  class/token distinction exactly where the type system is the thing enforcing it.

**A model number is the maker's production number.** The field's doc has always
claimed "unique per manufacturer" and nothing enforced it; it does now. The field
beside it, which was doing a *different* job under a name that read as a variant of
it, is gone.

- **New:** `AssertUniqueModelNumber` — a model number is unique against its
  `manufacturerId`, compared **exactly** (`QO120` is not `qo120`; case-insensitivity
  is `namesClash`, for instance names, which are prose). `CreateSku` and `UpdateSku`
  take it as a required dependency, the update path excluding the model's own id so
  an edit that keeps its number is not a clash with itself, and `InMemoryCatalog`
  wires it as `catalog.createSku` / `catalog.updateSku`.
- **New:** `uniqueCopyModelNumber` — `DuplicateSku` mints the next free "(copy)"
  number for its maker instead of reusing the original's, the same choice
  `DuplicateInstance` makes with a unique value: a copy is a new thing and is never
  refused for inheriting an identity.
- **Changed (breaking signatures):** `CreateSku` and `UpdateSku` take
  `skuRepository:` and `assertUniqueModelNumber:` as named parameters; the bare
  positional `CreateSku(repository)` no longer compiles.
- **Removed (breaking):** `Sku.manufacturerModelNumber` and its
  `manufacturer_model_number` wire key. It was never a variant of `modelNumber`: what
  a maker *calls* a thing, when that differs from its production number, is optional
  and carries no rule, so it is a trait a consumer declares. The package names a pair
  (`serializable`, `serial_number`) only when it enforces something on it.
- **Removed (breaking):** `Instance.skuModelNumber` and its `sku_model_number` wire
  key — a copy of a SKU field kept for labelling that nothing maintained and that
  could only disagree with the SKU it came from. The BACKLOG item that asked for a
  home for it is closed by removing it.
- **Note for a consumer's data:** the rule fires on write, so stored rows are safe
  until touched — but placeholder model numbers collide the moment they are written.
  A book's production number is its ISBN and its publisher is the manufacturer, so
  per-maker uniqueness is the right rule for a library too, and a `'FREE'`-style
  placeholder is the thing to replace rather than the rule to relax.

**`imageIds` leaves the entities: `ImageRecord` is the only home.** `Sku`,
`Instance` and `Locate` each carried a list of image ids while `ImageRecord` already
named its owner (`owner`, `ownerId`) — and the owner tag is the copy the package
queries by: `IImageRepository.fetchByOwner`, `FetchImageRecords`, and the cascade
`DeleteInstance` runs when an article goes. Nothing in `lib/` filled or read the
list, so the two copies could only disagree; a cover added through
`CreateImageRecord` never appeared in the field, and an entity loaded from storage
carried whatever the last writer put there. A consumer that read it for convenience
(`library_scanner` counts covers with `books.where((b) => b.imageIds.isNotEmpty)`)
gets a better answer from one `fetchAll()` grouped by `ownerId`, which cannot go
stale. The `image_ids` wire key goes with the field; a stored record still carrying
that key parses without it and is not written back.

**New: `DeleteInstanceAndUnusedSku` — the degenerate model.** A model that exists
only for its articles (a book's *edition*: nobody catalogues it, its copies merely
instantiate it) is removed with its **last** article, not the first one to leave,
because two copies share one SKU. There is no flag for degeneracy and no trait —
**choosing this operation is the assertion**, which keeps the fact out of storage
where two articles of one model could disagree about it. It composes the existing
halves instead of re-implementing them: `DeleteInstance` takes the article's images
and association edges, `DeleteSku` takes the model's assembly edges, and both run in
one transaction. Unlike `DeleteSku` it does **not** refuse while articles use the
model — a copy must always be deletable, and a shared edition simply survives it.

**`ReportProperty` is gone, and with it the package's only reporting vocabulary.** It
was a label/value/unit row — the shape of a consumer's device card — with no producer
here and one consumer outside the package, which no longer needs it. Reports are not
this package's job (the README's "deliberately not here" list already said so), and it
was the one file the coverage floor could not reach, since testing it would have
blessed dead API. With its consumer gone nothing holds it and no port is owed.

**The reference backend is no longer published.**

- **Removed from the archive:** `lib/in_memory.dart`, `lib/src/adapters/` and
  `example/`, via `.pubignore`. The published package is the model and the
  operations; a domain package that ships one storage story makes that story look
  like its own. An import of `package:sku_catalog/in_memory.dart` against the
  hosted package stops resolving — a 2.x consumer that used the reference backend
  copies it into their own project, or keeps a `path:` dependency on a clone,
  which is the work a consumer writing their own storage was always expected to
  do. `example/` goes with it because the tour runs on that backend, and a
  published example importing an unpublished path would not analyze. Everything
  is unchanged in a clone: the suite and the tour still run on it.
- **Reversal:** 2.0.0 shipped that backend and reversed the earlier *"the adapter
  rules do not bind this package"* decision; this entry reverses the reversal on
  the **publishing** question only. The one-way `adapters` row in
  `test/architecture_test.dart`, the text tripwire in `test/boundary_test.dart`
  and the `plugins:` rules in `import_rules.yaml` all stay as they are — the model
  and the operations still may never name the backend, and the backend still may
  not reach back.
- **Tests:** 247 passing; `dart run melos run coverage` reports 98.25% of `lib/`,
  against a floor of **90%** (lowered from 97% on purpose — a floor is where a layer
  that lost its tests fails the build, not a number to chase, and the suite runs at
  ~98%, so the floor is slack). The new edge has its own suite
  (`test/instance_association_test.dart`: direction preserved, two kinds on one
  pair as two rows, either-end fetch with a kind filter, the three refusals,
  delete, and the cascade through `DeleteInstance`), the new store answers the
  shared contract table in `test/in_memory_repository_contract_test.dart`, and
  `test/in_memory_catalog_test.dart` proves the composition root has the edge
  wired rather than merely available. The model-number rule has its own suite too
  (`test/model_number_uniqueness_test.dart`: a clash refused and nothing stored, the
  same number under another maker allowed, case and padding *not* the same number,
  a rename onto a taken number refused while keeping its own is allowed, a delete
  freeing the number, the copy path minting "(copy)" then "(copy 2)", and the
  catalogue's wiring exercised as wiring). `test/image_records_test.dart` pins the
  replacement read `imageIds` was standing in for: one pass over the records answers
  which owners have images, and it tracks a delete. The degenerate-model rule has its
  own suite too (`test/delete_instance_and_unused_sku_test.dart`: the model surviving
  its first copy and going with its last, both cascades intact when it does go, a
  shared model keeping its assembly edges while a copy leaves, other models
  untouched), and the rule was proved discriminating by inverting it — four cases go
  red when the model is taken early.

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

- **Decided:** **no instance composition.** An `Instance` is one article of a SKU
  at one place and owns no parts, so there is no `parentId` on it and none is
  coming. Composition already has two homes — a SKU containing SKUs
  (`SkuComponent`, folded into a bill of materials) and a place inside a place
  (`Locate`) — and instance-level parentage would duplicate both. An article that
  sits inside a host is the consumer's own convention and needs nothing from the
  catalog: leave its `locate` unset and the host holds the place. Written into
  `AGENTS.md` so the model is not re-litigated, and the BACKLOG item asking for
  `Instance.parentId` is dropped.

- **Decided:** **the adapter rules do not bind this package.** `sku_catalog` is a
  pure domain package — entities, value objects, failures, repository *contracts*
  and the operations over them — with no outer rings: it ships no adapter, no
  datasource, no UI. So `docs/01`'s "at least two repository adapters" rule and
  `docs/05`'s shared contract suite run against every adapter have nothing here to
  bind to; the in-memory implementations under `test/support/` are test doubles,
  deliberately unpublished, and the adapters belong to whoever consumes the
  contracts. Recorded here rather than as a BACKLOG deviation, because it is not a
  defect to fix and not a rule this repo is failing — it is a category the rule was
  never about.

- **Decided:** **no bundle import/export in the package either.** A slug-stable
  export and idempotent re-import of a whole catalog — stable ids, referential
  integrity — is a storage story, and this package holds no storage, so it holds
  no adapter and no bundle format. The work is the consumer's and already lives
  where it belongs; what the package owes it is the contracts, which is exactly
  what it ships.

- **Decided:** **an `Instance` is not a trait scope.** `TraitScope` names the three
  things a trait can classify — a SKU, a place, a manufacturer — and it always did;
  what disagreed were the docs: the README's model table listed an instance as a
  trait carrier and `Instance.traitIds` called itself "instance-level
  classification". An article is the *realization* of a SKU, so it holds the
  *values* of the traits in scope for it and carries trait ids only so a value has
  its definition. The enum's doc, the README row and the field now say that.

- **Ships:** a **reference in-memory backend**, `package:sku_catalog/in_memory.dart` — a
  second entry point beside the front door. Ten stores implementing the repository
  contracts over one `InMemoryTable<T>` each (a row *is* the JSON the model
  round-trips, so a record written before a field existed still parses), an
  `InMemoryUnitOfWork` that rolls back by snapshot, and `InMemoryCatalog`, a
  composition root holding the stores, the transaction and the model's rules and
  operations wired over them (`catalog.createInstance(...)` is a write with the
  rules in place; `catalog.deleteSku(...)` is two writes in one transaction). It is
  an example rather than a storage story — no durability, no indexes, no
  concurrency — and it is **not** part of the model: `test/boundary_test.dart` now
  fails the build if anything under `lib/src/domain/` or `lib/src/usecases/` names
  it, and `test/architecture_test.dart`'s edge table carries a one-way `adapters`
  row. The suite and the example both run on it, so the unpublished doubles in
  `test/support/` (12 files, 886 lines) and the example's own hand-rolled backend
  (~310 lines) are gone — one in-memory backend in the repository instead of three.
- **Reversal:** the decision recorded earlier in this entry — *"the adapter rules do
  not bind this package … it ships no adapter, no datasource, no UI"* — no longer
  holds. The package has one outer ring now and the bible's adapter rules apply to
  it. The front door's promise is unchanged: the model and the operations still ship
  together in one import, and a consumer who writes their own backend never carries
  the adapter.
- **Tests:** the adapter has its own proof — `test/in_memory_repositories_test.dart`
  (each contract's behaviour plus `InMemoryTable`'s own semantics, including that a
  snapshot is a copy), `test/in_memory_unit_of_work_test.dart` (rollback, commit and
  the unregistered-table boundary) and `test/in_memory_catalog_test.dart` (end to
  end to end through the composition root: the unique-value rule wired, the
  transaction wired, the stores exposed as contracts).
- **Breaking: the repository contracts carry no transaction parameter and no
  factory reset.** Every write signature used to take `IUnitOfWork? uow`, and every
  store exposed `clearAll()`. Neither was ever called: a use case that writes more
  than once takes the unit of work itself (`DeleteSku`, `DeleteInstance`) and wraps
  its writes, so a store never had to enroll anything, and clearing a store is not
  a word the model has. An implementer now writes five plain methods per aggregate
  — `create`, `update`, `delete`, `fetchById`, `fetchAll` (plus the one extra fetch
  a store's contract declares) — and nothing else. Downstream code that threaded a
  `uow` through a repository, or called `clearAll`, is a 1.x consumer.
- **Breaking: `create` refuses an id that is already stored.** The reference stores
  used to overwrite silently on `create`; they now return `AlreadyExistsFailure` and
  leave the stored record alone, which is what an adapter over a store with a
  primary key has to do anyway.

- **Breaking: the unique-value rule spans every holder, not just articles.** An
  `AssertUniqueAttributeValues` used to read `IInstanceRepository` alone, so a
  `Locate` or a `Manufacturer` carrying the same `isUnique` attribute value as an
  article was stored without complaint. It now reads all three stores and refuses
  the second claimer of a value, whatever kind it is — `CreateLocate`,
  `UpdateLocate`, `CreateManufacturer` and `UpdateManufacturer` gained the rule (and
  a constructor that takes it), and `InMemoryCatalog` wires and exposes all four
  (`catalog.createLocate(...)`). A model is still not a holder: a value on a SKU
  describes the class, and nothing on a SKU is unique in this sense.
- **Breaking: `AssertUniqueAttributeValues` takes the other two contracts, and its
  subject as a holder.** `call` now takes `holder:` — an `ArticleHolder`,
  `PlaceHolder` or `MakerHolder`, the sealed family in
  `lib/src/domain/value_objects/attribute_holder.dart` — rather than
  `call({required Instance instance})`, because one rule now serves three write
  paths. A sealed family rather than three nullable parameters (a union no caller
  can be trusted to fill in correctly, guarded by a runtime check) and rather than
  three use cases (which the shape rule would allow, but which triplicates the
  scan): the `switch` over it is exhaustive, so a fourth kind is a compile error.
- **Recorded decisions on that rule** (stated so a later reader does not "fix" them
  back): **(a)** the comparison is by **key and value across holders**, not by
  declared carrier — a place holding a value under a key its own scope never
  declares still blocks that value. `Trait.scope` is data the package stores and
  deliberately does not gate on; making it normative is its own decision, not a
  tweak to this comparison. **(b)** a **SKU is not a holder**, though it carries an
  `attributeValues` map exactly as the three that are: a value on a model describes
  the class, and holding a unique value is an article's, a place's or a maker's act.

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
