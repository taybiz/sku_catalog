# AGENTS.md — instructions for agents working in this repo

`sku_catalog` is a published package built to the Dart/Flutter Bible
(`taybiz/dart-flutter-bible`; read `docs/00-compact.md` first). That doctrine is
the standard — this file carries only the local wiring and the calls this repo
made for itself. Do not restate bible rules below; if you need one, link it.

## Deviations from the bible

**The live list lives in [`BACKLOG.md`](BACKLOG.md)**, under "Deviations from the
Bible (flagged for review — do NOT auto-fix)": one entry per place the code and
the doctrine disagree, each with its reasoning. They are **recorded, not
auto-fixed** — the bible may itself be wrong, so every one is a human call. Do not
restate the list here; a second copy is a second truth.

## One package, on purpose

`lib/sku_catalog.dart` (the front door) re-exports `lib/src/domain/` (model +
contracts) and `lib/src/usecases/` (the operations). There is no `sku_catalog_domain`
package, and no narrow entry point: **if a consumer takes the domain they take the
operations with it.** Do not re-split this into sibling packages: a published
package may not depend on a `path:`, so siblings would have to be published too —
in dependency order, with version lockstep.

The backend in this repo is a **shipped reference adapter**:
`lib/src/adapters/in_memory/`, reachable at `package:sku_catalog/in_memory.dart`,
published like the rest of the package and tested by its own suite
(`test/in_memory_*_test.dart`). It is an example rather than a promise — no
durability, no indexes, no concurrency — and it is **outside the model**: nothing
under `lib/src/domain/` or `lib/src/usecases/` may import it, which
`test/boundary_test.dart` fails the build over, while the one-way `adapters` row in
`test/architecture_test.dart`'s edge table keeps the dependency pointing in. Its
tests live under `test/`, which `.pubignore` keeps out of the archive. A consumer is
still expected to build their own backend against the contracts; this one exists so
the contracts and the operations can be read as a running system.

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

## Local wiring

- Melos workspace of one (bible §3.3 "Topology C"): the package *is* the
  workspace root — `melos: useRootAsPackage: true` in `pubspec.yaml`, no
  `melos.yaml`, no pub `workspace:`. The gate is four scripts, and CI calls them
  by name so a script that rots fails the build: `dart run melos run format`,
  `analyze`, `test`, `publish-dry` (after `dart pub get`; `dart run melos
  bootstrap` once per clone, which writes `melos_<pkg>.iml` and `.idea/` — kept
  out of git and the archive by `*.iml` / `.idea/` in `.gitignore` and `.pubignore`).
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
  `BACKLOG.md` and the whole `test/` tree; check `dart pub publish --dry-run`'s
  file list before trusting it — stale untracked directories in a working clone get
  published too.
- Open items live in `BACKLOG.md`.

## Done means shipped

**This package is in production: changes land through a pull request.** `main`
takes no direct pushes — not from a human, not from an agent, not from a
dispatched worker. The delivery path is: branch off `main`, commit, push the
branch, open the PR.

The line for "ready to report done" and "ready to open the PR" is the **same
line** — the gate: formatted, analyzed, tested, covered, `publish-dry` at 0
warnings, CI green. If the work clears it and is good enough to tell the human
it's done, it is good enough to push and open the PR. No extra review gate, no
waiting, no "should I open a PR?" — velocity wins; the PR body carries what was
verified and what was left. Merge is the human's call; the branch is deleted once
the PR lands.

While a release is being assembled, the commits accumulate on one branch and land
as a single PR — a stack of interleaved PRs is a merge-order trap, and nobody
should have to sort one out by hand.
