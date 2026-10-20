import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/in_memory.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'package:test/test.dart';

/// A model number is the manufacturer's **production number**: an identifier,
/// unique against the maker it came from — not a label and not a name. So it is
/// compared exactly (`QO120` is not `qo120`), and two models of one maker cannot
/// share one.
///
/// What the maker *calls* the thing, when that differs from the production
/// number, is a different fact and no longer a field: it is optional and carries
/// no rule, so a consumer declares it as a trait.
void main() {
  Meta meta(String id) => Meta(
    id: id,
    notes: '',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  );

  Sku sku(String id, {String maker = 'square-d', String number = 'QO120'}) =>
      Sku(meta: meta(id), manufacturerId: maker, modelNumber: number);

  late InMemorySkuRepository skus;
  late AssertUniqueModelNumber rule;

  CreateSku create() =>
      CreateSku(skuRepository: skus, assertUniqueModelNumber: rule);

  UpdateSku update() =>
      UpdateSku(skuRepository: skus, assertUniqueModelNumber: rule);

  setUp(() {
    skus = InMemorySkuRepository();
    rule = AssertUniqueModelNumber(skus);
  });

  test(
    'a second number from the same maker is refused, and not stored',
    () async {
      (await create()(sku: sku('qo120')).run()).isRight().should.beTrue();

      final second = await create()(sku: sku('qo120-b', number: 'QO120')).run();

      second
          .fold((failure) => failure, (_) => fail('expected Left'))
          .should
          .beAssignableTo<AlreadyExistsFailure>();
      (await skus.fetchAll().run()).getOrElse((_) => []).should.haveCount(1);
    },
  );

  test('the same number from another maker is a different model', () async {
    (await create()(sku: sku('qo120')).run()).isRight().should.beTrue();

    final other = await create()(
      sku: sku('qo120-ge', maker: 'general', number: 'QO120'),
    ).run();

    other.isRight().should.beTrue();
    (await skus.fetchAll().run()).getOrElse((_) => []).should.haveCount(2);
  });

  test(
    'the comparison is exact: case and padding are not the same number',
    () async {
      (await create()(sku: sku('qo120')).run()).isRight().should.beTrue();

      // A production number is an identifier, not a human label: `qo120` is a
      // different string from `QO120`, unlike an instance name compared with
      // `namesClash`.
      (await create()(
        sku: sku('lower', number: 'qo120'),
      ).run()).isRight().should.beTrue();
      (await create()(
        sku: sku('padded', number: ' QO120'),
      ).run()).isRight().should.beTrue();
    },
  );

  test(
    'renaming a model onto a number the maker already uses is refused',
    () async {
      await create()(sku: sku('a', number: 'QO120')).run();
      await create()(sku: sku('b', number: 'QO130')).run();

      final renamed = await update()(sku: sku('b', number: 'QO120')).run();

      renamed
          .fold((failure) => failure, (_) => fail('expected Left'))
          .should
          .beAssignableTo<AlreadyExistsFailure>();
      (await skus.fetchById(id: 'b').run())
          .getOrElse((_) => fail('expected Right'))
          .modelNumber
          .should
          .be('QO130');
    },
  );

  test('a model keeping its own number is not a clash with itself', () async {
    await create()(sku: sku('a')).run();

    final kept = await update()(
      sku: sku('a').copyWith(attributeValues: const {'rated_amps': 20}),
    ).run();

    kept.isRight().should.beTrue();
  });

  test('deleting a model frees its number for the maker', () async {
    await create()(sku: sku('a')).run();
    (await DeleteSku(
      unitOfWork: noOpUnitOfWork,
      skuRepository: skus,
      instanceRepository: InMemoryInstanceRepository(),
      skuComponentRepository: InMemorySkuComponentRepository(),
    )(id: 'a').run()).isRight().should.beTrue();

    (await create()(sku: sku('b')).run()).isRight().should.beTrue();
  });

  test('a copy mints the next free number instead of clashing', () async {
    await create()(sku: sku('a')).run();

    final first = await DuplicateSku(skus)(id: 'a').run();
    first
        .getOrElse((_) => fail('expected Right'))
        .modelNumber
        .should
        .be('QO120 (copy)');
    // The copy is a real row, so the rule sees it: a second copy of the same
    // original cannot reuse "(copy)".
    final second = await DuplicateSku(skus)(id: 'a').run();
    second
        .getOrElse((_) => fail('expected Right'))
        .modelNumber
        .should
        .be('QO120 (copy 2)');
    (await skus.fetchAll().run()).getOrElse((_) => []).should.haveCount(3);

    // ...and every number the copies minted satisfies the rule, so a copy is
    // never refused after the fact.
    for (final row in (await skus.fetchAll().run()).getOrElse((_) => [])) {
      (await rule(
        modelNumber: row.modelNumber,
        manufacturerId: row.manufacturerId,
        excludeId: row.meta.id,
      ).run()).isRight().should.beTrue();
    }
  });

  test('the catalogue wires the rule into the SKU write paths', () async {
    final catalog = InMemoryCatalog();

    (await catalog.createSku(sku: sku('a')).run()).isRight().should.beTrue();
    final clash = await catalog.createSku(sku: sku('b')).run();

    // The rule is *wired*, not merely available.
    clash
        .fold((failure) => failure, (_) => fail('expected Left'))
        .should
        .beAssignableTo<AlreadyExistsFailure>();
  });
}
