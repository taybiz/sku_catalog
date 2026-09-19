/// The catalog model — entities, enums, value objects, failures and the
/// repository contracts.
///
/// No operations live here, and no storage: implement the contracts over
/// whatever you have, and reach the operations through the front door,
/// `package:sku_catalog/sku_catalog.dart`.
///
/// Presents FP-style tuples: every repository method and use case call returns a
/// fpdart `TaskEither<DomainFailure, T>`; call `.run()` for a
/// `Future<Either<DomainFailure, T>>`.
library;

export 'json_coercion.dart';
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
export 'failures/catalog_failures.dart';
export 'value_objects/device_report_property.dart';
export 'value_objects/resolved_attribute.dart';
export 'contracts/contracts.dart';
export 'contracts/device_repository.dart';
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
