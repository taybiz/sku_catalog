import '../domain/domain.dart';
import 'package:fpdart/fpdart.dart';

/// Delete a trait by id, blocked while it has child traits or is attached to
/// SKUs, manufacturers, or locates; its attribute definitions cascade.
///
/// The cascade is two writes and the guards read four other stores, so the
/// transaction is a **required** dependency: a store that cannot roll back is
/// wired with `noOpUnitOfWork` and says so at the composition root.
class DeleteTrait {
  /// Creates a [DeleteTrait] use case.
  const DeleteTrait({
    required ITraitRepository traitRepository,
    required ISkuRepository skuRepository,
    required IManufacturerRepository manufacturerRepository,
    required ILocateRepository locateRepository,
    required ITraitAttributeDefinitionRepository traitAttributeRepository,
    required UnitOfWork unitOfWork,
  }) : _traitRepository = traitRepository,
       _skuRepository = skuRepository,
       _manufacturerRepository = manufacturerRepository,
       _locateRepository = locateRepository,
       _traitAttributeRepository = traitAttributeRepository,
       _unitOfWork = unitOfWork;

  final ITraitRepository _traitRepository;
  final ISkuRepository _skuRepository;
  final IManufacturerRepository _manufacturerRepository;
  final ILocateRepository _locateRepository;
  final ITraitAttributeDefinitionRepository _traitAttributeRepository;
  final UnitOfWork _unitOfWork;

  /// Executes the use case.
  TaskEither<DomainFailure, void> call({required String id}) => TaskEither(
    () => _unitOfWork<DomainFailure, void>(
      body: () => _traitRepository.fetchAll().flatMap((traits) {
        if (traits.any((t) => t.parentTraitId == id)) {
          return TaskEither<DomainFailure, void>.left(
            InUseFailure('This trait has child traits.'),
          );
        }
        return _skuRepository.fetchAll().flatMap((types) {
          if (types.any((t) => t.traitIds.contains(id))) {
            return TaskEither<DomainFailure, void>.left(
              InUseFailure('This trait is attached to one or more SKUs.'),
            );
          }
          return _manufacturerRepository.fetchAll().flatMap((manufacturers) {
            if (manufacturers.any((m) => m.traitIds.contains(id))) {
              return TaskEither<DomainFailure, void>.left(
                InUseFailure(
                  'This trait is attached to one or more manufacturers.',
                ),
              );
            }
            return _locateRepository.fetchAll().flatMap((locates) {
              if (locates.any((l) => l.traitIds.contains(id))) {
                return TaskEither<DomainFailure, void>.left(
                  InUseFailure(
                    'This trait is attached to one or more locates.',
                  ),
                );
              }
              return _traitAttributeRepository
                  .fetchByTrait(traitId: id)
                  .flatMap(
                    (attrs) => sequenceTaskEither(
                      tasks: [
                        for (final a in attrs)
                          _traitAttributeRepository.delete(id: a.meta.id),
                      ],
                    ),
                  )
                  .flatMap((_) => _traitRepository.delete(id: id));
            });
          });
        });
      }).run(),
    ),
  );
}
