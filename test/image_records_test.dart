import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'support/memory_backends.dart';
import 'package:test/test.dart';

/// Images hang off three kinds of owner, and the owner kind is part of the
/// query — asking for a SKU's images must not return the instance's.
void main() {
  late MemoryImageRepository repository;

  ImageRecord record(
    String id, {
    ImageOwner owner = ImageOwner.instance,
    String ownerId = 'd1',
  }) => ImageRecord(
    id: id,
    owner: owner,
    ownerId: ownerId,
    filename: '$id.jpg',
    storedPath: 'data:image/jpeg;base64,AAAA',
    createdAt: '2024-01-01T00:00:00.000Z',
  );

  setUp(() {
    repository = MemoryImageRepository();
  });

  test('an image record round-trips through create', () async {
    final result = await CreateImageRecord(repository)(
      image: record('img1'),
    ).run();

    result.isRight().should.be(true);
    result.getOrElse((_) => fail('expected Right')).id.should.be('img1');
  });

  test('images are returned per owner kind and id', () async {
    await CreateImageRecord(repository)(image: record('d1a')).run();
    await CreateImageRecord(repository)(
      image: record('s1', owner: ImageOwner.sku, ownerId: 'sku1'),
    ).run();
    await CreateImageRecord(repository)(
      image: record('l1', owner: ImageOwner.locate, ownerId: 'loc1'),
    ).run();

    final skuImages = await FetchImageRecords(repository)(
      owner: ImageOwner.sku,
      ownerId: 'sku1',
    ).run();
    skuImages.getOrElse((_) => []).map((i) => i.id).should.be(['s1']);

    final instanceImages = await FetchImageRecords(repository)(
      owner: ImageOwner.instance,
      ownerId: 'd1',
    ).run();
    instanceImages.getOrElse((_) => []).map((i) => i.id).should.be(['d1a']);
  });

  test('deleting an image record removes it', () async {
    await CreateImageRecord(repository)(image: record('img1')).run();

    (await DeleteImageRecord(repository)(
      id: 'img1',
    ).run()).isRight().should.be(true);
    (await repository.fetchAll().run())
        .getOrElse((_) => [])
        .should
        .haveCount(0);
  });

  test('deleting an image that is not there fails as a value', () async {
    final result = await DeleteImageRecord(repository)(id: 'nope').run();

    result.isLeft().should.be(true);
    result
        .fold((f) => f, (_) => fail('expected Left'))
        .should
        .beAssignableTo<DomainFailure>();
  });
}
