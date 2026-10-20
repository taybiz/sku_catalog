import 'package:fpdart/fpdart.dart';

/// Transaction seam — a transactional adapter implements it over its store.
///
/// The unit of work is the only place a multi-write operation can be made atomic.
/// It is a **function**, not a class, because that is all it ever was: take a
/// body, run it, answer with the body's own `Either`.
///
/// **Rollback is a value, not an exception.** A `Left` means "undo the writes";
/// the adapter — the only code that owns a transaction — does the undoing.
/// Nothing in the domain ever throws.
///
/// Generic in `F` and `T` on purpose: `F` is the *caller's* failure type, so an
/// app can run a catalog operation inside its own unit of work and keep its own
/// failures, and `T` can carry a value back out of the transaction.
///
/// The body's shape is `Future<Either<F, T>> Function()` and the result is that
/// same `Future<Either<F, T>>` — which is exactly what `TaskEither`'s raw
/// constructor takes, so a use case reads
/// `TaskEither(() => _unitOfWork<DomainFailure, void>(body: …))` with nothing
/// wrapped around it. A transaction is not lazy: it runs now, and handing back
/// the finished `Either` keeps it from becoming a value a caller could hold past
/// its own commit.
///
/// An adapter writes one as a closure over its client, and the closure is checked
/// against this type where it is handed over — the same compile-time guarantee a
/// `class … implements` gave, at the exact signature rather than at the member
/// set. [noOpUnitOfWork] is the honest default.
typedef UnitOfWork =
    Future<Either<F, T>> Function<F, T>({
      required Future<Either<F, T>> Function() body,
    });

/// The unit of work for a store that cannot roll back: it just runs the body.
///
/// This is the default of every use case that takes a [UnitOfWork], so a caller
/// whose store has no transactions passes nothing and pays nothing. It is the
/// honest implementation rather than a silent success: a half-finished write is
/// possible, and the store's atomicity — or its absence — is what the caller
/// gets.
Future<Either<F, T>> noOpUnitOfWork<F, T>({
  required Future<Either<F, T>> Function() body,
}) => body();
