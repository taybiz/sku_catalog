/// A catalog model for physical parts: SKUs with traits and typed attributes,
/// assemblies of SKUs, manufacturers, the places they go, and the devices that
/// instantiate them.
///
/// This is the front door: it re-exports the model and the operations, so one
/// dependency gets you everything.
///
/// ```dart
/// import 'package:sku_catalog/sku_catalog.dart';
/// ```
///
/// Prefer a narrower dependency when you want only part of it:
///
/// - `sku_catalog_domain` — the model and the repository contracts, no operations.
/// - `sku_catalog_usecases` — the operations, typed against those contracts.
/// - `sku_catalog_memory` — an in-memory backend, for tests and prototypes.
library;

export 'package:sku_catalog_domain/sku_catalog_domain.dart';
export 'package:sku_catalog_usecases/sku_catalog_usecases.dart';
