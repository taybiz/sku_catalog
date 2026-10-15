/// A working in-memory backend for this package: **the reference to copy**.
///
/// `package:sku_catalog/sku_catalog.dart` is the model and its operations. This is
/// the third thing — the storage a consumer otherwise writes themselves: one
/// in-memory store per repository contract, a unit of work that rolls back by
/// snapshot, and an `InMemoryCatalog` composition root that wires the model's
/// rules and operations over both.
///
/// It is not this package's persistence story. It is durable to nothing, indexes
/// nothing, and is not safe across isolates: it exists so the contracts and the
/// operations can be read as a running system, and so a consumer has a
/// known-good shape to replace piece by piece.
///
/// ```dart
/// import 'package:sku_catalog/in_memory.dart';
/// import 'package:sku_catalog/sku_catalog.dart';
///
/// final catalog = InMemoryCatalog();
/// await catalog.createInstance(instance: article).run();   // rules included
/// ```
library;

export 'src/adapters/in_memory/in_memory.dart';
