# AGENTS.md — instructions for agents working in this repo

`sku_catalog` is a published package built to the Dart/Flutter Bible
(`staylorx/dart-flutter-bible`; read `docs/00-compact.md` first). That doctrine is
the standard — this file carries only **what is different here** and the local
wiring. Do not restate bible rules below; if you need one, link it.

## Deviations from the bible

1. **This package presents FP-style tuples; the public seam is `TaskEither`, not
   `Future<Either<...>>`.** `docs/04`
   ("Where the chain ends") says repository contract methods and use case `call()`
   signatures are `Future<Either<Failure, T>>` and that consumers never build or
   `run()` a chain. Here both return `TaskEither<DomainFailure, T>` and the
   consumer runs it: the tuple is handed over deliberately, because composition —
   trait chains, assembly resolution, provenance — is the point of this model.
   Rather than wrap that away, the README and the front door's doc comment state
   plainly what a caller gets back. Decided by Steve, 2026-09-19.
2. **The backend in this repo is a test double and is deliberately not
   published.** `test/support/` holds in-memory implementations of every
   repository contract; `.pubignore` keeps the whole `test/` tree out of the
   archive (shipping the tests without the doubles they import would publish
   broken imports). A consumer is expected to build their own backend against the
   contracts. Enforced by `test/boundary_test.dart` ("none of them reaches for
   the test doubles"), so the published library can never start depending on
   them.

## One package, on purpose

`lib/sku_catalog.dart` (the front door) re-exports `lib/src/domain/` (model +
contracts) and `lib/src/usecases/` (the operations). There is no `sku_catalog_domain`
package, and no narrow entry point: **if a consumer takes the domain they take the
operations with it.** Do not re-split this into sibling packages. A published
package may not depend on a `path:`, so siblings would have to be published too —
in dependency order, with version lockstep, and no client-side check catches a
miss (the dry run reports "0 warnings" for the root while the siblings 404).
Measured, not assumed; this shape was decided twice (2026-09-19).

## Local wiring

- No melos, no pub workspace: one package, plain Dart commands. Both existed only
  to coordinate members, and melos never saw the workspace root as a package
  anyway — the scripts had to name it explicitly.
- `dart pub get` · `dart format --output=none --set-exit-if-changed .` ·
  `dart analyze --fatal-infos --fatal-warnings` · `dart test` ·
  `dart pub publish --dry-run`. CI runs exactly those, in that order.
- Publishing needs a **committed** tree: pub warns about modified checked-in files
  and exits non-zero. One command, no dependency order.
- The import graph is enforced twice, deliberately. `import_rules.yaml` (wired via
  `plugins:` in `analysis_options.yaml`, no pubspec dependency) fails the analyzer
  — in the IDE as you type and in CI, because Analyze runs `--fatal-infos` — on
  any wrong-way edge (`usecases -> domain`, never the reverse) or on an internal
  file importing the public entry point. `test/boundary_test.dart` is the tripwire
  that cannot fail silently if the plugin ever stops resolving, and it carries the
  rules the plugin cannot express (a product name in text, `lib/` reaching for the
  doubles). Prove a rule fires — plant the import, run `dart analyze`, read the
  reason, revert — instead of assuming it does.
- `.pubignore` replaces this directory's `.gitignore` for pub, **applies to
  subdirectories**, and anchors any pattern containing a slash to this directory
  (`doc/api/` does not reach `sub/doc/api/`). It keeps out `AGENTS.md`,
  `BACKLOG.md` and the whole `test/` tree; check `dart pub publish --dry-run`'s
  file list before trusting it — an over-eager rule once hid a member's pubspec
  and emptied its archive, and stale untracked directories in a working clone get
  published too.
- Open items live in `BACKLOG.md`, including the one outstanding doctrine delta
  (a second repository adapter plus a shared contract suite).
