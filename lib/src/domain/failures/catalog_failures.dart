import 'package:equatable/equatable.dart';

/// Base of this layer's failure hierarchy — every way the catalog can fail.
///
/// `sealed`, so the leaves are exhaustively switchable: a consumer can list
/// every failure this package can return and let the analyzer prove the list
/// complete. A product that needs its own failure adds a `final class` here (or
/// keeps a separate hierarchy) rather than descending from outside — a root
/// that any library could extend could never be switched over exhaustively.
///
/// The UI ring converts these to exceptions. Never thrown from the bulls-eye.
sealed class DomainFailure extends Equatable {
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
