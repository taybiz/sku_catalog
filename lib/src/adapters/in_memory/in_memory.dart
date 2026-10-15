/// The reference in-memory backend: ten stores implementing the repository
/// contracts, a transaction over them, and a catalog that wires the model's rules
/// and operations over both.
///
/// It is an example, not a product: nothing here is durable, indexed or
/// thread-safe. Reach it through `package:sku_catalog/in_memory.dart`.
library;

export 'in_memory_catalog.dart';
export 'in_memory_image_repository.dart';
export 'in_memory_instance_repository.dart';
export 'in_memory_locate_repository.dart';
export 'in_memory_manufacturer_repository.dart';
export 'in_memory_meta_repository.dart';
export 'in_memory_sku_association_repository.dart';
export 'in_memory_sku_component_repository.dart';
export 'in_memory_sku_repository.dart';
export 'in_memory_table.dart';
export 'in_memory_trait_attribute_definition_repository.dart';
export 'in_memory_trait_repository.dart';
export 'in_memory_unit_of_work.dart';
