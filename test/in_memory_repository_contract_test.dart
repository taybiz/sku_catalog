import 'package:fpdart/fpdart.dart';
import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/in_memory.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'package:test/test.dart';

/// Every reference store answers to the same contract, so it must answer the
/// same way: `create` refuses an id that is taken, and a call that names a record
/// nobody stored fails as a value rather than quietly succeeding.
///
/// The table runs the same assertions over every store, which is how a rule added
/// to one of them cannot skip the other eight — the shape that let nine copies of
/// the duplicate-id check ship with one of them tested.
///
/// `InMemoryMetaRepository` is absent because its contract is not this one: meta
/// is a single record (`fetch` / `update`), with no id to take and nothing to
/// delete. It is covered where it is used.
void main() {
  Meta meta(String id) => Meta(
    id: id,
    notes: '',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  );

  /// The four calls every one of these contracts carries, closed over one fresh
  /// store so a case cannot leak state into the next.
  Map<String, _Contract Function()> stores() => {
    'Sku': () {
      final store = InMemorySkuRepository();
      return _Contract(
        name: 'Sku',
        create: () => store
            .create(
              sku: Sku(
                meta: meta('s1'),
                manufacturerId: 'm',
                modelNumber: 'S1',
              ),
            )
            .run(),
        update: () => store
            .update(
              sku: Sku(
                meta: meta('gone'),
                manufacturerId: 'm',
                modelNumber: 'S1',
              ),
            )
            .run(),
        delete: () => store.delete(id: 'gone').run(),
        fetchById: () => store.fetchById(id: 'gone').run(),
      );
    },
    'Trait': () {
      final store = InMemoryTraitRepository();
      return _Contract(
        name: 'Trait',
        create: () => store
            .create(
              trait: Trait(meta: meta('t1'), name: 'T1'),
            )
            .run(),
        update: () => store
            .update(
              trait: Trait(meta: meta('gone'), name: 'Gone'),
            )
            .run(),
        delete: () => store.delete(id: 'gone').run(),
        fetchById: () => store.fetchById(id: 'gone').run(),
      );
    },
    'TraitAttributeDefinition': () {
      final store = InMemoryTraitAttributeDefinitionRepository();
      TraitAttributeDefinition definition(String id) =>
          TraitAttributeDefinition(
            meta: meta(id),
            traitId: 't1',
            key: 'k',
            displayLabel: 'K',
            dataType: DataType.string,
          );
      return _Contract(
        name: 'TraitAttributeDefinition',
        create: () => store.create(attribute: definition('a1')).run(),
        update: () => store.update(attribute: definition('gone')).run(),
        delete: () => store.delete(id: 'gone').run(),
        fetchById: () => store.fetchById(id: 'gone').run(),
      );
    },
    'SkuComponent': () {
      final store = InMemorySkuComponentRepository();
      SkuComponent edge(String id) => SkuComponent(
        meta: meta(id),
        parentSkuId: 'assembly',
        childSkuId: 'part',
        quantity: 2,
      );
      return _Contract(
        name: 'SkuComponent',
        create: () => store.create(component: edge('e1')).run(),
        delete: () => store.delete(id: 'gone').run(),
        fetchById: () => store.fetchById(id: 'gone').run(),
      );
    },
    'SkuAssociation': () {
      final store = InMemorySkuAssociationRepository();
      SkuAssociation edge(String id) => SkuAssociation(
        meta: meta(id),
        sourceSkuId: 'a',
        targetSkuId: 'b',
        kind: 'replaces',
      );
      return _Contract(
        name: 'SkuAssociation',
        create: () => store.create(association: edge('r1')).run(),
        delete: () => store.delete(id: 'gone').run(),
        fetchById: () => store.fetchById(id: 'gone').run(),
      );
    },
    'Instance': () {
      final store = InMemoryInstanceRepository();
      Instance article(String id) =>
          Instance(meta: meta(id), skuId: 's1', locateId: null, name: id);
      return _Contract(
        name: 'Instance',
        create: () => store.create(instance: article('i1')).run(),
        update: () => store.update(instance: article('gone')).run(),
        delete: () => store.delete(id: 'gone').run(),
        fetchById: () => store.fetchById(id: 'gone').run(),
      );
    },
    'InstanceAssociation': () {
      final store = InMemoryInstanceAssociationRepository();
      InstanceAssociation edge(String id) => InstanceAssociation(
        meta: meta(id),
        sourceInstanceId: 'copy-1',
        targetInstanceId: 'copy-2',
        kind: 'bound_with',
      );
      return _Contract(
        name: 'InstanceAssociation',
        create: () => store.create(association: edge('r1')).run(),
        delete: () => store.delete(id: 'gone').run(),
        fetchById: () => store.fetchById(id: 'gone').run(),
      );
    },
    'Locate': () {
      final store = InMemoryLocateRepository();
      Locate place(String id) => Locate(meta: meta(id), name: id);
      return _Contract(
        name: 'Locate',
        create: () => store.create(locate: place('l1')).run(),
        update: () => store.update(locate: place('gone')).run(),
        delete: () => store.delete(id: 'gone').run(),
        fetchById: () => store.fetchById(id: 'gone').run(),
      );
    },
    'Manufacturer': () {
      final store = InMemoryManufacturerRepository();
      Manufacturer maker(String id) => Manufacturer(meta: meta(id), name: id);
      return _Contract(
        name: 'Manufacturer',
        create: () => store.create(manufacturer: maker('m1')).run(),
        update: () => store.update(manufacturer: maker('gone')).run(),
        delete: () => store.delete(id: 'gone').run(),
        fetchById: () => store.fetchById(id: 'gone').run(),
      );
    },
    'ImageRecord': () {
      final store = InMemoryImageRepository();
      ImageRecord image(String id) => ImageRecord(
        id: id,
        owner: ImageOwner.instance,
        ownerId: 'i1',
        filename: 'photo.jpg',
        storedPath: 'images/photo.jpg',
        createdAt: '2026-01-01T00:00:00.000Z',
      );
      return _Contract(
        name: 'ImageRecord',
        create: () => store.create(image: image('img1')).run(),
        delete: () => store.delete(id: 'gone').run(),
        fetchById: () => store.fetchById(id: 'gone').run(),
      );
    },
  };

  DomainFailure refusalOf(Either<DomainFailure, Object?> result) =>
      result.fold<DomainFailure>(
        (failure) => failure,
        (_) => fail('expected the store to refuse'),
      );

  for (final entry in stores().entries) {
    group('Given the reference ${entry.key} store', () {
      test(
        'Then create takes an id once and refuses it the second time',
        () async {
          final store = entry.value();

          (await store.create()).isRight().should.beTrue();
          refusalOf(
            await store.create(),
          ).should.beAssignableTo<AlreadyExistsFailure>();
        },
      );

      test('Then deleting an id nobody stored fails as a value', () async {
        final store = entry.value();

        refusalOf(
          await store.delete(),
        ).should.beAssignableTo<NotFoundFailure>();
      });

      test('Then fetching an id nobody stored fails as a value', () async {
        final store = entry.value();

        refusalOf(
          await store.fetchById(),
        ).should.beAssignableTo<NotFoundFailure>();
      });

      if (entry.value().update != null) {
        test('Then updating a record nobody stored fails as a value', () async {
          final store = entry.value();

          refusalOf(
            await store.update!(),
          ).should.beAssignableTo<NotFoundFailure>();
        });
      }
    });
  }
}

/// One store's four contract calls, as closures so each case gets a fresh store.
class _Contract {
  _Contract({
    required this.name,
    required this.create,
    required this.delete,
    required this.fetchById,
    this.update,
  });

  /// The store's name, for the test description.
  final String name;

  /// Creates the store's one record; a second call must be refused.
  final Future<Either<DomainFailure, Object?>> Function() create;

  /// Deletes an id the store does not hold.
  final Future<Either<DomainFailure, Object?>> Function() delete;

  /// Fetches an id the store does not hold.
  final Future<Either<DomainFailure, Object?>> Function() fetchById;

  /// Updates a record the store does not hold, for the contracts that have one.
  final Future<Either<DomainFailure, Object?>> Function()? update;
}
