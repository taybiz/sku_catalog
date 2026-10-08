# AGENTS.md — instructions for agents working in this repo

`sku_catalog` is a published package built to the Dart/Flutter Bible
(`taybiz/dart-flutter-bible`; read `docs/00-compact.md` first). That doctrine is
the standard — this file carries only **what is different here** and the local
wiring. Do not restate bible rules below; if you need one, link it.

## Deviations from the bible

Each row is a place the code and the doctrine disagree. They are **recorded, not
auto-fixed** — the bible may itself be wrong, so every one is a human call. The
reasoning for each lives in [`BACKLOG.md`](BACKLOG.md) under "Deviations from the
Bible"; one line each here. Re-checked 2026-10-08 against the bible at
`taybiz/dart-flutter-bible` `main` (docs §1–§12, rule-code numbering).

| # | Bible says | Here |
|---|---|---|
| 1 | §4.6 the default seam is `Future<Either<...>>` and consumers never build or run a chain. | The seam **is** the unrun `TaskEither`; the consumer runs it. **Sanctioned** by §4 ("declare the error style, loudly") — declared in the barrel doc comment, the README and here. |
| 2 | §2.5 named parameters always; §4.4 `call()` takes discrete business params, never cargo objects. | Contracts and `call()` are positional and pass whole entities (`create(DeviceType …)`). |
| 3 | §2.2 never disable a rule in `analysis_options.yaml` — per-line `// ignore:` or change the code. | `prefer_initializing_formals: false` is set in the config. |
| 4 | §9.7 the root `analysis_options.yaml` wires lints, **strict**, `public_member_api_docs`, `todo: error`. | `lints` + `public_member_api_docs` + `todo: error` are on; no `strict-casts` / `strict-raw-types`. |
| 5 | §4.2 failure hierarchies are closed (`sealed` where the language allows) so a `switch` over them is exhaustive. | `DomainFailure` is `abstract base` — the shared root every product's failure family extends, which a `sealed` root cannot be. |
| 6 | §4.8 / §10.2 no `throw` / `try` / `catch` anywhere inside the domain. | `contracts/unit_of_work.dart` bridges a transactional store's rollback with a hand-rolled `throw` / `on … catch`. |
| 7 | §6.2 use-case tests mock the repository seam with `mocktail`. | All twelve test files run the use cases against the real in-memory doubles (§6.3 also says to prefer a real double where one exists). |
| 8 | Stack table pins `equatable ^2.x`. | `equatable ^3.0.0` — the pin looks stale; 3.x is current and `dart pub outdated` is clean. |
| 9 | §2.7 / §3 a published package's example directory is `examples/`. | `example/` (singular) — the name only. |
| 10 | §10.4 every repository contract has ≥2 adapters and a shared contract suite run against all of them. | One (test-only, in-memory) adapter and no contract suite. Open item in `BACKLOG.md`. |

There is no deviation for the layer graph: the current bible (§2.8) enforces
boundaries by **lint and review only** and names no architecture test, so the
repo's `import_rules` plugin and `test/boundary_test.dart` are extra hygiene
rather than a rival to a prescribed gate. (An earlier bible revision did
prescribe `dart_arch_test`; that rule is gone.)

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
  bootstrap` once per clone, which writes `melos_<pkg>.iml` — kept out of git and
  the archive by `*.iml` in `.gitignore` and `.pubignore`).
- Publishing needs a **committed** tree: pub warns about modified checked-in files
  and exits non-zero. One command, no dependency order.
- The import graph of `lib/` is enforced twice, deliberately. `import_rules.yaml`
  (wired via `plugins:` in `analysis_options.yaml`, no pubspec dependency) fails
  the analyzer — in the IDE as you type and in CI, because Analyze runs
  `--fatal-infos` — on any wrong-way edge (`usecases -> domain`, never the reverse)
  or on an internal file importing the public entry point. `test/boundary_test.dart`
  is the tripwire that cannot fail silently if the plugin ever stops resolving, and
  it carries the rules the plugin cannot express (a product name in text, `lib/`
  reaching for the doubles). Prove a rule fires — plant the import, run
  `dart analyze`, read the reason, revert — instead of assuming it does.
- `.pubignore` replaces this directory's `.gitignore` for pub, **applies to
  subdirectories**, and anchors any pattern containing a slash to this directory
  (`doc/api/` does not reach `sub/doc/api/`). It keeps out `AGENTS.md`,
  `BACKLOG.md` and the whole `test/` tree; check `dart pub publish --dry-run`'s
  file list before trusting it — an over-eager rule once hid a member's pubspec
  and emptied its archive, and stale untracked directories in a working clone get
  published too.
- Open items live in `BACKLOG.md`, including the outstanding doctrine delta
  (a second repository adapter plus a shared contract suite).
