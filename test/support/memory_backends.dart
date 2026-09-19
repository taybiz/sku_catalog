/// Test doubles: in-memory implementations of every repository contract,
/// plus [MemoryUnitOfWork] for testing atomic operations.
///
/// TEST-ONLY. This is the backend this package's own tests run against, and
/// it is deliberately NOT part of the published package: consumers build
/// their own backend against the contracts in `package:sku_catalog`.
library;

export 'memory_device_repository.dart';
export 'memory_device_type_repository.dart';
export 'memory_image_repository.dart';
export 'memory_locate_repository.dart';
export 'memory_manufacturer_repository.dart';
export 'memory_meta_repository.dart';
export 'memory_sku_component_repository.dart';
export 'memory_trait_attribute_definition_repository.dart';
export 'memory_trait_repository.dart';
export 'memory_unit_of_work.dart';
