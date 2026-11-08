# Contributing

## Layout

```
lib/sku_catalog.dart        the front door: the model and the operations
lib/in_memory.dart          the other door: the reference in-memory backend
                            (repo-only — not in the published archive)
lib/src/domain/             entities, enums, value objects, failures, contracts
lib/src/usecases/           one file per operation
lib/src/adapters/in_memory/ the reference backend: stores, transaction, catalogue
                            (repo-only)
example/                    a runnable tour of the contracts, on its own tiny store
test/                       the suite (repo-only — not published)
```

`lib/src/` is internal — import the barrel. `package:sku_catalog/sku_catalog.dart`
is the published package: the model and its operations, one dependency, and it
cannot be split. In a clone there is a second barrel,
`package:sku_catalog/in_memory.dart`, for the reference backend that the suite and
the tour run on — a consumer writing their own storage never carries it, because
it is not in the archive.


## Working on it

This package is a **melos workspace of one**: the package *is* the workspace root,
so the scripts live in `pubspec.yaml` under `melos:`. There is no `melos.yaml`.

```bash
dart pub get
dart run melos bootstrap       # once per clone; also writes melos_<pkg>.iml
dart run melos run format      # dart format --output=none --set-exit-if-changed .
dart run melos run analyze     # dart analyze --fatal-infos --fatal-warnings
dart run melos run test        # dart test
dart run melos run publish-dry # dart pub publish --dry-run
```

CI runs exactly those scripts, in that order, so a broken step fails the build
rather than rotting.

### Publishing

```bash
dart pub publish --dry-run
dart pub publish
```

One package, one version, one publish — there is no dependency order to get
right and no sibling constraint to keep in step. Check the file list the dry run
prints: the pubspec, `lib/` (minus the adapter ring and its door), `README.md`,
`CHANGELOG.md`, `LICENSE` and `example/` belong there; `test/`,
`lib/in_memory.dart`, `lib/src/adapters/`, `AGENTS.md` and `backlog/` do not.

The package holds its structural rules in `test/boundary_test.dart`, and they fail
the build rather than waiting for review:

- **nothing in `lib/` may import or name anything product-specific** — if a
  consumer's word shows up in this API, the boundary has moved without anyone
  deciding it should;
- **the model and the operations may never reach for the adapter** — the reference
  backend lives in this repository (outside the published archive), so the model
  cannot start depending on it;
- **the areas of `lib/src/` may only depend in the allowed direction** — the
  dependency table lives in that test (`domain`, `usecases`, `adapters`, each with
  the packages it may use; `adapters -> usecases -> domain` and never back), and an
  import that crosses an area, or reaches either public entry point from inside
  `lib/src/`, fails. That is the guarantee package separation used to give for
  free; with one package, the suite says it out loud.

