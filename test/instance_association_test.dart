import 'package:fpdart/fpdart.dart';
import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/in_memory.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'package:test/test.dart';

/// An `InstanceAssociation` is a labeled, directed relationship edge between two
/// *articles*: [sourceInstanceId] acts on [targetInstanceId] in some [kind] role.
///
/// It is the token-level sibling of `SkuAssociation`, and the two are **axes, not
/// alternatives**: "an author edited a work" is true of the models and belongs on
/// the SKUs; "this copy is bound with that copy" is true of two particular
/// articles and cannot be said about the models at all. Both are real, and neither
/// store sees the other's rows.
///
/// The rule an edge may never break: **it connects peers.** An edge between two
/// articles names two articles, and an article is never its own peer.
void main() {
  Meta meta(String id) => Meta(
    id: id,
    notes: '',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  );

  Instance article(String id) =>
      Instance(meta: meta(id), skuId: 'title', locateId: null, name: id);

  late InMemoryInstanceRepository instances;
  late InMemoryInstanceAssociationRepository associations;

  setUp(() async {
    instances = InMemoryInstanceRepository();
    associations = InMemoryInstanceAssociationRepository();
  });

  Future<void> store(Instance instance) =>
      instances.create(instance: instance).run();

  Future<Either<DomainFailure, List<InstanceAssociation>>> edgesOn(
    String instanceId,
  ) => FetchAssociationsByInstance(associations)(instanceId: instanceId).run();

  test('an association between two articles is created and fetched back, '
      'direction preserved', () async {
    await store(article('copy-1'));
    await store(article('copy-2'));

    final result =
        await AddInstanceAssociation(
              unitOfWork: noOpUnitOfWork,
              repository: associations,
              instanceRepository: instances,
              idGenerator: () => 'a1',
            )(
              sourceInstanceId: 'copy-1',
              targetInstanceId: 'copy-2',
              kind: 'bound_with',
            )
            .run();
    result.isRight().should.beTrue();

    final rows = (await edgesOn(
      'copy-2',
    )).getOrElse((_) => fail('expected Right'));
    rows.single.sourceInstanceId.should.be('copy-1');
    rows.single.targetInstanceId.should.be('copy-2');
    rows.single.kind.should.be('bound_with');

    // The round-trip through JSON keeps the endpoints distinct, never inverted.
    final json = InstanceAssociation.fromJson(rows.single.toJson());
    json.sourceInstanceId.should.be('copy-1');
    json.targetInstanceId.should.be('copy-2');
  });

  test('two kinds on one pair are two rows, both kept', () async {
    await store(article('copy-1'));
    await store(article('copy-2'));

    await AddInstanceAssociation(
          unitOfWork: noOpUnitOfWork,
          repository: associations,
          instanceRepository: instances,
          idGenerator: () => 'a1',
        )(
          sourceInstanceId: 'copy-1',
          targetInstanceId: 'copy-2',
          kind: 'bound_with',
        )
        .run();
    await AddInstanceAssociation(
          unitOfWork: noOpUnitOfWork,
          repository: associations,
          instanceRepository: instances,
          idGenerator: () => 'a2',
        )(
          sourceInstanceId: 'copy-1',
          targetInstanceId: 'copy-2',
          kind: 'signed_by',
        )
        .run();

    final rows = (await edgesOn(
      'copy-1',
    )).getOrElse((_) => fail('expected Right'));
    rows.map((row) => row.kind).should.be(['bound_with', 'signed_by']);
  });

  test(
    'an association is returned from either end, and filterable by kind',
    () async {
      await store(article('copy-1'));
      await store(article('copy-2'));
      await store(article('copy-3'));

      final add = AddInstanceAssociation(
        unitOfWork: noOpUnitOfWork,
        repository: associations,
        instanceRepository: instances,
        idGenerator: () => 'a1',
      );
      await add(
        sourceInstanceId: 'copy-1',
        targetInstanceId: 'copy-2',
        kind: 'replaced_by',
      ).run();
      await AddInstanceAssociation(
            unitOfWork: noOpUnitOfWork,
            repository: associations,
            instanceRepository: instances,
            idGenerator: () => 'a2',
          )(
            sourceInstanceId: 'copy-3',
            targetInstanceId: 'copy-1',
            kind: 'bound_with',
          )
          .run();

      (await edgesOn('copy-1')).getOrElse((_) => []).should.haveCount(2);
      // A copy with no edges of its own is not implicated by its neighbour's.
      (await edgesOn('copy-2')).getOrElse((_) => []).should.haveCount(1);
      (await edgesOn(
        'copy-3',
      )).getOrElse((_) => []).single.kind.should.be('bound_with');

      final filtered = (await FetchAssociationsByInstance(associations)(
        instanceId: 'copy-1',
        kind: 'replaced_by',
      ).run()).getOrElse((_) => fail('expected Right'));
      filtered.should.haveCount(1);
      (await FetchAssociationsByInstance(associations)(
        instanceId: 'copy-1',
        kind: 'footnoted',
      ).run()).getOrElse((_) => []).should.beEmpty();
    },
  );

  test(
    'an association naming an article that does not exist is refused',
    () async {
      await store(article('copy-1'));

      final result =
          await AddInstanceAssociation(
                unitOfWork: noOpUnitOfWork,
                repository: associations,
                instanceRepository: instances,
              )(
                sourceInstanceId: 'copy-1',
                targetInstanceId: 'ghost',
                kind: 'bound_with',
              )
              .run();

      result.isLeft().should.beTrue();
      // Refused as a value, and nothing was written.
      (await edgesOn('copy-1')).getOrElse((_) => []).should.beEmpty();
    },
  );

  test('an empty kind is refused', () async {
    await store(article('copy-1'));
    await store(article('copy-2'));

    final result =
        await AddInstanceAssociation(
              unitOfWork: noOpUnitOfWork,
              repository: associations,
              instanceRepository: instances,
            )(
              sourceInstanceId: 'copy-1',
              targetInstanceId: 'copy-2',
              kind: '   ',
            )
            .run();

    result
        .fold((failure) => failure, (_) => fail('expected Left'))
        .should
        .beAssignableTo<InvalidInputFailure>();
  });

  test(
    'an edge needs two distinct articles: an article is not its own peer',
    () async {
      await store(article('copy-1'));

      final result =
          await AddInstanceAssociation(
                unitOfWork: noOpUnitOfWork,
                repository: associations,
                instanceRepository: instances,
              )(
                sourceInstanceId: 'copy-1',
                targetInstanceId: 'copy-1',
                kind: 'bound_with',
              )
              .run();

      result
          .fold((failure) => failure, (_) => fail('expected Left'))
          .should
          .beAssignableTo<InvalidInputFailure>();
      (await edgesOn('copy-1')).getOrElse((_) => []).should.beEmpty();
    },
  );

  test(
    'an association can be deleted by id, leaving its neighbours alone',
    () async {
      await store(article('copy-1'));
      await store(article('copy-2'));

      await AddInstanceAssociation(
            unitOfWork: noOpUnitOfWork,
            repository: associations,
            instanceRepository: instances,
            idGenerator: () => 'a1',
          )(
            sourceInstanceId: 'copy-1',
            targetInstanceId: 'copy-2',
            kind: 'bound_with',
          )
          .run();

      final rows = (await edgesOn(
        'copy-1',
      )).getOrElse((_) => fail('expected Right'));
      rows.should.haveCount(1);

      (await DeleteInstanceAssociation(associations)(
        id: rows.single.meta.id,
      ).run()).isRight().should.beTrue();
      (await edgesOn('copy-1')).getOrElse((_) => []).should.beEmpty();
      (await instances.fetchAll().run())
          .getOrElse((_) => [])
          .should
          .haveCount(2);
    },
  );

  test(
    'deleting an article takes its edges and leaves other edges alone',
    () async {
      await store(article('copy-1'));
      await store(article('copy-2'));
      await store(article('copy-3'));

      final add = AddInstanceAssociation(
        unitOfWork: noOpUnitOfWork,
        repository: associations,
        instanceRepository: instances,
        idGenerator: () => 'a1',
      );
      await add(
        sourceInstanceId: 'copy-1',
        targetInstanceId: 'copy-2',
        kind: 'replaced_by',
      ).run();
      await AddInstanceAssociation(
            unitOfWork: noOpUnitOfWork,
            repository: associations,
            instanceRepository: instances,
            idGenerator: () => 'a2',
          )(
            sourceInstanceId: 'copy-3',
            targetInstanceId: 'copy-2',
            kind: 'bound_with',
          )
          .run();

      final result = await DeleteInstance(
        unitOfWork: noOpUnitOfWork,
        instanceRepository: instances,
        imageRepository: InMemoryImageRepository(),
        instanceAssociationRepository: associations,
      )(id: 'copy-1').run();

      result.isRight().should.beTrue();
      // copy-1 is gone, and so is the edge that named it...
      (await instances.fetchById(id: 'copy-1').run()).isLeft().should.beTrue();
      (await associations.fetchAll().run())
          .getOrElse((_) => [])
          .single
          .sourceInstanceId
          .should
          .be('copy-3');
    },
  );
}
