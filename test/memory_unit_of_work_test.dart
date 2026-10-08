import 'package:fpdart/fpdart.dart';
import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'support/memory_backends.dart';
import 'package:test/test.dart';

/// The unit of work is the only thing that makes a multi-write operation atomic,
/// so it is tested like a feature rather than trusted like a utility.
void main() {
  Meta meta(String id) => Meta(
    id: id,
    notes: '',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  );

  Sku sku(String id) =>
      Sku(meta: meta(id), manufacturerId: 'm', modelNumber: id.toUpperCase());

  Future<List<String>> ids(MemorySkuRepository repo) async =>
      (await repo.fetchAll().run())
          .getOrElse((_) => [])
          .map((s) => s.meta.id)
          .toList();

  test('a Left body restores every registered store', () async {
    final skus = MemorySkuRepository();
    final locates = MemoryLocateRepository();
    await skus.create(sku('a')).run();
    final uow = MemoryUnitOfWork([skus, locates]);

    final result = await uow.runEither<DomainFailure, void>(body: () async {
      await skus.create(sku('b')).run();
      await locates.create(Locate(meta: meta('l1'), name: 'Rack 1')).run();
      return const Left<DomainFailure, void>(InUseFailure('refused'));
    });

    result.isLeft().should.beTrue();
    (await ids(skus)).should.be(['a']);
    (await locates.fetchAll().run()).getOrElse((_) => []).should.beEmpty();
  });

  test('runEither rolls back on a Left and returns the failure', () async {
    final skus = MemorySkuRepository();
    await skus.create(sku('a')).run();
    final uow = MemoryUnitOfWork([skus]);

    final result = await uow.runEither<DomainFailure, void>(body: () async {
      await skus.create(sku('b')).run();
      return const Left<DomainFailure, void>(InUseFailure('refused'));
    });

    result.isLeft().should.beTrue();
    result
        .fold((f) => f, (_) => fail('expected Left'))
        .should
        .beAssignableTo<InUseFailure>();
    (await ids(skus)).should.be(['a']);
  });

  test('a successful body commits', () async {
    final skus = MemorySkuRepository();
    final uow = MemoryUnitOfWork([skus]);

    final result = await uow.runEither<DomainFailure, void>(body: () async {
      await skus.create(sku('a')).run();
      return const Right<DomainFailure, void>(null);
    });

    result.isRight().should.beTrue();
    (await ids(skus)).should.be(['a']);
  });

  test('a store that is not registered is left alone', () async {
    final skus = MemorySkuRepository();
    final others = MemoryLocateRepository();
    final uow = MemoryUnitOfWork([skus]);

    final result = await uow.runEither<DomainFailure, void>(body: () async {
      await others.create(Locate(meta: meta('l1'), name: 'Rack 1')).run();
      return const Left<DomainFailure, void>(InUseFailure('refused'));
    });

    result.isLeft().should.beTrue();
    // Not registered, so not rolled back — the documented boundary.
    (await others.fetchAll().run()).getOrElse((_) => []).should.haveCount(1);
  });
}
