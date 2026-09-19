/// A catalog model for physical parts: SKUs with traits and typed attributes,
/// assemblies of SKUs, manufacturers, the places they go, and the devices that
/// instantiate them.
///
/// This is the front door: it re-exports the model and the operations, so one
/// dependency gets you everything.
///
/// Presents FP-style tuples: every repository method and use case call returns a
/// fpdart `TaskEither<DomainFailure, T>`; call `.run()` for a
/// `Future<Either<DomainFailure, T>>`.
///
/// ```dart
/// import 'package:sku_catalog/sku_catalog.dart';
/// ```
///
/// There is nothing else to pick: the model and the operations ship together.
/// Persistence is yours — implement the repository contracts over whatever you
/// have. (The in-memory backend in this repo is a test double, and is not part
/// of the published package.)
library;

export 'src/domain/domain.dart';
export 'src/usecases/usecases.dart';
