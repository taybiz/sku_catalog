import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'support/memory_backends.dart';
import 'package:test/test.dart';

/// Trait attribute definition model + persistence round-trips for the
/// [TraitAttributeDefinition.isUnique] flag.
void main() {
  group('Given a trait attribute definition model', () {
    test('Then is_unique persists through toJson/fromJson', () {
      final attribute = TraitAttributeDefinition(
        meta: newMeta(),
        traitId: 't1',
        key: 'serial_no',
        displayLabel: 'Serial number',
        dataType: DataType.string,
        isUnique: true,
      );

      final restored = TraitAttributeDefinition.fromJson(attribute.toJson());

      (attribute.toJson()['is_unique'] as bool).should.be(true);
      restored.isUnique.should.be(true);
    });

    test('Then isUnique defaults to false when absent from the record', () {
      final attribute = TraitAttributeDefinition.fromJson({
        'id': 'a1',
        'notes': '',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
        'trait_id': 't1',
        'key': 'serial_no',
        'display_label': 'Serial number',
        'data_type': 'string',
      });

      attribute.isUnique.should.be(false);
    });

    test('Then is_unique is exposed and compared in equality', () {
      final meta = newMeta();
      final unique = TraitAttributeDefinition(
        meta: meta,
        traitId: 't1',
        key: 'serial_no',
        displayLabel: 'Serial number',
        dataType: DataType.string,
        isUnique: true,
      );
      final notUnique = TraitAttributeDefinition(
        meta: meta,
        traitId: 't1',
        key: 'serial_no',
        displayLabel: 'Serial number',
        dataType: DataType.string,
        isUnique: false,
      );

      unique.should.not.be(notUnique);
    });
  });

  group('Given the memory trait attribute definition repository', () {
    test('Then is_unique is persisted across create and fetch', () async {
      final repository = MemoryTraitAttributeDefinitionRepository();
      final attribute = TraitAttributeDefinition(
        meta: newMeta(),
        traitId: 't1',
        key: 'serial_no',
        displayLabel: 'Serial number',
        dataType: DataType.string,
        isUnique: true,
      );

      await CreateTraitAttributeDefinition(repository)(
        attribute: attribute,
      ).run();

      final fetched = await repository.fetchById(id: attribute.meta.id).run();
      fetched.isRight().should.be(true);
      fetched.getRight().toNullable()!.isUnique.should.be(true);
    });
  });
}
