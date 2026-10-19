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

**Divergence:** the bible puts an optional `IUnitOfWork? uow` on every repository
write method — reads may take one, never require it — so the seam is uniform
(§5.5), and gives a many-store wipe one unit of work (§5.6). Here the contracts are
**five plain methods** — `fetchAll`, `fetchById`, `create`, `update`, `delete`,
plus the one extra fetch a store declares — with no `uow` parameter and no
`clearAll()`. The transaction sits on the **use case** that writes more than once:
`DeleteSku` and `DeleteInstance` take an `IUnitOfWork?` and wrap their writes in
it.

**Why:** neither was ever called. A use case that writes several times owns its own
atomicity, so a store never had to enroll anything, and clearing a store is not a
word this model has.

**What it costs, and where the seam went:** the *adapter* keeps it. A transactional
backend must publish its open transaction where its repositories can find it,
because they are no longer handed one — set the active client inside `runEither`,
clear it in its `finally`, and route **every** read through it too, or a read in an
open transaction blocks on it. Enrollment is therefore per *use case*, not per
write: a consumer can hand their own `IUnitOfWork` to a catalog use case
(`DeleteInstance(unitOfWork: mine)`), but cannot take a single write of one into
their own transaction.

**Status:** deliberate, and on review. The alternative — a bible clause sanctioning
the use-case seam — was considered and held: the estate has no second adopter, and
it would change what every future package's contracts look like in order to settle
one package's preference.

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
(`test/in_memory_*_test.dart`), and kept out of the archive by `.pubignore` —
together with `lib/in_memory.dart` and `example/`, which runs on it — so the
published package stays the model and the operations, and no consumer inherits
someone else's storage story. (2.0.0 published it; 3.0.0 took it back out. Do not
flip this again without a reason that survives "a domain package that ships one
storage story makes that story look like its own".) It is an example rather than a
promise — no durability, no indexes, no concurrency — and it is **outside the
model**: nothing under `lib/src/domain/` or `lib/src/usecases/` may import it, which
`test/boundary_test.dart` fails the build over, while the one-way `adapters` row in
`test/architecture_test.dart`'s edge table keeps the dependency pointing in. A
consumer is expected to build their own backend against the contracts; this one
exists so the contracts and the operations can be read as a running system in a
clone.

## Not doing: instance composition

An `Instance` is one article of a SKU at one place; it owns no parts, and there is
no `parentId` on it — do not add instance-level parentage. Composition already has
two homes and a third would duplicate both: a SKU containing SKUs (`SkuComponent`,
folded into a bill of materials) and a place inside a place (`Locate`). An article
that lives inside a host is the consumer's own convention, and it needs nothing
from the catalog to express it: leave the article's `locate` unset and the host
holds the place. The catalog does not force that on a trait name — an article with
no place of its own simply has no place, and only the consumer knows which those
are.

## Association is at both levels, and an edge connects peers

Composition is SKU-only (above); **association is not**. The model carries two edge
entities on purpose, and which one a fact belongs to is decided by the *predicate*,
not by taste: `SkuAssociation` for a fact of the models ("an author `edited` a
work", "compatible with"), `InstanceAssociation` for a fact of two particular
articles ("this copy is `bound_with` that copy", "this copy was `replaced_by` that
one"). Stating a model fact on the articles restates it once per article owned and
lets the copies disagree; stating an article fact on the models claims something
about articles nobody asked about.

Do not re-litigate that into one polymorphic edge. A sealed node reference
(`SkuRef | InstanceRef`) changes every existing wire key *and* erases the
class/token distinction exactly where the type system is the thing enforcing it,
so the `Add*Association` operations would have to say at runtime what the types say
now. 3.0.0 considered it and took the second entity instead.

The rule both entities share: **an edge connects peers** — an article never points
at a SKU (it points at its model through its own `skuId`), and an article is not
its own peer. `AddInstanceAssociation` refuses a blank kind, a missing article and
a self-edge; all three are `InvalidInputFailure`, so the sealed `DomainFailure`
hierarchy gains no leaf and a consumer's exhaustive switch keeps compiling.

## Local wiring

- Melos workspace of one (bible §3.3 "Topology C"): the package *is* the
  workspace root — `melos: useRootAsPackage: true` in `pubspec.yaml`, no
  `melos.yaml`, no pub `workspace:`. The gate is five scripts, and CI calls them
  by name so a script that rots fails the build: `dart run melos run format`,
  `analyze`, `test`, `coverage`, `publish-dry` (after `dart pub get`; `dart run melos
  bootstrap` once per clone, which writes `melos_<pkg>.iml` and `.idea/` — kept
  out of git and the archive by `*.iml` / `.idea/` in `.gitignore` and `.pubignore`).
  `coverage` runs `coverage:test_with_coverage --fail-under=97`, so the number is
  enforced rather than asserted. It is a ratchet: raise the floor as the suite
  grows, never lower it to turn a red build green.
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

**This package is in production: changes land through a pull request.** `main`
takes no direct pushes — not from a human, not from an agent, not from a
dispatched worker. The delivery path is: branch off `main`, commit, push the
branch, open the PR.

The line for "ready to report done" and "ready to open the PR" is the **same
line** — the gate: formatted, analyzed, tested, covered to the floor `dart run
melos run coverage` enforces (90% of `lib/`), `publish-dry` at 0 warnings, CI
green. If the work clears it and is good enough to tell the human
it's done, it is good enough to push and open the PR. No extra review gate, no
waiting, no "should I open a PR?" — velocity wins; the PR body carries what was
verified and what was left. Merge is the human's call; the branch is deleted once
the PR lands.

While a release is being assembled, the commits accumulate on one branch and land
as a single PR — a stack of interleaved PRs is a merge-order trap, and nobody
should have to sort one out by hand.
