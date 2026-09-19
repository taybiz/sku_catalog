import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'package:test/test.dart';

/// The naming helpers are pure functions, and they are the part most likely to
/// be reused verbatim — a template with a sequence token is how you get
/// "Rack-1 Unit 1/2/3" without collisions.
void main() {
  Meta meta(String id) => Meta(
    id: id,
    notes: '',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  );

  group('validateNameTemplate', () {
    test('accepts a template carrying the {n} sequence token', () {
      validateNameTemplate('{trait}_{locate}_{sku}_{n}').should.beNull();
      validateNameTemplate('  {base} #{n}  ').should.beNull();
    });

    test('rejects a template without the {n} sequence token', () {
      final error = validateNameTemplate('{trait}_{locate}_{sku}');
      error.should.not.beNull();
      error!.should.contain('{n}');
    });

    test('the default template is valid', () {
      validateNameTemplate(defaultNameTemplate).should.beNull();
    });
  });

  group('formatName', () {
    test('fills fixed tokens and collapses the gaps left by empty ones', () {
      formatName('{trait}_{locate}_{sku}_{n}', {
        'trait': 'Bracket',
        'locate': '',
        'sku': 'AB12',
      }, 3).should.be('Bracket_AB12_3');
    });

    test('keeps the leading token when the first one is empty', () {
      formatName('{base}_{locate}_{n}', {
        'base': '',
        'locate': 'Rack 1',
      }, 2).should.be('Rack 1_2');
    });
  });

  group('nextSequenceStart', () {
    test('continues past the highest existing number', () {
      nextSequenceStart(
        '{base} {n}',
        {'base': 'Unit'},
        ['Unit 1', 'Unit 2', 'Something else'],
      ).should.be(3);
    });

    test('starts at one when nothing matches', () {
      nextSequenceStart('{base} {n}', {'base': 'Unit'}, ['Other']).should.be(1);
    });
  });

  group('uniqueCopyName', () {
    test('suffixes each successive copy', () {
      final all = <Device>[
        Device(
          meta: meta('d1'),
          deviceTypeId: 'sku',
          locateId: 'loc',
          name: 'Sensor',
        ),
      ];
      uniqueCopyName('Sensor', 'loc', all).should.be('Sensor copy');

      all.add(
        Device(
          meta: meta('d2'),
          deviceTypeId: 'sku',
          locateId: 'loc',
          name: 'Sensor copy',
        ),
      );
      uniqueCopyName('Sensor', 'loc', all).should.be('Sensor copy 2');
    });
  });

  group('isSlotBound', () {
    test('is false when the caller names no slot-bound traits', () {
      isSlotBound('sku', const [], const [], const {}).should.beFalse();
    });

    test('matches an inherited trait name case-insensitively', () {
      final traits = <Trait>[
        Trait(meta: meta('root'), name: 'Housed'),
        Trait(meta: meta('leaf'), name: 'Slotted', parentTraitId: 'root'),
      ];
      final skus = <DeviceType>[
        DeviceType(
          meta: meta('sku'),
          manufacturerId: 'm',
          modelNumber: 'X',
          traitIds: const ['leaf'],
        ),
      ];
      isSlotBound('sku', skus, traits, const {'slotted'}).should.beTrue();
      isSlotBound('sku', skus, traits, const {'Housed'}).should.beTrue();
      isSlotBound('sku', skus, traits, const {'Floating'}).should.beFalse();
    });
  });

  group('resolveAttributeAbbreviation', () {
    test('reads the code from the named trait and attribute', () {
      final traits = <Trait>[Trait(meta: meta('coded'), name: 'Coded')];
      resolveAttributeAbbreviation(
        const ['coded'],
        traits,
        const {'code': ' cb '},
        traitName: 'coded',
        attributeKey: 'code',
      ).should.be('CB');
    });

    test('returns empty when the trait is absent or the code is blank', () {
      final traits = <Trait>[Trait(meta: meta('coded'), name: 'Coded')];
      resolveAttributeAbbreviation(
        const [],
        traits,
        const {'code': 'CB'},
        traitName: 'coded',
        attributeKey: 'code',
      ).should.be('');
      resolveAttributeAbbreviation(
        const ['coded'],
        traits,
        const {'code': '  '},
        traitName: 'coded',
        attributeKey: 'code',
      ).should.be('');
    });
  });
}
