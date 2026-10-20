// A tour of what a consumer writes: implement the repository contracts over your
// own storage, wire the rules, run the operations.
//
// `sku_catalog` ships no storage, so there is nothing to import but the package
// itself. The two stores below keep their rows in `Map`s for the sake of a single
// runnable file; a real one is a database or a file, and the shape it has to
// satisfy is the contract. The reference implementation worth reading next lives in
// the repository at `lib/src/adapters/in_memory/`.
//
//   dart run example/sku_catalog_example.dart
import 'package:fpdart/fpdart.dart';
import 'package:sku_catalog/sku_catalog.dart';

Future<void> main() async {
  final skus = SkuStore();
  final parts = SkuComponentStore();

  // A transaction over both tables. `transaction` below is the smallest thing that
  // can be called a unit of work; the four rules a real adapter has to get right
  // are on the `UnitOfWork` type.
  final unitOfWork = transaction([skus.rows, parts.rows]);

  // Wire the rules once and share them: a rule that reads a store is built where
  // the store is, and every path that writes that entity takes the same one.
  final createSku = CreateSku(
    skuRepository: skus,
    assertUniqueModelNumber: AssertUniqueModelNumber(skus),
  );
  final addComponent = AddSkuComponent(
    repository: parts,
    skuRepository: skus,
    unitOfWork: unitOfWork,
  );

  // A failure is a value: `.run()` hands back an `Either`, and nothing threw.
  final panel = Sku(
    meta: newMeta(),
    manufacturerId: 'square-d',
    modelNumber: 'QO-16',
  );
  final breaker = Sku(
    meta: newMeta(),
    manufacturerId: 'square-d',
    modelNumber: 'QO120',
  );
  print(
    'create     ${_show(await createSku(sku: panel).run(), 'stored QO-16')}',
  );
  print(
    'create     ${_show(await createSku(sku: breaker).run(), 'stored QO120')}',
  );

  // A model number is unique per maker, so the same one twice is refused — on
  // create as much as on update. A create is not a back door.
  final clash = await createSku(sku: panel.copyWith(meta: newMeta())).run();
  print('duplicate  ${_show(clash, 'allowed — BUG')}');

  // Assemble. This writes once, but it decides by reading the graph first, which is
  // why it takes the transaction: on a store that can lock, the check and the edge
  // are one step.
  final edge = await addComponent(
    parentSkuId: panel.meta.id,
    childSkuId: breaker.meta.id,
    quantity: 8,
  ).run();
  print('assemble   ${_show(edge, '8 × QO120 under QO-16')}');

  // ...and the reverse edge would close a loop, so the guard refuses it.
  final loop = await addComponent(
    parentSkuId: breaker.meta.id,
    childSkuId: panel.meta.id,
    quantity: 1,
  ).run();
  print('cycle      ${_show(loop, 'allowed — BUG')}');

  // Drive the seam yourself when you write more than once: a `Left` undoes
  // everything the body wrote, and the failure comes back untouched.
  final undone = await unitOfWork<DomainFailure, String>(
    body: () async {
      await parts
          .create(
            component: SkuComponent(
              meta: newMeta(),
              parentSkuId: panel.meta.id,
              childSkuId: breaker.meta.id,
              quantity: 99,
            ),
          )
          .run();
      return const Left(InvalidInputFailure('changed my mind'));
    },
  );
  final leftTheNinetyNine = (await parts.fetchAll().run())
      .getOrElse((_) => [])
      .any((component) => component.quantity == 99);
  print(
    'rollback   ${_show(undone, 'committed — unexpected')}  '
    '(the 99 is gone: ${!leftTheNinetyNine})',
  );

  // Read the catalog back, and ask what a build consumes. Nothing here throws.
  final stored = (await FetchAllSkus(skus)().run()).getOrElse((_) => []);
  print('skus       ${stored.map((s) => s.modelNumber).join(', ')}');

  final bom = await AggregateBillOfMaterials(
    skuRepository: skus,
    skuComponentRepository: parts,
  )(skuId: panel.meta.id, units: 2).run();
  print(
    'parts      2 × ${panel.modelNumber} → '
    '${bom.fold((failure) => 'failed: ${failure.message}', (bill) => bill.lines.map((line) => '${line.quantity} × ${line.modelNumber}').join(', '))}',
  );
}

String _show(Either<DomainFailure, Object?> result, String whenOk) =>
    result.fold((failure) => 'refused (${failure.message})', (_) => whenOk);

/// A SKU store over a `Map`, keeping rows as the wire form the model round-trips —
/// the form an adapter should persist, so a record written before a field existed
/// still parses.
class SkuStore implements ISkuRepository {
  /// The rows, by id. Public because a transaction snapshots them.
  final Map<String, Map<String, dynamic>> rows = {};

  @override
  TaskEither<DomainFailure, List<Sku>> fetchAll() =>
      TaskEither.of([for (final row in rows.values) Sku.fromJson(row)]);

  @override
  TaskEither<DomainFailure, List<Sku>> fetchByManufacturer({
    required String manufacturerId,
  }) => TaskEither.of([
    for (final row in rows.values)
      if (Sku.fromJson(row).manufacturerId == manufacturerId) Sku.fromJson(row),
  ]);

  @override
  TaskEither<DomainFailure, Sku> fetchById({required String id}) {
    final row = rows[id];
    return row == null
        ? TaskEither.left(NotFoundFailure('No SKU is stored under "$id"'))
        : TaskEither.of(Sku.fromJson(row));
  }

  @override
  TaskEither<DomainFailure, Sku> create({required Sku sku}) {
    if (rows.containsKey(sku.meta.id)) {
      return TaskEither.left(
        AlreadyExistsFailure('"${sku.meta.id}" is already stored'),
      );
    }
    rows[sku.meta.id] = sku.toJson();
    return TaskEither.of(sku);
  }

  @override
  TaskEither<DomainFailure, Sku> update({required Sku sku}) {
    if (!rows.containsKey(sku.meta.id)) {
      return TaskEither.left(
        NotFoundFailure('No SKU is stored under "${sku.meta.id}"'),
      );
    }
    rows[sku.meta.id] = sku.toJson();
    return TaskEither.of(sku);
  }

  @override
  TaskEither<DomainFailure, void> delete({required String id}) {
    if (rows.remove(id) == null) {
      return TaskEither.left(NotFoundFailure('No SKU is stored under "$id"'));
    }
    return TaskEither.of(null);
  }
}

/// The same, for assembly edges. The contract has no `update`: an edge's quantity is
/// changed by deleting it and creating the replacement, which is two writes and
/// therefore a transaction.
class SkuComponentStore implements ISkuComponentRepository {
  /// The rows, by id. Public because a transaction snapshots them.
  final Map<String, Map<String, dynamic>> rows = {};

  @override
  TaskEither<DomainFailure, List<SkuComponent>> fetchAll() => TaskEither.of([
    for (final row in rows.values) SkuComponent.fromJson(row),
  ]);

  @override
  TaskEither<DomainFailure, List<SkuComponent>> fetchBySku({
    required String skuId,
  }) => TaskEither.of([
    for (final row in rows.values)
      if (row['parent_sku_id'] == skuId) SkuComponent.fromJson(row),
  ]);

  @override
  TaskEither<DomainFailure, SkuComponent> fetchById({required String id}) {
    final row = rows[id];
    return row == null
        ? TaskEither.left(NotFoundFailure('No edge is stored under "$id"'))
        : TaskEither.of(SkuComponent.fromJson(row));
  }

  @override
  TaskEither<DomainFailure, SkuComponent> create({
    required SkuComponent component,
  }) {
    if (rows.containsKey(component.meta.id)) {
      return TaskEither.left(
        AlreadyExistsFailure('"${component.meta.id}" is already stored'),
      );
    }
    rows[component.meta.id] = component.toJson();
    return TaskEither.of(component);
  }

  @override
  TaskEither<DomainFailure, void> delete({required String id}) {
    if (rows.remove(id) == null) {
      return TaskEither.left(NotFoundFailure('No edge is stored under "$id"'));
    }
    return TaskEither.of(null);
  }
}

/// A unit of work over `Map` rows: snapshot every table, run the body, and put the
/// tables back if it answers `Left`.
///
/// A real adapter hands this job to its store's own transaction — `BEGIN IMMEDIATE`
/// on SQLite, a session elsewhere — and the rules for doing that are on `UnitOfWork`
/// itself. What matters here is the shape: a `Left` means undo, and the adapter is
/// the only code that can.
UnitOfWork transaction(List<Map<String, Map<String, dynamic>>> tables) =>
    <F, T>({required Future<Either<F, T>> Function() body}) async {
      final snapshots = [
        for (final table in tables)
          Map<String, Map<String, dynamic>>.from(table),
      ];
      final result = await body();
      if (result.isLeft()) {
        for (var i = 0; i < tables.length; i++) {
          tables[i]
            ..clear()
            ..addAll(snapshots[i]);
        }
      }
      return result;
    };
