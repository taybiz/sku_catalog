/// The catalog model: what a thing is, what can be said about it, what it is
/// made of, and where it sits.
///
/// This library is the whole domain half — entities, value objects, enums,
/// failures and repository contracts. It imports nothing but
/// `package:equatable` and `package:fpdart`.
library;

export 'entities/device.dart';
export 'entities/device_type.dart';
export 'entities/image_record.dart';
export 'entities/locate.dart';
export 'entities/manufacturer.dart';
export 'entities/meta.dart';
export 'entities/sku_component.dart';
export 'entities/trait.dart';
export 'entities/trait_attribute_definition.dart';
export 'enums/data_type.dart';
export 'enums/image_owner.dart';
export 'enums/trait_scope.dart';
export 'value_objects/device_report_property.dart';
export 'value_objects/resolved_attribute.dart';
export 'failures/catalog_failures.dart';
export 'contracts/contracts.dart';
export 'contracts/device_type_repository.dart';
export 'contracts/image_repository.dart';
export 'contracts/locate_repository.dart';
export 'contracts/manufacturer_repository.dart';
export 'contracts/meta_repository.dart';
export 'contracts/no_op_unit_of_work.dart';
export 'contracts/sku_component_repository.dart';
export 'contracts/trait_attribute_definition_repository.dart';
export 'contracts/trait_repository.dart';
export 'contracts/unit_of_work.dart';
