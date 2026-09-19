import 'package:equatable/equatable.dart';

/// Base class for all domain failures, product-agnostic ones and a product's
/// own alike.
///
/// Deliberately `abstract base` rather than `sealed`. A sealed class may only be
/// extended from its own library, and this type is the shared root every
/// product's failure family descends from — the catalog contracts are typed
/// against it, so it cannot live inside one product. Nothing in the estate
/// switches exhaustively over [DomainFailure]; consumers read [message].
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

/// A requested entity was not found.
final class NotFoundFailure extends DomainFailure {
  /// Creates a [NotFoundFailure].
  const NotFoundFailure(super.message);
}

/// An entity that would create a duplicate already exists.
final class AlreadyExistsFailure extends DomainFailure {
  /// Creates an [AlreadyExistsFailure].
  const AlreadyExistsFailure(super.message);
}

/// An operation would create a circular dependency in the graph.
final class WouldCreateCycleFailure extends DomainFailure {
  /// Creates a [WouldCreateCycleFailure].
  const WouldCreateCycleFailure(super.message);
}

/// Input data is invalid.
final class InvalidInputFailure extends DomainFailure {
  /// Creates an [InvalidInputFailure].
  const InvalidInputFailure(super.message);
}

/// The caller lacks permission for this operation.
final class PermissionDeniedFailure extends DomainFailure {
  /// Creates a [PermissionDeniedFailure].
  const PermissionDeniedFailure(super.message);
}

/// The operation failed because the entity is still in use.
final class InUseFailure extends DomainFailure {
  /// Creates an [InUseFailure].
  const InUseFailure(super.message);
}

/// An unexpected internal error occurred.
final class InternalFailure extends DomainFailure {
  /// Creates an [InternalFailure].
  const InternalFailure(super.message);
}

/// Network or IO failure when accessing a datasource.
final class DatasourceFailure extends DomainFailure {
  /// Creates a [DatasourceFailure].
  const DatasourceFailure(super.message);
}

/// Serialization/deserialization failure.
final class SerializationFailure extends DomainFailure {
  /// Creates a [SerializationFailure].
  const SerializationFailure(super.message);
}
