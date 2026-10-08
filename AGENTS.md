# AGENTS.md — instructions for agents working in this repo

`sku_catalog` is a published package built to the Dart/Flutter Bible
(`taybiz/dart-flutter-bible`; read `docs/00-compact.md` first). That doctrine is
the standard — this file carries only the local wiring and the calls this repo
made for itself. Do not restate bible rules below; if you need one, link it.

## Deviations from the bible

**The live list lives in [`BACKLOG.md`](BACKLOG.md)**, under "Deviations from the
Bible (flagged for review — do NOT auto-fix)": one entry per place the code and
the doctrine disagree, each with its reasoning, re-checked against
`taybiz/dart-flutter-bible` `main` and dated. They are **recorded, not
auto-fixed** — the bible may itself be wrong, so every one is a human call.

Do not restate the list here. It moves as doctrine and the code move, and a
second copy is a second truth; the tracker is the one place it lives. This file
says what the repo *is* and how to work on it, not where it still differs.

## One package, on purpose

`lib/sku_catalog.dart` (the front door) re-exports `lib/src/domain/` (model +
contracts) and `lib/src/usecases/` (the operations). There is no `sku_catalog_domain`
package, and no narrow entry point: **if a consumer takes the domain they take the
operations with it.** Do not re-split this into sibling packages. A published
package may not depend on a `path:`, so siblings would have to be published too —
in dependency order, with version lockstep, and no client-side check catches a
miss (the dry run reports "0 warnings" for the root while the siblings 404).
Measured, not assumed; this shape was decided twice (2026-09-19).

The backend in this repo is a **test double and is deliberately not published**.
`test/support/` holds in-memory implementations of every repository contract;
`.pubignore` keeps the whole `test/` tree out of the archive (shipping the tests
without the doubles they import would publish broken imports). A consumer is
expected to build their own backend against the contracts. `test/boundary_test.dart`
asserts that nothing under `lib/` reaches for those doubles, so the published
library can never start depending on them.

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
  `test/architecture_test.dart`: a `dart_arch_test` test over the *resolved*
  import graph (bible §2.9) for area direction, front-door cycles, `lib/src/`
  privacy, `file:`/product-dependency leakage, and workspace-wide cycle-freedom —
  a plain `dart test`, so CI already runs it. `import_rules.yaml` (wired via
  `plugins:` in `analysis_options.yaml`, no pubspec dependency) is the as-you-type
  nicety: it fails the analyzer — in the IDE and in CI, because Analyze runs
  `--fatal-infos` — on any wrong-way edge (`usecases -> domain`, never the reverse)
  or an internal file importing the public entry point. `test/boundary_test.dart`
  is the text tripwire that cannot fail silently if a tool stops resolving, and it
  carries the rules no import graph can express (a product name in a comment or
  string). Prove a rule fires — plant the import, run the test, read the failure,
  revert — instead of assuming it does.
- `.pubignore` replaces this directory's `.gitignore` for pub, **applies to
  subdirectories**, and anchors any pattern containing a slash to this directory
  (`doc/api/` does not reach `sub/doc/api/`). It keeps out `AGENTS.md`,
  `BACKLOG.md` and the whole `test/` tree; check `dart pub publish --dry-run`'s
  file list before trusting it — an over-eager rule once hid a member's pubspec
  and emptied its archive, and stale untracked directories in a working clone get
  published too.
- Open items live in `BACKLOG.md`, including the outstanding doctrine delta
  (a second repository adapter plus a shared contract suite).
