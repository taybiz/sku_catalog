import 'package:fpdart/fpdart.dart';

import '../entities/meta.dart';
import '../failures/catalog_failures.dart';

/// Contract for meta (bundle metadata) persistence.
abstract interface class IMetaRepository {
  /// Fetch the current meta.
  TaskEither<DomainFailure, Meta> fetch();

  /// Update meta.
  TaskEither<DomainFailure, Meta> update({required Meta meta});

  /// Remove the current meta (factory reset support).
}
