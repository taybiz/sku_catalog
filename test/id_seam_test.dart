import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/sku_catalog.dart';
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
  });
}
