/// The reference in-memory backend: eleven stores implementing the repository
/// contracts, a transaction over them, and a catalog that wires the model's rules
/// and operations over both.
///
/// It is an example, not a product: nothing here is durable, indexed or
/// thread-safe. In a clone of this repository it is reachable through
/// `package:sku_catalog/in_memory.dart`; it is **not** in the published archive,
/// because storage belongs to the implementer and the package does not ship one.
library;

export 'in_memory_catalog.dart';
export 'in_memory_image_repository.dart';
export 'in_memory_instance_association_repository.dart';
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
