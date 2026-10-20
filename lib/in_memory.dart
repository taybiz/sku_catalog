/// A working in-memory backend for this package: **the reference to copy**.
///
/// `package:sku_catalog/sku_catalog.dart` is the model and its operations. This is
/// the second thing — the storage a consumer otherwise writes themselves: one
/// in-memory store per repository contract, a unit of work that rolls back by
/// snapshot, and an `InMemoryCatalog` composition root that wires the model's
/// rules and operations over both.
///
/// **This door is repo-only — it is not in the published archive.** The published
/// package is the model and the operations; storage is the implementer's, and
/// shipping one would make a single storage story look like the package's own.
/// Read it here, in a clone (or on GitHub), copy the shape, and implement the
/// contracts over whatever you actually have. `.pubignore` keeps `lib/in_memory.dart`
/// and `lib/src/adapters/` out of the archive; the example and the suite in this
/// repository run on it either way.
///
/// It is not a storage story even here: it is durable to nothing, indexes
/// nothing, and is not safe across isolates. It exists so the contracts and the
/// operations can be read as a running system.
///
/// ```dart
/// import 'package:sku_catalog/in_memory.dart';   // in a clone of this repo
/// import 'package:sku_catalog/sku_catalog.dart';
///
/// final catalog = InMemoryCatalog();
/// await catalog.createInstance(instance: article).run();   // rules included
/// ```
library;

export 'src/adapters/in_memory/in_memory.dart';
