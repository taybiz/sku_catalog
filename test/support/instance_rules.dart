/// Builders for the instance write rules, wired the way a composition root would.
///
/// The create, update and copy paths all read the schema of an article, and the
/// unique-value check is built on the same resolution — so a test wires the pair
/// once here instead of assembling the same four repositories at every call site.
///
/// TEST-ONLY, like every other file in this directory.
library;

import 'package:sku_catalog/sku_catalog.dart';

/// The schema in scope for an instance, over the given in-memory stores.
ResolveInstanceSchema instanceSchemaOn({
  required ISkuRepository skuRepository,
  required ITraitRepository traitRepository,
  required ITraitAttributeDefinitionRepository attributeRepository,
}) => ResolveInstanceSchema(
  skuRepository: skuRepository,
  resolveSchema: ResolveSchema(
    traitRepository: traitRepository,
    attributeRepository: attributeRepository,
  ),
);

/// The unique-attribute check, over the given in-memory stores.
AssertUniqueAttributeValues uniqueValuesOn({
  required IInstanceRepository instanceRepository,
  required ISkuRepository skuRepository,
  required ITraitRepository traitRepository,
  required ITraitAttributeDefinitionRepository attributeRepository,
}) => AssertUniqueAttributeValues(
  instanceRepository: instanceRepository,
  resolveInstanceSchema: instanceSchemaOn(
    skuRepository: skuRepository,
    traitRepository: traitRepository,
    attributeRepository: attributeRepository,
  ),
);
