import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'support/memory_backends.dart';
import 'package:test/test.dart';

/// A SkuAssociation is a labeled, directed relationship edge: [sourceSkuId]
/// acts on [targetSkuId] in some [kind] role. Unlike SkuComponent it has no
/// quantity, no depth, no fold, and no cycle guard — an ontology of
/// `author --edited--> anthology` and `author --contributed_to--> anthology`
/// as distinct rows.
void main() {
  Meta meta(String id) => Meta(
    id: id,
    notes: '',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  );

  Sku sku(String id) =>
      Sku(meta: meta(id), manufacturerId: 'm', modelNumber: id.toUpperCase());

  late MemorySkuRepository skus;
  late MemorySkuAssociationRepository associations;

  setUp(() async {
    skus = MemorySkuRepository();
    associations = MemorySkuAssociationRepository();
  });

  test(
    'an association can be created and fetched back, direction preserved',
    () async {
      await CreateSku(skus)(sku: sku('smith')).run();
      await CreateSku(skus)(sku: sku('anthology-1')).run();

      final result = await AddSkuAssociation(
        repository: associations,
        skuRepository: skus,
        idGenerator: () => 'a1',
      )(sourceSkuId: 'smith', targetSkuId: 'anthology-1', kind: 'edited').run();
      result.isRight().should.beTrue();

      final rows = (await FetchAssociationsBySku(associations)(
        skuId: 'anthology-1',
      ).run()).getOrElse((_) => fail('expected Right'));
      rows.single.sourceSkuId.should.be('smith');
      rows.single.targetSkuId.should.be('anthology-1');
      rows.single.kind.should.be('edited');
      // The round-trip through JSON keeps the endpoints distinct, never inverted.
      final json = SkuAssociation.fromJson(rows.single.toJson());
      json.sourceSkuId.should.be('smith');
      json.targetSkuId.should.be('anthology-1');
    },
  );

  test(
    'edited and contributed_to are distinct associations, both kept',
    () async {
      await CreateSku(skus)(sku: sku('smith')).run();
      await CreateSku(skus)(sku: sku('jones')).run();
      await CreateSku(skus)(sku: sku('anthology-1')).run();

      final add = AddSkuAssociation(
        repository: associations,
        skuRepository: skus,
        idGenerator: () => 'e1',
      );
      await add(
        sourceSkuId: 'smith',
        targetSkuId: 'anthology-1',
        kind: 'edited',
      ).run();
      await AddSkuAssociation(
            repository: associations,
            skuRepository: skus,
            idGenerator: () => 'c1',
          )(
            sourceSkuId: 'jones',
            targetSkuId: 'anthology-1',
            kind: 'contributed_to',
          )
          .run();

      final rows = (await FetchAssociationsBySku(associations)(
        skuId: 'anthology-1',
      ).run()).getOrElse((_) => fail('expected Right'));
      rows.map((r) => r.kind).should.be(['edited', 'contributed_to']);
    },
  );

  test(
    'an association is returned from either end, and filterable by kind',
    () async {
      await CreateSku(skus)(sku: sku('smith')).run();
      await CreateSku(skus)(sku: sku('anthology-1')).run();

      final add = AddSkuAssociation(
        repository: associations,
        skuRepository: skus,
        idGenerator: () => 'a1',
      );
      await add(
        sourceSkuId: 'smith',
        targetSkuId: 'anthology-1',
        kind: 'edited',
      ).run();

      // Queried from the target (as before) and from the source (the other end).
      final fromTarget = (await FetchAssociationsBySku(associations)(
        skuId: 'anthology-1',
      ).run()).getOrElse((_) => fail('expected Right'));
      fromTarget.should.haveCount(1);
      final fromSource = (await FetchAssociationsBySku(associations)(
        skuId: 'smith',
      ).run()).getOrElse((_) => fail('expected Right'));
      fromSource.should.haveCount(1);

      final filtered = (await FetchAssociationsBySku(associations)(
        skuId: 'smith',
        kind: 'edited',
      ).run()).getOrElse((_) => fail('expected Right'));
      filtered.should.haveCount(1);
      final noMatch = (await FetchAssociationsBySku(associations)(
        skuId: 'smith',
        kind: 'footnoted',
      ).run()).getOrElse((_) => fail('expected Right'));
      noMatch.should.beEmpty();
    },
  );

  test('an association to a SKU that does not exist is refused', () async {
    final result = await AddSkuAssociation(
      repository: associations,
      skuRepository: skus,
    )(sourceSkuId: 'ghost', targetSkuId: 'anthology-1', kind: 'edited').run();
    result.isLeft().should.beTrue();
  });

  test('an empty kind is refused', () async {
    await CreateSku(skus)(sku: sku('smith')).run();
    await CreateSku(skus)(sku: sku('anthology-1')).run();

    final result = await AddSkuAssociation(
      repository: associations,
      skuRepository: skus,
    )(sourceSkuId: 'smith', targetSkuId: 'anthology-1', kind: '   ').run();
    result.isLeft().should.beTrue();
    result
        .fold((f) => f, (_) => fail('expected Left'))
        .should
        .beAssignableTo<InvalidInputFailure>();
  });

  test('an association can be deleted by id', () async {
    await CreateSku(skus)(sku: sku('smith')).run();
    await CreateSku(skus)(sku: sku('anthology-1')).run();

    await AddSkuAssociation(
      repository: associations,
      skuRepository: skus,
      idGenerator: () => 'a1',
    )(sourceSkuId: 'smith', targetSkuId: 'anthology-1', kind: 'edited').run();

    final rows = (await FetchAssociationsBySku(associations)(
      skuId: 'anthology-1',
    ).run()).getOrElse((_) => fail('expected Right'));
    rows.should.haveCount(1);

    (await DeleteSkuAssociation(associations)(
      id: rows.single.meta.id,
    ).run()).isRight().should.beTrue();
    (await FetchAssociationsBySku(associations)(
      skuId: 'anthology-1',
    ).run()).getOrElse((_) => []).should.beEmpty();
  });
}
