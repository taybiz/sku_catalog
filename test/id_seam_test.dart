import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'support/memory_backends.dart';
import 'package:test/test.dart';

/// Identity is a seam, not a constant: the catalog mints ids through `newMeta`,
/// and a consumer may hand it their own generator. The shape of an id is theirs
/// to choose; what the catalog guarantees is that it stays opaque.
void main() {
  final uuidV4 = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  Meta meta(String id) => Meta(
    id: id,
    notes: '',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  );

  group('Given the id seam', () {
    group('When newMeta is called', () {
      test('Then it defaults to a random UUID v4', () {
        uuidV4.hasMatch(newMeta().id).should.beTrue();
      });

      test('Then an injected generator decides the id', () {
        newMeta(idGenerator: () => 'DEV-0007').id.should.be('DEV-0007');
      });

      test('Then an opaque id survives a JSON round-trip unchanged', () {
        final odd = meta('  Cafe-SNOWMAN / 00:07  ');
        Meta.fromJson(odd.toJson()).id.should.be('  Cafe-SNOWMAN / 00:07  ');
      });
    });

    group('When a use case mints an id internally', () {
      test('Then DuplicateSku uses the injected generator', () async {
        final skus = MemorySkuRepository();
        await CreateSku(skus)(
          sku: Sku(
            meta: meta('qo120'),
            manufacturerId: 'm',
            modelNumber: 'QO120',
          ),
        ).run();

        final copy = await DuplicateSku(
          skus,
          idGenerator: () => 'DEV-0007',
        )(id: 'qo120').run();

        copy
            .getOrElse((_) => fail('expected Right'))
            .meta
            .id
            .should
            .be('DEV-0007');
      });

      test('Then DuplicateSku still defaults to a UUID v4', () async {
        final skus = MemorySkuRepository();
        await CreateSku(skus)(
          sku: Sku(
            meta: meta('qo120'),
            manufacturerId: 'm',
            modelNumber: 'QO120',
          ),
        ).run();

        final copy = await DuplicateSku(skus)(id: 'qo120').run();

        uuidV4
            .hasMatch(copy.getOrElse((_) => fail('expected Right')).meta.id)
            .should
            .beTrue();
      });

      test('Then DuplicateInstance uses the injected generator', () async {
        final instances = MemoryInstanceRepository();
        final skus = MemorySkuRepository();
        final traits = MemoryTraitRepository();
        await CreateSku(skus)(
          sku: Sku(
            meta: meta('free'),
            manufacturerId: 'm',
            modelNumber: 'FREE',
          ),
        ).run();
        await CreateInstance(instances)(
          instance: Instance(
            meta: meta('d1'),
            skuId: 'free',
            locateId: null,
            name: 'Sensor 1',
          ),
        ).run();

        final copy = await DuplicateInstance(
          instanceRepository: instances,
          skuRepository: skus,
          traitRepository: traits,
          idGenerator: () => 'DEV-0008',
        )(id: 'd1').run();

        copy
            .getOrElse((_) => fail('expected Right'))
            .meta
            .id
            .should
            .be('DEV-0008');
      });

      test('Then AddSkuComponent stamps the edge with the injected id', () async {
        final skus = MemorySkuRepository();
        final components = MemorySkuComponentRepository();
        for (final id in ['rack', 'card']) {
          await CreateSku(skus)(
            sku: Sku(
              meta: meta(id),
              manufacturerId: 'm',
              modelNumber: id.toUpperCase(),
            ),
          ).run();
        }

        final edge = await AddSkuComponent(
          repository: components,
          skuRepository: skus,
          idGenerator: () => 'EDGE-1',
        )(parentSkuId: 'rack', childSkuId: 'card', quantity: 8).run();

        edge
            .getOrElse((_) => fail('expected Right'))
            .meta
            .id
            .should
            .be('EDGE-1');
      });

      test(
        'Then UpdateSkuComponent stamps the replacement with the injected id',
        () async {
          final components = MemorySkuComponentRepository();
          await components
              .create(
                component: SkuComponent(
                  meta: meta('e1'),
                  parentSkuId: 'rack',
                  childSkuId: 'card',
                  quantity: 2,
                ),
              )
              .run();

          final updated = await UpdateSkuComponent(
            components,
            idGenerator: () => 'EDGE-2',
          )(skuId: 'e1', quantity: 5).run();

          final row = updated.getOrElse((_) => fail('expected Right'));
          row.meta.id.should.be('EDGE-2');
          row.quantity.should.be(5);
        },
      );
    });
  });
}
