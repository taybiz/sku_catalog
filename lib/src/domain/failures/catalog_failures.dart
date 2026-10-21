import 'package:equatable/equatable.dart';

/// The shared root of the failure vocabulary — the catalog's failures and a
/// product's own alike.
///
/// Deliberately `abstract base` rather than `sealed`. A sealed class may only be
/// extended from its own library, and this type is what the catalog's contracts
/// are typed against, so a consumer's own failure family cannot live inside this
/// package: sealing the root would hand a product's domain layer a closed set it
/// does not own, and force a translation at every call into the catalog instead
/// of one at its edge. `base` still keeps the root from being implemented from
/// outside, so the hierarchy stays a family of classes rather than an interface
/// anybody can fake.
///
/// The set that IS closed is [CatalogFailure] below — every way this package can
/// fail. Switch over that for the catalog's own leaves; extend this root to add
/// a product's.
///
/// The UI ring converts these to exceptions. Never thrown from the bulls-eye.
abstract base class DomainFailure extends Equatable {
  /// Message describing what went wrong.
  final String message;

  /// Creates a [DomainFailure].
  const DomainFailure(this.message);

  @override
  List<Object> get props => [message];
}

/// Every way this package can fail, as one closed set.
///
/// `sealed`, so its leaves are exhaustively switchable: a consumer (or this
/// package's own code) can list every failure a catalog operation can return and
/// let the analyzer prove the list complete. A product's own failures are
/// siblings of this class under [DomainFailure], not members of it — the set is
/// closed so that it can be enumerated, not so that it can be extended from
/// here.
sealed class CatalogFailure extends DomainFailure {
  /// Creates a [CatalogFailure].
  const CatalogFailure(super.message);
}

/// A requested entity was not found.
final class NotFoundFailure extends CatalogFailure {
  /// Creates a [NotFoundFailure].
  const NotFoundFailure(super.message);
}

/// An entity that would create a duplicate already exists.
final class AlreadyExistsFailure extends CatalogFailure {
  /// Creates an [AlreadyExistsFailure].
  const AlreadyExistsFailure(super.message);
}

/// An operation would create a circular dependency in the graph.
final class WouldCreateCycleFailure extends CatalogFailure {
  /// Creates a [WouldCreateCycleFailure].
  const WouldCreateCycleFailure(super.message);
}

/// Input data is invalid.
final class InvalidInputFailure extends CatalogFailure {
  /// Creates an [InvalidInputFailure].
  const InvalidInputFailure(super.message);
}

/// The caller lacks permission for this operation.
final class PermissionDeniedFailure extends CatalogFailure {
  /// Creates a [PermissionDeniedFailure].
  const PermissionDeniedFailure(super.message);
}

/// The operation failed because the entity is still in use.
final class InUseFailure extends CatalogFailure {
  /// Creates an [InUseFailure].
  const InUseFailure(super.message);
}

/// An unexpected internal error occurred.
final class InternalFailure extends CatalogFailure {
  /// Creates an [InternalFailure].
  const InternalFailure(super.message);
}

/// Network or IO failure when accessing a datasource.
final class DatasourceFailure extends CatalogFailure {
  /// Creates a [DatasourceFailure].
  const DatasourceFailure(super.message);
}

/// Serialization/deserialization failure.
final class SerializationFailure extends CatalogFailure {
  /// Creates a [SerializationFailure].
  const SerializationFailure(super.message);
}

/// A value for an attribute marked unique is already held by another instance.
///
/// Raised on the instance write path by `AssertUniqueAttributeValues`: a unique
/// attribute identifies one article, so a second article claiming the same value
/// is a duplicate, not a variation.
final class DuplicateAttributeValueFailure extends CatalogFailure {
  /// Creates a [DuplicateAttributeValueFailure].
  const DuplicateAttributeValueFailure(super.message);
}
