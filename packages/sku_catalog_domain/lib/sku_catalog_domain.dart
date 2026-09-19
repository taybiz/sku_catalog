/// The catalog model — entities, enums, value objects, failures and the
/// repository contracts.
///
/// No operations live here, and no storage: implement the contracts over
/// whatever you have, or depend on `sku_catalog_usecases` for the operations.
///
/// Every repository method and use case call returns a fpdart
/// `TaskEither<DomainFailure, T>`; call `.run()` for a
/// `Future<Either<DomainFailure, T>>`.
library;

export 'src/json_coercion.dart';
export 'src/entities/device.dart';
export 'src/entities/device_type.dart';
export 'src/entities/image_record.dart';
export 'src/entities/locate.dart';
export 'src/entities/manufacturer.dart';
export 'src/entities/meta.dart';
export 'src/entities/sku_component.dart';
export 'src/entities/trait.dart';
export 'src/entities/trait_attribute_definition.dart';
export 'src/enums/data_type.dart';
export 'src/enums/image_owner.dart';
export 'src/enums/trait_scope.dart';
export 'src/failures/catalog_failures.dart';
export 'src/value_objects/device_report_property.dart';
export 'src/value_objects/resolved_attribute.dart';
export 'src/contracts/contracts.dart';
export 'src/contracts/device_repository.dart';
export 'src/contracts/device_type_repository.dart';
export 'src/contracts/image_repository.dart';
export 'src/contracts/locate_repository.dart';
export 'src/contracts/manufacturer_repository.dart';
export 'src/contracts/meta_repository.dart';
export 'src/contracts/no_op_unit_of_work.dart';
export 'src/contracts/sku_component_repository.dart';
export 'src/contracts/trait_attribute_definition_repository.dart';
export 'src/contracts/trait_repository.dart';
export 'src/contracts/unit_of_work.dart';
