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
/// `class … implements` gave, at the exact signature rather than at the member set.
/// [noOpUnitOfWork] is the honest default.
///
/// ## The four rules for a transactional adapter
///
/// Measured against SQLite, and they generalise to any store with a single writer:
///
/// - **Take the write lock when the unit opens, not at its first write.** On SQLite
///   that is `BEGIN IMMEDIATE` rather than the deferred default: a deferred unit
///   reads an unprotected snapshot, so a rule's check can be beaten by a concurrent
///   writer and the loss surfaces as a store error (`database is locked`) instead of
///   a domain failure. Holding the lock from the start is what makes a check and the
///   write that follows it one step, which is why the rule-carrying operations take
///   this seam at all.
/// - **Route every repository call through the open transaction, reads included.**
///   The repositories are never handed the unit of work, so the adapter publishes it
///   for the duration and clears it in a `finally`. A read on another connection does
///   not hang — it answers from the *pre-transaction* snapshot, which is worse for a
///   check than a failure would be, because nothing reports it.
/// - **Treat a busy store as "this unit did not happen" and retry the whole unit.**
///   SQLite rolls the transaction back on a failed lock upgrade in journal mode and
///   leaves it open in WAL, so an adapter must not assume either state; set a busy
///   timeout or retry with a bound. Rollback is a *value* here, but retry is the
///   adapter's business.
/// - **Re-entrance means joining the open unit, not opening a second one.** A
///   consumer may run a catalog write inside their own unit of work — that is what
///   this seam is for. If one is already open on this client, run the body inside it
///   rather than starting another: SQLite answers a nested `BEGIN` with "cannot start
///   a transaction within a transaction". Reach for a `SAVEPOINT` only when the inner
///   unit must roll back on its own. (drift's `transaction()` already nests via
///   savepoints and absorbs this; raw `package:sqlite3` leaves the branch to you.)
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
