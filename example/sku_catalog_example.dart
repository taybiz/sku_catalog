// A runnable tour of the package: classify, value, assemble, place, instantiate,
// fold.
//
// The storage is the package's own reference backend — `InMemoryCatalog` — so this
// file is about the model and nothing else. A real consumer writes their own store
// classes against the same contracts; `package:sku_catalog/in_memory.dart` is the
// shape to copy, and swapping it in is a one-line change here.
//
//   dart run example/sku_catalog_example.dart
import 'package:sku_catalog/in_memory.dart';
import 'package:sku_catalog/sku_catalog.dart';

Future<void> main() async {
  // One object holds every store, a transaction over all of them, and the
  // operations that need more than one store wired together.
  final catalog = InMemoryCatalog();
  final traits = catalog.traits;
  final attributes = catalog.attributes;
  final skus = catalog.skus;
  final assemblies = catalog.assemblies;
  final locates = catalog.locates;
  final instances = catalog.instances;

  // 1. Classify. Traits form a tree: Breaker is a Switch with more to say.
  final switchTrait = Trait(
    meta: _meta('switch'),
    name: 'Switch',
    scope: const [TraitScope.sku],
  );
  final breakerTrait = Trait(
    meta: _meta('breaker'),
    name: 'Breaker',
    parentTraitId: switchTrait.meta.id,
    scope: const [TraitScope.sku],
  );
  await CreateTrait(traits)(trait: switchTrait).run();
  await CreateTrait(traits)(trait: breakerTrait).run();

  // 2. Value: each trait contributes typed fields, and a child overrides them.
  //
  //    The serializable trait is the package's one canonical one: a serial
  //    number is not a field on the instance, it is an attribute value — the
  //    model carries the trait, the article carries the number, and `isUnique`
  //    is what makes the catalog refuse a second article holding the same one.
  final serializable = SerializableTrait.define(
    traitMeta: _meta('serializable'),
    attributeMeta: _meta('serializable-serial_number'),
  );
  await CreateTrait(traits)(trait: serializable.trait).run();
  await CreateTraitAttributeDefinition(attributes)(
    attribute: serializable.serialNumber,
  ).run();

  await CreateTraitAttributeDefinition(attributes)(
    attribute: TraitAttributeDefinition(
      meta: _meta('switch-rated_amps'),
      traitId: switchTrait.meta.id,
      key: 'rated_amps',
      displayLabel: 'Rated Amperage',
      dataType: DataType.number,
      unit: 'A',
      isRequired: true,
    ),
  ).run();
  await CreateTraitAttributeDefinition(attributes)(
    attribute: TraitAttributeDefinition(
      meta: _meta('breaker-trip_amperage'),
      traitId: breakerTrait.meta.id,
      key: 'trip_amperage',
      displayLabel: 'Trip Amperage',
      dataType: DataType.number,
      unit: 'A',
    ),
  ).run();

  // 3. Catalogue the SKUs. A panel and a breaker are both products.
  final breakerModel = Sku(
    meta: _meta('qo120'),
    manufacturerId: 'square-d',
    modelNumber: 'QO120',
    traitIds: [breakerTrait.meta.id],
    attributeValues: const {'rated_amps': 20, 'trip_amperage': 20},
  );
  final panelModel = Sku(
    meta: _meta('qo-16'),
    manufacturerId: 'square-d',
    modelNumber: 'QO-16',
    traitIds: [serializable.trait.meta.id],
  );
  await CreateSku(skus)(sku: breakerModel).run();
  await CreateSku(skus)(sku: panelModel).run();
  final subPanelModel = Sku(
    meta: _meta('qo-4'),
    manufacturerId: 'square-d',
    modelNumber: 'QO-4',
  );
  await CreateSku(skus)(sku: subPanelModel).run();

  // 4. Assemble: the panel holds eight breakers and four sub-panels, and each
  //    sub-panel holds four breakers — so a build consumes the breaker two
  //    ways. On purpose the edge is then tried the other way round, to show the
  //    cycle guard refuse it.
  final addComponent = catalog.addSkuComponent;
  await addComponent(
    parentSkuId: panelModel.meta.id,
    childSkuId: breakerModel.meta.id,
    quantity: 8,
  ).run();
  await addComponent(
    parentSkuId: panelModel.meta.id,
    childSkuId: subPanelModel.meta.id,
    quantity: 4,
  ).run();
  await addComponent(
    parentSkuId: subPanelModel.meta.id,
    childSkuId: breakerModel.meta.id,
    quantity: 4,
  ).run();
  final loop = await addComponent(
    parentSkuId: breakerModel.meta.id,
    childSkuId: panelModel.meta.id,
    quantity: 1,
  ).run();

  // 5. Place: a Locate is a place, and places nest. The panel goes in a room.
  final garage = Locate(meta: _meta('garage'), name: 'Garage');
  final panelPlace = Locate(
    meta: _meta('garage.panel'),
    name: 'Panel Position',
    parentLocateId: garage.meta.id,
  );
  await CreateLocate(locates)(locate: garage).run();
  await CreateLocate(locates)(locate: panelPlace).run();

  // 6. Instantiate: an instance is one article of a SKU, at one place. Its
  //    serial number is an attribute value, and because the trait marks it
  //    unique the write path refuses a second article claiming the same one.
  final createInstance = catalog.createInstance;
  final panelInstance = Instance(
    meta: _meta('pnl-1'),
    skuId: panelModel.meta.id,
    locateId: panelPlace.meta.id,
    name: 'Garage Panel 1',
    attributeValues: const {SerializableTrait.serialNumberKey: 'QO-0001'},
  );
  await createInstance(instance: panelInstance).run();
  final duplicateSerial = await createInstance(
    instance: panelInstance.copyWith(
      meta: _meta('pnl-2'),
      name: 'Garage Panel 2',
    ),
  ).run();

  // 7. Ask the model what it knows. Traits inherit, so the breaker's schema
  //    carries Switch's attributes too.
  final schema = await catalog.schema(traitIds: breakerModel.traitIds).run();

  final schemaLine = schema.fold(
    (failure) => 'failed: ${failure.message}',
    (resolved) => resolved
        .map((a) => '${a.name}${a.def.unit == null ? '' : ' (${a.def.unit})'}')
        .join(', '),
  );
  final partsCount = await FetchComponentsBySku(assemblies)(
    skuId: panelModel.meta.id,
  ).run();
  final breakersDirect = partsCount.fold(
    (failure) => '?',
    (rows) =>
        '${rows.firstWhere((c) => c.childSkuId == breakerModel.meta.id).quantity}',
  );
  final subPanelsDirect = partsCount.fold(
    (failure) => '?',
    (rows) =>
        '${rows.firstWhere((c) => c.childSkuId == subPanelModel.meta.id).quantity}',
  );
  final instancesAtPlace = await FetchInstancesByLocate(instances)(
    locateId: panelPlace.meta.id,
  ).run();

  print(
    'SKU        ${panelModel.modelNumber} — holds $breakersDirect × '
    '${breakerModel.modelNumber} directly, plus $subPanelsDirect × '
    '${subPanelModel.modelNumber}',
  );
  print('Schema     ${breakerModel.modelNumber} → $schemaLine');
  print(
    'Place      ${garage.name} / ${panelPlace.name} → '
    '${instancesAtPlace.fold((f) => '?', (rows) => rows.single.name)}',
  );
  print(
    'Assembly   panel in breaker? '
    '${loop.fold((failure) => 'refused (${failure.message})', (_) => 'allowed — BUG')}',
  );
  print(
    'Serial     QO-0001 on a second panel? '
    '${duplicateSerial.fold((failure) => 'refused (${failure.message})', (_) => 'allowed — BUG')}',
  );

  // 8. Fold: what does a build of two panels consume? This is not resolution —
  //    that merges the layers describing one thing. This folds the tree that
  //    builds one thing: quantities multiply down the levels, and the breaker,
  //    reached directly and through a sub-panel, is one line with the total.
  final bom = await catalog
      .billOfMaterials(skuId: panelModel.meta.id, units: 2)
      .run();

  final bomLine = bom.fold(
    (failure) => 'failed: ${failure.message}',
    (bill) => bill.lines
        .map(
          (line) =>
              '${line.quantity} × ${line.modelNumber} '
              '(level ${line.depth}${line.isAssembly ? ', itself an assembly' : ''})',
        )
        .join(', '),
  );
  print('Parts      2 × ${panelModel.modelNumber} → $bomLine');

  // 9. An instance carries its own classification and values, independent of the
  //    model it came from — which is what lets one SKU be wired two ways.
  final spare = panelInstance.copyWith(
    name: 'Spare Panel',
    locateId: null,
    traitIds: const ['spare'],
    attributeValues: const {'note': 'not yet fitted'},
  );
  print('Instance   ${spare.name} is placed? ${spare.isPlaced}');
}

Meta _meta(String id) => Meta(
  id: id,
  notes: '',
  createdAt: '2026-01-01T00:00:00.000Z',
  updatedAt: '2026-01-01T00:00:00.000Z',
);
