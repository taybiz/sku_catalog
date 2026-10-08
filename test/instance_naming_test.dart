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
      validateNameTemplate(
        template: '{trait}_{locate}_{sku}_{n}',
      ).should.beNull();
      validateNameTemplate(template: '  {base} #{n}  ').should.beNull();
    });

    test('rejects a template without the {n} sequence token', () {
      final error = validateNameTemplate(template: '{trait}_{locate}_{sku}');
      error.should.not.beNull();
      error!.should.contain('{n}');
    });

    test('the default template is valid', () {
      validateNameTemplate(template: defaultNameTemplate).should.beNull();
    });
  });

  group('formatName', () {
    test('fills fixed tokens and collapses the gaps left by empty ones', () {
      formatName(
        template: '{trait}_{locate}_{sku}_{n}',
        tokens: {'trait': 'Bracket', 'locate': '', 'sku': 'AB12'},
        n: 3,
      ).should.be('Bracket_AB12_3');
    });

    test('keeps the leading token when the first one is empty', () {
      formatName(
        template: '{base}_{locate}_{n}',
        tokens: {'base': '', 'locate': 'Rack 1'},
        n: 2,
      ).should.be('Rack 1_2');
    });
  });

  group('nextSequenceStart', () {
    test('continues past the highest existing number', () {
      nextSequenceStart(
        template: '{base} {n}',
        tokens: {'base': 'Unit'},
        existingNames: ['Unit 1', 'Unit 2', 'Something else'],
      ).should.be(3);
    });

    test('starts at one when nothing matches', () {
      nextSequenceStart(
        template: '{base} {n}',
        tokens: {'base': 'Unit'},
        existingNames: ['Other'],
      ).should.be(1);
    });
  });

  group('uniqueCopyName', () {
    test('suffixes each successive copy', () {
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
  });

  group('isSlotBound', () {
    test('is false when the caller names no slot-bound traits', () {
      isSlotBound(
        typeId: 'sku',
        skus: const [],
        traits: const [],
        traitNames: const {},
      ).should.beFalse();
    });

    test('matches an inherited trait name case-insensitively', () {
      final traits = <Trait>[
        Trait(meta: meta('root'), name: 'Housed'),
        Trait(meta: meta('leaf'), name: 'Slotted', parentTraitId: 'root'),
      ];
      final skus = <Sku>[
        Sku(
          meta: meta('sku'),
          manufacturerId: 'm',
          modelNumber: 'X',
          traitIds: const ['leaf'],
        ),
      ];
      isSlotBound(
        typeId: 'sku',
        skus: skus,
        traits: traits,
        traitNames: const {'slotted'},
      ).should.beTrue();
      isSlotBound(
        typeId: 'sku',
        skus: skus,
        traits: traits,
        traitNames: const {'Housed'},
      ).should.beTrue();
      isSlotBound(
        typeId: 'sku',
        skus: skus,
        traits: traits,
        traitNames: const {'Floating'},
      ).should.beFalse();
    });
  });

  group('resolveAttributeAbbreviation', () {
    test('reads the code from the named trait and attribute', () {
      final traits = <Trait>[Trait(meta: meta('coded'), name: 'Coded')];
      resolveAttributeAbbreviation(
        traitIds: const ['coded'],
        traits: traits,
        attributeValues: const {'code': ' cb '},
        traitName: 'coded',
        attributeKey: 'code',
      ).should.be('CB');
    });

    test('returns empty when the trait is absent or the code is blank', () {
      final traits = <Trait>[Trait(meta: meta('coded'), name: 'Coded')];
      resolveAttributeAbbreviation(
        traitIds: const [],
        traits: traits,
        attributeValues: const {'code': 'CB'},
        traitName: 'coded',
        attributeKey: 'code',
      ).should.be('');
      resolveAttributeAbbreviation(
        traitIds: const ['coded'],
        traits: traits,
        attributeValues: const {'code': '  '},
        traitName: 'coded',
        attributeKey: 'code',
      ).should.be('');
    });
  });
}
