import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'package:test/test.dart';

/// Pins the required/optional flag through JSON serialization.
///
/// `isRequired` is written as `is_required`, read back symmetric for both
/// values, and — the backward-compatibility contract — treated as false when a
/// record omits the key (or carries a null), so catalogs written before the
/// flag existed still load as fully optional.
void main() {
  TraitAttributeDefinition def({
    required bool isRequired,
    String key = 'amps',
  }) => TraitAttributeDefinition(
    meta: const Meta(
      id: 'a1',
      notes: '',
      createdAt: '2026-01-01T00:00:00.000Z',
      updatedAt: '2026-01-01T00:00:00.000Z',
    ),
    traitId: 't1',
    key: key,
    displayLabel: 'Amps',
    dataType: DataType.number,
    isRequired: isRequired,
  );

  group('trait attribute definition serialization', () {
    test('toJson writes is_required true for a required attribute', () {
      (def(isRequired: true).toJson()['is_required'] as bool).should.beTrue();
    });

    test('toJson writes is_required false for an optional attribute', () {
      (def(isRequired: false).toJson()['is_required'] as bool).should.beFalse();
    });

    test('round-trips a required attribute', () {
      final parsed = TraitAttributeDefinition.fromJson(
        def(isRequired: true).toJson(),
      );
      parsed.isRequired.should.beTrue();
      parsed.key.should.be('amps');
    });

    test('round-trips an optional attribute', () {
      final parsed = TraitAttributeDefinition.fromJson(
        def(isRequired: false).toJson(),
      );
      parsed.isRequired.should.beFalse();
    });

    test('round-trips and matches as Equatable for both values', () {
      final required = def(isRequired: true);
      required.should.be(TraitAttributeDefinition.fromJson(required.toJson()));
      final optional = def(isRequired: false);
      optional.should.be(TraitAttributeDefinition.fromJson(optional.toJson()));
    });

    test(
      'backward compatible: missing is_required defaults to not required',
      () {
        final json = def(isRequired: true).toJson()..remove('is_required');
        TraitAttributeDefinition.fromJson(json).isRequired.should.beFalse();
      },
    );

    test('backward compatible: null is_required defaults to not required', () {
      final json = def(isRequired: true).toJson()..['is_required'] = null;
      TraitAttributeDefinition.fromJson(json).isRequired.should.beFalse();
    });
  });
}
