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
   repository contract; `.pubignore` keeps them out of the archive. A consumer is
   expected to build their own backend against the contracts. Enforced by
   `test/boundary_test.dart` ("none of them reaches for the test doubles"), so
   the published library can never start depending on them.

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
- `.pubignore` replaces this directory's `.gitignore` for pub **and applies to
  subdirectories** — which is how an over-eager rule once hid a member's pubspec
  and emptied its archive. It exists to keep `AGENTS.md`, `BACKLOG.md` and
  `test/support/` out; check `dart pub publish --dry-run`'s file list before
  trusting it.
- Open items live in `BACKLOG.md`, including the one outstanding doctrine delta
  (a second repository adapter plus a shared contract suite).
