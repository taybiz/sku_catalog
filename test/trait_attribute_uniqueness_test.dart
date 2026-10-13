import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'support/memory_backends.dart';
import 'package:test/test.dart';

/// A trait attribute marked `isUnique` must not collide with instance data:
/// when a definition is created or updated as unique, no two instances that
/// carry the trait may already hold the same value for that attribute. The
/// rule is scoped to the trait (each instance is identified by its SKU), and
/// only non-blank explicit values compete.
void main() {
  late MemoryInstanceRepository instances;
  late MemoryTraitAttributeDefinitionRepository attrs;

  Meta meta(String id) => Meta(
    id: id,
    notes: '',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  );

  Instance instance(
    String id, {
    String skuId = 'sku-a',
    List<String> traitIds = const ['sensor'],
    Map<String, dynamic> values = const {},
  }) => Instance(
    meta: meta(id),
    skuId: skuId,
    locateId: null,
    name: id,
    traitIds: traitIds,
    attributeValues: values,
  );

  TraitAttributeDefinition definition(
    String key, {
    bool unique = true,
    String traitId = 'sensor',
    String id = 'def',
  }) => TraitAttributeDefinition(
    meta: meta(id),
    traitId: traitId,
    key: key,
    displayLabel: key,
    dataType: DataType.string,
    isUnique: unique,
  );

  CreateTraitAttributeDefinition create() =>
      CreateTraitAttributeDefinition(attrs, instanceRepository: instances);

  UpdateTraitAttributeDefinition update() =>
      UpdateTraitAttributeDefinition(attrs, instanceRepository: instances);

  setUp(() {
    instances = MemoryInstanceRepository();
    attrs = MemoryTraitAttributeDefinitionRepository();
  });

  test(
    'a unique attribute persists when no instance holds its value',
    () async {
      final result = await create()(attribute: definition('serial')).run();

      result.isRight().should.beTrue();
      (await attrs.fetchAll().run()).getOrElse((_) => []).length.should.be(1);
    },
  );

  test(
    'a non-unique attribute persists even when instances share a value',
    () async {
      await CreateInstance(instances)(
        instance: instance('i1', values: const {'serial': 'A'}),
      ).run();
      await CreateInstance(instances)(
        instance: instance('i2', values: const {'serial': 'A'}),
      ).run();

      final result = await create()(
        attribute: definition('serial', unique: false),
      ).run();

      result.isRight().should.beTrue();
    },
  );

  test(
    'a unique attribute is refused when two instances with the trait share a value',
    () async {
      await CreateInstance(instances)(
        instance: instance('i1', skuId: 'sku-a', values: const {'serial': 'A'}),
      ).run();
      await CreateInstance(instances)(
        instance: instance('i2', skuId: 'sku-b', values: const {'serial': 'A'}),
      ).run();

      final result = await create()(attribute: definition('serial')).run();

      result.isLeft().should.beTrue();
      final failure = result.fold((f) => f, (_) => fail('expected Left'));
      failure.should.beAssignableTo<AlreadyExistsFailure>();
      failure.message.should.contain('serial');
      failure.message.should.contain('sku-a');
      failure.message.should.contain('sku-b');
      // Nothing was persisted.
      (await attrs.fetchAll().run()).getOrElse((_) => []).should.beEmpty();
    },
  );

  test(
    'a unique attribute persists when instances hold distinct values',
    () async {
      await CreateInstance(instances)(
        instance: instance('i1', values: const {'serial': 'A'}),
      ).run();
      await CreateInstance(instances)(
        instance: instance('i2', values: const {'serial': 'B'}),
      ).run();

      final result = await create()(attribute: definition('serial')).run();

      result.isRight().should.beTrue();
    },
  );

  test('a single holder of the value is not a duplicate', () async {
    await CreateInstance(instances)(
      instance: instance('i1', values: const {'serial': 'A'}),
    ).run();

    final result = await create()(attribute: definition('serial')).run();

    result.isRight().should.beTrue();
  });

  test('instances that do not carry the trait are ignored', () async {
    await CreateInstance(instances)(
      instance: instance(
        'i1',
        traitIds: const ['other'],
        values: const {'serial': 'A'},
      ),
    ).run();
    await CreateInstance(instances)(
      instance: instance(
        'i2',
        traitIds: const ['other'],
        values: const {'serial': 'A'},
      ),
    ).run();

    final result = await create()(attribute: definition('serial')).run();

    result.isRight().should.beTrue();
  });

  test('an unset or blank value does not compete for uniqueness', () async {
    await CreateInstance(instances)(
      instance: instance('i1', values: const {}),
    ).run();
    await CreateInstance(instances)(
      instance: instance('i2', values: const {'serial': '   '}),
    ).run();
    await CreateInstance(instances)(
      instance: instance('i3', values: const {'serial': 'A'}),
    ).run();

    final result = await create()(attribute: definition('serial')).run();

    result.isRight().should.beTrue();
  });

  test(
    'updating a definition to unique is refused when duplicates already exist',
    () async {
      await create()(attribute: definition('serial', unique: false)).run();

      await CreateInstance(instances)(
        instance: instance('i1', values: const {'serial': 'A'}),
      ).run();
      await CreateInstance(instances)(
        instance: instance('i2', values: const {'serial': 'A'}),
      ).run();

      final result = await update()(definition: definition('serial')).run();

      result.isLeft().should.beTrue();
      result
          .fold((f) => f, (_) => fail('expected Left'))
          .should
          .beAssignableTo<AlreadyExistsFailure>();
    },
  );

  test(
    'updating a definition to unique persists when values are distinct',
    () async {
      await create()(attribute: definition('serial', unique: false)).run();
      await CreateInstance(instances)(
        instance: instance('i1', values: const {'serial': 'A'}),
      ).run();
      await CreateInstance(instances)(
        instance: instance('i2', values: const {'serial': 'B'}),
      ).run();

      final result = await update()(definition: definition('serial')).run();

      result.isRight().should.beTrue();
      (await attrs.fetchById(id: 'def').run())
          .getOrElse((_) => fail('expected Right'))
          .isUnique
          .should
          .beTrue();
    },
  );
}
