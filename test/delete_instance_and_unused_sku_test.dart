import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/in_memory.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'package:test/test.dart';

/// A degenerate model is one nobody catalogues: a book's edition, which exists only
/// because its copies instantiate it. There is no flag for that — **choosing this
/// operation is the assertion** — and the rule it keeps is the one the plural case
/// forces: the model goes with its **last** article, not with the first one to leave.
///
/// Both halves are the existing use cases, so what is asserted here is the *rule*
/// (when the model goes) plus that neither cascade was lost in the composing.
void main() {
  Meta meta(String id) => Meta(
    id: id,
    notes: '',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  );

  late InMemoryCatalog catalog;

  Sku model(String id, {String maker = 'publisher'}) =>
      Sku(meta: meta(id), manufacturerId: maker, modelNumber: id.toUpperCase());

  Instance copy(String id, {String skuId = 'book'}) =>
      Instance(meta: meta(id), skuId: skuId, locateId: null, name: id);

  setUp(() {
    catalog = InMemoryCatalog();
  });

  test('the model survives its first copy and goes with its last', () async {
    await catalog.skus.create(sku: model('book')).run();
    await catalog.instances.create(instance: copy('copy-1')).run();
    await catalog.instances.create(instance: copy('copy-2')).run();

    (await catalog.deleteInstanceAndUnusedSku(id: 'copy-1').run())
        .isRight()
        .should
        .beTrue();

    // Two copies share one SKU, so "lives and dies with the instance" is true only
    // of the last one: the edition is still copy-2's model.
    (await catalog.skus.fetchById(id: 'book').run()).isRight().should.beTrue();
    (await catalog.instances.fetchAll().run())
        .getOrElse((_) => [])
        .single
        .name
        .should
        .be('copy-2');

    (await catalog.deleteInstanceAndUnusedSku(id: 'copy-2').run())
        .isRight()
        .should
        .beTrue();

    (await catalog.skus.fetchById(id: 'book').run()).isLeft().should.beTrue();
    (await catalog.instances.fetchAll().run())
        .getOrElse((_) => [])
        .should
        .beEmpty();
  });

  test('the article keeps its cascade and the model keeps its own', () async {
    await catalog.skus.create(sku: model('book')).run();
    // An author the book is *composed of*, so the model has an assembly edge of its
    // own to lose — a different store from the article's.
    await catalog.skus.create(sku: model('author')).run();
    await catalog.assemblies
        .create(
          component: SkuComponent(
            meta: meta('wrote'),
            parentSkuId: 'book',
            childSkuId: 'author',
            quantity: 1,
          ),
        )
        .run();
    await catalog.instances.create(instance: copy('copy-1')).run();
    await catalog.images
        .create(
          image: ImageRecord(
            id: 'img-1',
            owner: ImageOwner.instance,
            ownerId: 'copy-1',
            filename: 'copy.jpg',
            storedPath: 'images/copy.jpg',
            createdAt: '2026-01-01T00:00:00.000Z',
          ),
        )
        .run();

    (await catalog.deleteInstanceAndUnusedSku(id: 'copy-1').run())
        .isRight()
        .should
        .beTrue();

    // The article's own cascade, which is DeleteInstance's.
    (await catalog.images.fetchAll().run())
        .getOrElse((_) => [])
        .should
        .beEmpty();
    // The model's own edge, which is DeleteSku's — asserted because it hangs off a
    // different store than the article does.
    (await catalog.assemblies.fetchAll().run())
        .getOrElse((_) => [])
        .should
        .beEmpty();
    // ...and it took only what pointed at the dead model.
    (await catalog.skus.fetchById(id: 'author').run())
        .isRight()
        .should
        .beTrue();
  });

  test('a copy leaving a shared model takes nothing of the model', () async {
    await catalog.skus.create(sku: model('book')).run();
    await catalog.skus.create(sku: model('author')).run();
    await catalog.assemblies
        .create(
          component: SkuComponent(
            meta: meta('wrote'),
            parentSkuId: 'book',
            childSkuId: 'author',
            quantity: 1,
          ),
        )
        .run();
    await catalog.instances.create(instance: copy('copy-1')).run();
    await catalog.instances.create(instance: copy('copy-2')).run();

    (await catalog.deleteInstanceAndUnusedSku(id: 'copy-1').run())
        .isRight()
        .should
        .beTrue();

    (await catalog.skus.fetchById(id: 'book').run()).isRight().should.beTrue();
    (await catalog.assemblies.fetchAll().run())
        .getOrElse((_) => [])
        .should
        .haveCount(1);
  });

  test('articles of other models are untouched', () async {
    await catalog.skus.create(sku: model('book')).run();
    await catalog.skus.create(sku: model('other')).run();
    await catalog.instances.create(instance: copy('copy-1')).run();
    await catalog.instances
        .create(instance: copy('copy-9', skuId: 'other'))
        .run();

    (await catalog.deleteInstanceAndUnusedSku(id: 'copy-1').run())
        .isRight()
        .should
        .beTrue();

    (await catalog.skus.fetchById(id: 'book').run()).isLeft().should.beTrue();
    (await catalog.skus.fetchById(id: 'other').run()).isRight().should.beTrue();
    (await catalog.instances.fetchAll().run())
        .getOrElse((_) => [])
        .single
        .name
        .should
        .be('copy-9');
  });

  test('an article the catalog does not hold fails as a value', () async {
    final result = await catalog.deleteInstanceAndUnusedSku(id: 'ghost').run();

    result.isLeft().should.beTrue();
    result
        .fold((failure) => failure, (_) => fail('expected Left'))
        .should
        .beAssignableTo<NotFoundFailure>();
  });
}
