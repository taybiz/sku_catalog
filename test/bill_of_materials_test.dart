import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'support/memory_backends.dart';
import 'package:test/test.dart';

/// A bill of materials is a fold, and every way it can be silently wrong is a
/// way to order the wrong number of parts: a level that is not multiplied, a
/// part reached twice and counted once, a sub-assembly standing in for its own
/// parts, a loop that reports a finite quantity, or a level that depends on the
/// order a store handed its rows back.
void main() {
  late MemoryDeviceTypeRepository skus;
  late MemorySkuComponentRepository components;
  late AggregateBillOfMaterials aggregate;

  Meta meta(String id) => Meta(
    id: id,
    notes: '',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  );

  DeviceType sku(String id) => DeviceType(
    meta: meta(id),
    manufacturerId: 'acme',
    modelNumber: id.toUpperCase(),
  );

  /// An assembly edge, written the way a consumer writes one.
  Future<void> edge(String parent, String child, int quantity) async {
    final result =
        await AddSkuComponent(
              repository: components,
              deviceTypeRepository: skus,
            )(
              parentDeviceTypeId: parent,
              childDeviceTypeId: child,
              quantity: quantity,
            )
            .run();

    result.isRight().should.be(true);
  }

  Future<BillOfMaterials> bom(String id, {int units = 1}) async {
    final result = await aggregate(id, units: units).run();
    result.isRight().should.be(true);
    return result.getOrElse((_) => fail('expected Right'));
  }

  Future<DomainFailure> refused(String id, {int units = 1}) async {
    final result = await aggregate(id, units: units).run();
    result.isLeft().should.be(true);
    return result.fold((failure) => failure, (_) => fail('expected Left'));
  }

  BomLine line(BillOfMaterials bill, String id) => bill.lines.firstWhere(
    (line) => line.deviceTypeId == id,
    orElse: () => fail(
      'no "$id" among ${bill.lines.map((l) => l.deviceTypeId).join(', ')}',
    ),
  );

  setUp(() async {
    skus = MemoryDeviceTypeRepository();
    components = MemorySkuComponentRepository();
    aggregate = AggregateBillOfMaterials(
      deviceTypeRepository: skus,
      skuComponentRepository: components,
    );

    for (final id in ['machine', 'rack', 'card', 'shelf', 'bolt']) {
      await CreateDeviceType(skus)(sku(id)).run();
    }
  });

  group('Given a SKU to fold', () {
    group('When it is built from nothing', () {
      test('Then the bill is empty rather than an error', () async {
        final bill = await bom('machine');

        bill.deviceTypeId.should.be('machine');
        bill.modelNumber.should.be('MACHINE');
        bill.units.should.be(1);
        bill.lines.should.beEmpty();
      });
    });

    group('When it holds parts directly', () {
      test('Then each part is a level-1 line with the edge quantity', () async {
        await edge('machine', 'card', 8);

        final card = line(await bom('machine'), 'card');

        card.quantity.should.be(8);
        card.depth.should.be(1);
        card.modelNumber.should.be('CARD');
        card.isAssembly.should.be(false);
      });
    });

    group('When the build is for several units', () {
      test('Then every quantity is multiplied by the unit count', () async {
        await edge('machine', 'card', 8);

        final bill = await bom('machine', units: 3);

        bill.units.should.be(3);
        line(bill, 'card').quantity.should.be(24);
      });
    });

    group('When a part sits inside a sub-assembly', () {
      test('Then its quantity is the product of the edges above it', () async {
        await edge('machine', 'rack', 2);
        await edge('rack', 'card', 8);

        final bill = await bom('machine');

        line(bill, 'rack').quantity.should.be(2);
        line(bill, 'rack').depth.should.be(1);
        line(bill, 'card').quantity.should.be(16);
        line(bill, 'card').depth.should.be(2);
      });

      test('Then the sub-assembly is still a line of its own', () async {
        await edge('machine', 'rack', 2);
        await edge('rack', 'card', 8);

        final bill = await bom('machine');

        line(bill, 'rack').isAssembly.should.be(true);
        line(bill, 'card').isAssembly.should.be(false);
      });
    });

    group('When two paths reach the same part', () {
      test('Then it is one line and the quantity is the sum', () async {
        await edge('machine', 'rack', 2);
        await edge('machine', 'shelf', 1);
        await edge('rack', 'bolt', 3);
        await edge('shelf', 'bolt', 3);

        final bill = await bom('machine');

        bill.lines.where((l) => l.deviceTypeId == 'bolt').length.should.be(1);
        line(bill, 'bolt').quantity.should.be(9);
        line(bill, 'bolt').depth.should.be(2);
      });
    });

    group('When a part is used directly and inside a sub-assembly', () {
      test('Then the line reports the level closest to the root', () async {
        await edge('machine', 'bolt', 4);
        await edge('machine', 'rack', 2);
        await edge('rack', 'bolt', 3);

        final bill = await bom('machine');

        line(bill, 'bolt').quantity.should.be(10);
        line(bill, 'bolt').depth.should.be(1);
      });
    });

    group('When the tree is several levels deep', () {
      test('Then quantities multiply all the way down', () async {
        await edge('machine', 'rack', 2);
        await edge('rack', 'shelf', 3);
        await edge('shelf', 'bolt', 4);

        final bill = await bom('machine', units: 5);

        line(bill, 'rack').quantity.should.be(10);
        line(bill, 'shelf').quantity.should.be(30);
        line(bill, 'bolt').quantity.should.be(120);
        line(bill, 'bolt').depth.should.be(3);
      });
    });

    group('When the parts come back in no particular order', () {
      test('Then the lines are level order, then model number', () async {
        await edge('machine', 'shelf', 1);
        await edge('machine', 'card', 1);
        await edge('shelf', 'rack', 1);
        await edge('shelf', 'bolt', 1);

        final bill = await bom('machine');

        bill.lines.map((l) => l.deviceTypeId).should.be([
          'card',
          'shelf',
          'bolt',
          'rack',
        ]);
      });
    });

    group('When the same use case folds the same SKU twice', () {
      test('Then the second bill equals the first', () async {
        await edge('machine', 'rack', 2);
        await edge('rack', 'card', 8);

        final first = await bom('machine');

        (await bom('machine')).should.be(first);
      });
    });

    group('When an edge points at a SKU the catalog does not have', () {
      test('Then the line still reports what the edge asks for', () async {
        await edge('machine', 'card', 8);
        (await skus.delete('card').run()).isRight().should.be(true);

        final card = line(await bom('machine'), 'card');

        card.quantity.should.be(8);
        card.modelNumber.should.beNull();
      });
    });
  });

  group('Given a build that cannot be folded', () {
    group('When the SKU is not in the catalog', () {
      test('Then the failure comes back on the Left', () async {
        final failure = await refused('ghost');

        failure.should.beAssignableTo<NotFoundFailure>();
      });
    });

    group('When the unit count is below one', () {
      test('Then the failure comes back on the Left', () async {
        (await refused(
          'machine',
          units: 0,
        )).should.beAssignableTo<InvalidInputFailure>();

        (await refused(
          'machine',
          units: -2,
        )).should.beAssignableTo<InvalidInputFailure>();
      });
    });

    group('When the assembly graph loops', () {
      test('Then the fold refuses instead of reporting a number', () async {
        await edge('machine', 'rack', 2);
        // Written straight to the store: the edge guard refuses this, and the
        // fold is the backstop for a loop that got in anyway. A visited-set
        // walk would quietly return a finite, wrong quantity here.
        await components
            .create(
              SkuComponent(
                meta: meta('edge-rack-machine'),
                parentDeviceTypeId: 'rack',
                childDeviceTypeId: 'machine',
                quantity: 1,
              ),
            )
            .run();

        final failure = await refused('machine');

        failure.should.beAssignableTo<WouldCreateCycleFailure>();
      });
    });
  });
}
