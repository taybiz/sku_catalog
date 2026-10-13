import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'package:test/test.dart';

/// Pins the required-attribute validation rule.
///
/// A required attribute is one the schema declares `isRequired` and that still
/// resolves to no value. An optional attribute is never reported, and a
/// required attribute that a default (or an instance/SKU claim) satisfies is
/// likewise satisfied — only attributes still null after resolution are
/// missing.
void main() {
  ResolvedAttribute attr({
    required String key,
    required bool isRequired,
    Object? value,
    Object? defaultValue,
  }) {
    final def = TraitAttributeDefinition(
      meta: Meta(
        id: 'def-$key',
        notes: '',
        createdAt: '2026-01-01T00:00:00.000Z',
        updatedAt: '2026-01-01T00:00:00.000Z',
      ),
      traitId: 't1',
      key: key,
      displayLabel: key,
      dataType: DataType.string,
      isRequired: isRequired,
      defaultValue: defaultValue,
    );
    // Mirror ResolveEffectiveAttributes: a default fills the value, so a
    // required attribute with a default is never missing.
    return ResolvedAttribute(
      attributeId: def.meta.id,
      name: def.displayLabel,
      value: value ?? defaultValue,
      unit: def.unit,
      source: value != null ? 'instance' : 'default',
      def: def,
    );
  }

  group('missingRequiredAttributeKeys', () {
    test('reports a required attribute that resolves to no value', () {
      missingRequiredAttributeKeys(
        attributes: [attr(key: 'amps', isRequired: true)],
      ).should.be(['amps']);
    });

    test('does not report a required attribute that has a value', () {
      missingRequiredAttributeKeys(
        attributes: [attr(key: 'amps', isRequired: true, value: 120)],
      ).should.beEmpty();
    });

    test('does not report a required attribute satisfied by its default', () {
      missingRequiredAttributeKeys(
        attributes: [attr(key: 'amps', isRequired: true, defaultValue: '120A')],
      ).should.beEmpty();
    });

    test('does not report an optional attribute with no value', () {
      missingRequiredAttributeKeys(
        attributes: [attr(key: 'note', isRequired: false)],
      ).should.beEmpty();
    });

    test('reports only the missing required keys, in schema order', () {
      missingRequiredAttributeKeys(
        attributes: [
          attr(key: 'amps', isRequired: true),
          attr(key: 'volts', isRequired: true, value: 24),
          attr(key: 'note', isRequired: false),
          attr(key: 'phase', isRequired: true),
        ],
      ).should.be(['amps', 'phase']);
    });

    test('empty attributes report nothing missing', () {
      missingRequiredAttributeKeys(attributes: const []).should.beEmpty();
    });
  });

  group('assertRequiredAttributes', () {
    test('returns Right(unit) when every required attribute is satisfied', () {
      final result = assertRequiredAttributes(
        attributes: [
          attr(key: 'amps', isRequired: true, value: 120),
          attr(key: 'note', isRequired: false),
        ],
      );
      result.isRight().should.beTrue();
    });

    test('returns a Left(InvalidInputFailure) naming missing keys', () {
      final result = assertRequiredAttributes(
        attributes: [
          attr(key: 'amps', isRequired: true),
          attr(key: 'phase', isRequired: true),
        ],
      );
      result.fold((failure) {
        failure.should.beOfType<InvalidInputFailure>();
        failure.message.should.contain('amps');
        failure.message.should.contain('phase');
      }, (_) => fail('expected a missing-required failure'));
    });
  });
}
