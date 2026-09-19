/// In-memory implementations of every `sku_catalog_domain` repository contract,
/// plus [MemoryUnitOfWork] for testing atomic operations.
///
/// For tests, prototypes, demos and fixtures: state lives in a map per
/// repository and disappears with the object.
///
/// Presents FP-style tuples: every repository method returns a fpdart
/// `TaskEither<DomainFailure, T>`; call `.run()` for a
/// `Future<Either<DomainFailure, T>>`.
library;

export 'src/memory_device_repository.dart';
export 'src/memory_device_type_repository.dart';
export 'src/memory_image_repository.dart';
export 'src/memory_locate_repository.dart';
export 'src/memory_manufacturer_repository.dart';
export 'src/memory_meta_repository.dart';
export 'src/memory_sku_component_repository.dart';
export 'src/memory_trait_attribute_definition_repository.dart';
export 'src/memory_trait_repository.dart';
export 'src/memory_unit_of_work.dart';
