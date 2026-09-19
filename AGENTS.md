# AGENTS.md — instructions for agents working in this repo

`sku_catalog` is a published package family built to the Dart/Flutter Bible
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
   Rather than wrap that away, each README and each package barrel states plainly
   what a caller gets back. Decided by Steve, 2026-09-19.
2. **The repo root is a package.** The front door `sku_catalog` sits at the root
   and the root is also the pub workspace root. melos does not treat the workspace
   root as a package, so `verify` and `publish-check` name the root explicitly.
   Do not "tidy" those scripts back into a bare `melos run …` — that silently
   drops the root's tests and its publish.

## Local wiring

- melos config lives in the root `pubspec.yaml` under `melos:`. There is no
  `melos.yaml`, and adding one would be dead config.
- `melos run verify` — format check, root analyze + test, then every member.
- `melos run publish-check` — the root's `dart pub publish --dry-run`, then
  `melos exec -- dart pub publish --dry-run` for each member. Needs a **committed**
  tree: pub warns about modified checked-in files and exits non-zero.
- CI runs both scripts, in that order.
- Publish order is domain → usecases/memory → root. A dry-run does **not** warn
  when a sibling is not on pub.dev yet, so the order is on the publisher.
- Open items live in `BACKLOG.md`, including the one outstanding doctrine delta
  (a second repository adapter plus a shared contract suite).
