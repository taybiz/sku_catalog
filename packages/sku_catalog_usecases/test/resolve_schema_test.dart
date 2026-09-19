import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog_domain/sku_catalog_domain.dart';
import 'package:sku_catalog_memory/sku_catalog_memory.dart';
import 'package:sku_catalog_usecases/sku_catalog_usecases.dart';
import 'package:test/test.dart';

/// Pins how a trait chain's attributes merge.
///
/// Two decisions are load-bearing here and both have been wrong before: a child
/// trait's definition of a key must win over the parent's, and a key must keep
/// the position where it was first seen so the general attributes read before
/// the specific ones. A lazy-TaskEither bug once made the schema come back empty
/// for every entity; these tests are the guard for that whole class.
void main() {
  late MemoryTraitRepository traits;
  late MemoryTraitAttributeDefinitionRepository attrs;
  late ResolveSchema resolve;

  Meta meta(String id) => Meta(
    id: id,
    notes: '',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  );

  TraitAttributeDefinition attr(
    String traitId,
    String key, {
    String? unit,
    bool required = false,
    DataType type = DataType.number,
  }) => TraitAttributeDefinition(
    meta: meta('$traitId-$key'),
    traitId: traitId,
    key: key,
    displayLabel: key,
    dataType: type,
    unit: unit,
    isRequired: required,
  );

  setUp(() async {
    traits = MemoryTraitRepository();
    attrs = MemoryTraitAttributeDefinitionRepository();

    final part = Trait(
      meta: meta('part'),
      name: 'Part',
      scope: const [TraitScope.sku],
    );
    final bolt = Trait(
      meta: meta('bolt'),
      name: 'Bolt',
      parentTraitId: 'part',
      scope: const [TraitScope.sku],
    );
    final coated = Trait(
      meta: meta('coated'),
      name: 'Coated',
      scope: const [TraitScope.sku],
    );

    await CreateTrait(traits)(part).run();
    await CreateTrait(traits)(bolt).run();
    await CreateTrait(traits)(coated).run();

    await CreateTraitAttributeDefinition(attrs)(
      attr('part', 'size', unit: 'mm', required: true),
    ).run();
    await CreateTraitAttributeDefinition(attrs)(
      attr('part', 'mass', unit: 'g'),
    ).run();
    // The child redeclares `size` with its own unit — the child must win.
    await CreateTraitAttributeDefinition(attrs)(
      attr('bolt', 'size', unit: 'in'),
    ).run();
    await CreateTraitAttributeDefinition(attrs)(attr('bolt', 'thread')).run();
    await CreateTraitAttributeDefinition(attrs)(
      attr('coated', 'coating', type: DataType.string),
    ).run();

    resolve = ResolveSchema(
      traitRepository: traits,
      attributeRepository: attrs,
    );
  });

  Future<List<ResolvedAttribute>> schemaOf(List<String> ids) async =>
      (await resolve(ids).run()).fold((f) => fail('$f'), (v) => v);

  test('a child trait inherits its parent attributes', () async {
    final keys = (await schemaOf(['bolt'])).map((a) => a.def.key).toList();
    keys.should.containAll(['size', 'mass', 'thread']);
  });

  test("a child trait's definition of a key overrides the parent's", () async {
    final schema = await schemaOf(['bolt']);
    final size = schema.firstWhere((a) => a.def.key == 'size');

    size.def.unit!.should.be('in');
    size.def.meta.id.should.be('bolt-size');
    schema.length.should.be(3);
  });

  test('a key keeps the position where it was first seen', () async {
    final keys = (await schemaOf(['bolt'])).map((a) => a.def.key).toList();
    // `size` and `mass` come from the parent, so they read before `thread`.
    keys.should.be(['size', 'mass', 'thread']);
  });

  test('requirement and unit survive the merge', () async {
    final schema = await schemaOf(['bolt']);
    schema.firstWhere((a) => a.def.key == 'mass').unit!.should.be('g');
    schema
        .firstWhere((a) => a.def.key == 'thread')
        .def
        .isRequired
        .should
        .beFalse();
  });

  test('separate traits merge without duplicating shared keys', () async {
    final keys = (await schemaOf([
      'bolt',
      'coated',
    ])).map((a) => a.def.key).toList();
    keys.should.containAll(['size', 'mass', 'thread', 'coating']);
    keys.toSet().length.should.be(keys.length);
    keys.where((k) => k == 'size').length.should.be(1);
  });

  test('an empty trait list resolves to an empty schema', () async {
    (await schemaOf(const [])).should.beEmpty();
  });

  test('definitions come back, not values', () async {
    for (final a in await schemaOf(['coated'])) {
      (a.value as Object?).should.beNull();
      a.source.should.be('trait');
    }
  });
}
