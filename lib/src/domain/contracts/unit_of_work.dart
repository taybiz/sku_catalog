import 'package:fpdart/fpdart.dart';

/// Transaction seam — transactional adapters implement it over their store.
///
/// The unit of work is the only place a multi-write operation can be made
/// atomic. A store that cannot roll back implements it as [NoOpUnitOfWork] and
/// callers pass nothing.
///
/// **Rollback is triggered by a thrown error, not by a returned failure.** Turn
/// a `Left` into a throw inside [run] or nothing rolls back — which is exactly
/// what [UnitOfWorkEither.runEither] does for you.
abstract interface class IUnitOfWork {
  /// Runs [work] inside the store's transaction.
  Future<T> run<T>(Future<T> Function() work);
}

/// Running a failure-returning body in a unit of work.
///
/// This codebase reports problems as values (`TaskEither<DomainFailure, T>`),
/// but a unit of work rolls back on a *thrown* error. Without a bridge, a body
/// that returns `Left` would commit half its writes — the bug this extension
/// exists to prevent.
extension UnitOfWorkEither on IUnitOfWork {
  /// Runs [body] in this unit of work. If it returns a `Left`, the transaction
  /// is rolled back and that failure is returned as a `Left`.
  ///
  /// ```dart
  /// final result = await uow.runEither(() async {
  ///   await firstWrite().run();
  ///   return secondWrite().run();
  /// });
  /// ```
  Future<Either<F, T>> runEither<F, T>(
    Future<Either<F, T>> Function() body,
  ) async {
    try {
      return await run(() async {
        final result = await body();
        return result.fold(
          (failure) => throw _Rollback<F>(failure),
          Right<F, T>.new,
        );
      });
    } on _Rollback<F> catch (rolled) {
      return Left<F, T>(rolled.failure);
    }
  }
}

/// Carries a failed body out of [UnitOfWorkEither.runEither] so the unit of work
/// sees an error and rolls back.
class _Rollback<F> implements Exception {
  _Rollback(this.failure);

  final F failure;
}
