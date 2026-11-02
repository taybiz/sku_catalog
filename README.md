# sku_catalog

A catalog model for physical parts: **SKUs with traits and typed attributes,
assemblies of SKUs, the manufacturers behind them, the places they go, and the
instances that instantiate them.** Published from `taybiz/sku_catalog`. Built
for cases where things are real, varied, and described by different people in
different words — electrical gear, pinball boards, lab equipment; nothing in
the package is specific to one of those.

## Stack

Dart (pub.dev package), melos workspace of one. Use cases return
`TaskEither<DomainFailure, T>` (fpdart) rather than throwing — see
[`docs/usage.md`](docs/usage.md).

## Quick start

```dart
import 'package:sku_catalog/sku_catalog.dart';
```

Define the traits and typed attributes, build SKUs that carry them, then
construct the operations over your own repository contracts — this package
ships no database. Runnable version:
[`example/sku_catalog_example.dart`](https://github.com/taybiz/sku_catalog/blob/main/example/sku_catalog_example.dart).

```bash
dart pub get && dart run melos run test
```

## Where to look

| Topic | File |
|---|---|
| Usage: what you get back, one package, bringing your own storage | [`docs/usage.md`](docs/usage.md) |
| The model: entities, assembly edges, serial numbers, identity rules | [`docs/model.md`](docs/model.md) |
| Reference in-memory backend, repo layout, working on it, publishing | [`docs/reference-backend.md`](docs/reference-backend.md), [`docs/contributing.md`](docs/contributing.md) |
| Local wiring, deviations from the bible, architecture gates, open work | [`AGENTS.md`](AGENTS.md), [`BACKLOG.md`](BACKLOG.md) |
| Prior README text, archived 2026-10-31 | [`docs/readme-archive-2026-10-31.md`](docs/readme-archive-2026-10-31.md) |

## License

MIT — see [LICENSE](LICENSE).
