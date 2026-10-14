import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'package:test/test.dart';

/// The name rules the catalog owns: the case-insensitive comparison behind the
/// per-locate rule, and the name a copy gets so it can satisfy it. Naming
/// *templates* — sequence tokens, shortened model numbers, locates as slugs — are
/// the screen's business and are not here.
void main() {
  Meta meta(String id) => Meta(
    id: id,
    notes: '',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  );

  group('namesClash', () {
    test('ignores case and surrounding space', () {
      namesClash(a: 'Sensor 1', b: ' sensor 1 ').should.beTrue();
      namesClash(a: 'Sensor 1', b: 'Sensor 2').should.beFalse();
    });
  });

  group('uniqueCopyName', () {
    test('suffixes each successive copy at the same place', () {
      final all = <Instance>[
        Instance(
          meta: meta('d1'),
          skuId: 'sku',
          locateId: 'loc',
          name: 'Sensor',
        ),
      ];
      uniqueCopyName(
        baseName: 'Sensor',
        locateId: 'loc',
        all: all,
      ).should.be('Sensor copy');

      all.add(
        Instance(
          meta: meta('d2'),
          skuId: 'sku',
          locateId: 'loc',
          name: 'Sensor copy',
        ),
      );
      uniqueCopyName(
        baseName: 'Sensor',
        locateId: 'loc',
        all: all,
      ).should.be('Sensor copy 2');
    });

    test('counts only the names at that place', () {
      final all = <Instance>[
        Instance(
          meta: meta('d1'),
          skuId: 'sku',
          locateId: 'loc',
          name: 'Sensor copy',
        ),
        Instance(
          meta: meta('d2'),
          skuId: 'sku',
          locateId: null,
          name: 'Sensor',
        ),
      ];

      uniqueCopyName(
        baseName: 'Sensor',
        locateId: null,
        all: all,
      ).should.be('Sensor copy');
    });
  });
}
