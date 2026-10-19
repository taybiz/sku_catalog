import 'package:fpdart/fpdart.dart';

import '../domain/domain.dart';

/// Fails with [AlreadyExistsFailure] when another model from the same
/// manufacturer already carries [modelNumber].
///
/// A model number is the maker's **production number** — an identifier, not a
/// label — so the comparison here is exact: `QO120` and `qo120` are two different
/// numbers, unlike an instance name, which `namesClash` compares
/// case-insensitively because it is prose a person reads.
///
/// The rule lives here so every SKU write path shares one implementation, and the
/// copy path ([DuplicateSku]) mints a number that already satisfies it
/// (`uniqueCopyModelNumber`) rather than being refused after the fact.
class AssertUniqueModelNumber {
  /// Creates an [AssertUniqueModelNumber] use case.
  const AssertUniqueModelNumber(this._repository);

  final ISkuRepository _repository;

  /// Executes the use case: checks [modelNumber] against [manufacturerId],
  /// ignoring the model [excludeId] when an existing SKU keeps or edits its own
  /// number.
  TaskEither<DomainFailure, Unit> call({
    required String modelNumber,
    required String manufacturerId,
    String? excludeId,
  }) => _repository.fetchAll().flatMap((all) {
    final clash = all.any(
      (sku) =>
          sku.meta.id != excludeId &&
          sku.manufacturerId == manufacturerId &&
          sku.modelNumber == modelNumber,
    );
    if (clash) {
      return TaskEither<DomainFailure, Unit>.left(
        AlreadyExistsFailure(
          'Manufacturer "$manufacturerId" already makes a model numbered '
          '"$modelNumber"',
        ),
      );
    }
    return TaskEither<DomainFailure, Unit>.of(unit);
  });
}
