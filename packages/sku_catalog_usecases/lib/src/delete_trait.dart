import 'package:sku_catalog_domain/sku_catalog_domain.dart';
import 'package:fpdart/fpdart.dart';

import 'sequence.dart';

/// Delete a trait by id, blocked while it has child traits or is attached to
/// SKUs, manufacturers, or locates; its attribute definitions cascade.
class DeleteTrait {
  /// Creates a [DeleteTrait] use case.
  const DeleteTrait({
    required ITraitRepository traitRepository,
    required IDeviceTypeRepository deviceTypeRepository,
    required IManufacturerRepository manufacturerRepository,
    required ILocateRepository locateRepository,
    required ITraitAttributeDefinitionRepository traitAttributeRepository,
  }) : _traitRepository = traitRepository,
       _deviceTypeRepository = deviceTypeRepository,
       _manufacturerRepository = manufacturerRepository,
       _locateRepository = locateRepository,
       _traitAttributeRepository = traitAttributeRepository;

  final ITraitRepository _traitRepository;
  final IDeviceTypeRepository _deviceTypeRepository;
  final IManufacturerRepository _manufacturerRepository;
  final ILocateRepository _locateRepository;
  final ITraitAttributeDefinitionRepository _traitAttributeRepository;

  /// Executes the use case.
  TaskEither<DomainFailure, void> call(String id) =>
      _traitRepository.fetchAll().flatMap((traits) {
        if (traits.any((t) => t.parentTraitId == id)) {
          return TaskEither.left(InUseFailure('This trait has child traits.'));
        }
        return _deviceTypeRepository.fetchAll().flatMap((types) {
          if (types.any((t) => t.traitIds.contains(id))) {
            return TaskEither.left(
              InUseFailure('This trait is attached to one or more SKUs.'),
            );
          }
          return _manufacturerRepository.fetchAll().flatMap((manufacturers) {
            if (manufacturers.any((m) => m.traitIds.contains(id))) {
              return TaskEither.left(
                InUseFailure(
                  'This trait is attached to one or more manufacturers.',
                ),
              );
            }
            return _locateRepository.fetchAll().flatMap((locates) {
              if (locates.any((l) => l.traitIds.contains(id))) {
                return TaskEither.left(
                  InUseFailure(
                    'This trait is attached to one or more locates.',
                  ),
                );
              }
              return _traitAttributeRepository
                  .fetchByTrait(id)
                  .flatMap(
                    (attrs) => sequenceTaskEither([
                      for (final a in attrs)
                        _traitAttributeRepository.delete(a.meta.id),
                    ]),
                  )
                  .flatMap((_) => _traitRepository.delete(id));
            });
          });
        });
      });
}
