# AGENTS.md — instructions for agents working in this repo

`sku_catalog` is a published package built to the Dart/Flutter Bible
(`taybiz/dart-flutter-bible`; read `docs/00-compact.md` first). That doctrine is
the standard — this file carries only the local wiring and the calls this repo
made for itself. Do not restate bible rules below; if you need one, link it.

## Deviations from the bible

One entry per place the code and the doctrine disagree, each with its reasoning.
They are **recorded, not auto-fixed** — the bible may itself be wrong, so every one
is a human call (bible §1.3, §10.15a). A **fixable defect** is not a deviation: it
goes to [`BACKLOG.md`](BACKLOG.md) as a terse item to fix.

### The repository contracts carry no `uow`, and no `clearAll`

**Divergence:** the bible puts an optional `uow` on every repository write method —
so the seam is uniform (§5.5) — and gives a many-store wipe one unit of work (§5.6).
Here the contracts are **five plain methods** — `fetchAll`, `fetchById`, `create`,
`update`, `delete`, plus the one extra fetch a store declares — with no `uow`
parameter and no `clearAll()`. The transaction sits on the **use case**: a
`UnitOfWork` (a function type) taken as a **required constructor dependency** by the
fourteen operations that need one — the three cascading deletes, `DeleteTrait`,
`UpdateSkuComponent`, the six rule-carrying create/update paths, the three edge
writers. No optional form, no default: a store that cannot roll back is wired with
`noOpUnitOfWork` at the composition root. An operation that composes others owns the
only transaction and wires its pieces with the no-op, so nothing nests.

**Why:** the contracts' optional `uow` was never called, and an optional one on a use
case had an unsafe shape — `DeleteInstance(id: x)` compiled, defaulted to a no-op and
silently meant "no transaction". A bible clause sanctioning the use-case seam was
considered and left out: no second adopter.

**What the adapter pays:** it keeps the seam. Publish the open transaction where the
repositories can find it — set the active client inside the unit of work, clear it in
a `finally`, route **every** read through it too, and treat a busy store as a unit that
did not happen. Enrollment is per *use case*, not per write: a consumer hands their own
`UnitOfWork` to the operation they construct, but cannot take a single write of one into
their own transaction. The four rules an implementer has to get right are on the
`UnitOfWork` type itself.

## One package, on purpose

`lib/sku_catalog.dart` (the front door) re-exports `lib/src/domain/` (model +
contracts) and `lib/src/usecases/` (the operations). There is no `sku_catalog_domain`
package, and no narrow entry point: **if a consumer takes the domain they take the
operations with it.** Do not re-split this into sibling packages: a published
package may not depend on a `path:`, so siblings would have to be published too —
in dependency order, with version lockstep.

The backend in this repo is a **reference adapter, and it is NOT published**:
`lib/src/adapters/in_memory/`, reachable in a clone at
`package:sku_catalog/in_memory.dart`, tested by its own suite
(`test/in_memory_*_test.dart`), and kept out of the archive by `.pubignore` — together
with `lib/in_memory.dart` — so the published package is the model and the operations, and
no consumer inherits somebody else's storage story. `example/` *does* ship, because a
published package is expected to carry a real, CI-tested example: it runs on the published
import alone, with its own little store, and `test/example_runs_test.dart` executes it.
2.0.0 shipped it and 3.0.0 took it back out: do not flip that again without a reason that
survives "a package that ships one storage story makes it look like its own". It is an
example, not a promise — no durability, no indexes, no concurrency — and it is **outside
the model**:
nothing under `lib/src/domain/` or `lib/src/usecases/` may import it, which
`test/boundary_test.dart` fails the build over, while the one-way `adapters` row in
`test/architecture_test.dart`'s edge table keeps the dependency pointing in. Consumers
build their own backend against the contracts; this one exists so the contracts and the
operations can be read as a running system in a clone.

## Not doing: instance composition

An `Instance` is one article of a SKU at one place: it owns no parts and carries no
`parentId`. Do not add instance-level parentage — composition already has two homes (a
SKU containing SKUs, `SkuComponent` into a bill of materials; a place inside a place,
`Locate`) and a third would duplicate both. An article that lives inside a host is the
consumer's own convention: leave the article's `locate` unset and the host holds the
place. No trait name is forced on it — only the consumer knows which articles have no
place of their own.

## Association is at both levels, and an edge connects peers

Composition is SKU-only (above); **association is not**. The model carries two edge
entities on purpose, and the *predicate* decides which one a fact belongs to:
`SkuAssociation` for a fact of the models ("an author `edited` a work"), and
`InstanceAssociation` for a fact of two particular articles ("this copy is
`bound_with` that copy"). A model fact stated on the articles is restated once per
copy and lets the copies disagree; an article fact stated on the models claims
something about articles nobody asked about. Do not collapse the two into one
polymorphic edge: a sealed `SkuRef | InstanceRef` changes every wire key and erases the
class/token distinction exactly where the type system is what enforces it, so the
`Add*Association` operations would have to say at runtime what the types say now. That
was settled in 3.0.0 — the second entity stands.

The rule both entities share: **an edge connects peers** — an article never points
at a SKU (it points at its model through its own `skuId`), and an article is not
its own peer. `AddInstanceAssociation` refuses a blank kind, a missing article and
a self-edge; all three are `InvalidInputFailure`, so the sealed `DomainFailure`
hierarchy gains no leaf and a consumer's exhaustive switch keeps compiling.

## Local wiring

- Melos workspace of one (bible §3.3 "Topology C"): the package *is* the workspace
  root — `melos: useRootAsPackage: true` in `pubspec.yaml`, no `melos.yaml`, no pub
  `workspace:`. Five gate scripts, called by name in CI so one that rots fails the
  build: `dart run melos run format`, `analyze`, `test`, `coverage`, `publish-dry`
  (after `dart pub get`; `melos bootstrap` once per clone writes `melos_<pkg>.iml` and
  `.idea/`, kept out of git and the archive by `*.iml` / `.idea/`). `coverage` runs
  `coverage:test_with_coverage --fail-under=90`: a floor, not a target, so it is where a
  layer that lost its tests fails the build. The suite runs at ~98%, so ratcheting the
  number up only reds the gate on noise.
- Publishing needs a **committed** tree: pub warns about modified checked-in files
  and exits non-zero. One command, no dependency order.
- The import graph of `lib/` is gated three ways, deliberately. The **gate** is
  `test/architecture_test.dart`: a `dart_arch_test` test over the *resolved* import
  graph (bible §2.9), run by plain `dart test`, so CI already runs it. Its edge table
  carries three areas — `domain`, `usecases` and `adapters` (the reference backend) —
  with `adapters -> usecases -> domain` and never the reverse.
  `import_rules.yaml` (wired via `plugins:` in `analysis_options.yaml`, no pubspec
  dependency) is the as-you-type nicety, failing analyze — CI runs `--fatal-infos` —
  on a wrong-way edge (`usecases -> domain`, never the reverse) or an internal file
  importing the public entry point. `test/boundary_test.dart` is the text tripwire
  that cannot fail silently if a tool stops resolving, and carries the rules no
  import graph can express (a product name in a comment or string). Prove a rule
  fires — plant the import, run the test, read the failure, revert.
- `.pubignore` replaces this directory's `.gitignore` for pub, **applies to
  subdirectories**, and anchors any pattern containing a slash to this directory
  (`doc/api/` does not reach `sub/doc/api/`). It keeps out `AGENTS.md`,
  `BACKLOG.md`, the whole `test/` tree, and the reference backend with its door and
  its example (`lib/in_memory.dart`, `lib/src/adapters/`, `example/`); check
  `dart pub publish --dry-run`'s file list before trusting it — stale untracked
  directories in a working clone get published too.
- Open items live in `BACKLOG.md`.

## Done means shipped

**Changes land through a pull request.** `main` takes no direct pushes — not from a
human, not from an agent, not from a dispatched worker. Branch off `main`, commit, push
the branch, open the PR.

The line for "ready to report done" and "ready to open the PR" is the **same line** —
formatted, analyzed, tested, covered to the 90% floor, `publish-dry` at 0 warnings, CI
green. Work that clears it is good enough to push and open the PR: no extra review
gate, no waiting, no "should I open a PR?". The PR body carries what was verified and
what was left. Merge is the human's call; the branch is deleted once the PR lands.

While a release is being assembled, the commits accumulate on one branch and land as a
single PR — a stack of interleaved PRs is a merge-order trap nobody should have to sort
out by hand.
