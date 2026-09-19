## 0.1.0

- First release: the catalog model extracted from Circuit Planner.
- One package: the model and the operations together, with no sibling packages.
  Persistence is the consumer's — implement the repository contracts over
  whatever you have.
- Entities: `Meta`, `Trait`, `TraitAttributeDefinition`, `DeviceType` (SKU),
  `SkuComponent` (assembly edge), `Manufacturer`, `Locate` (place tree),
  `Device` (instance), `ImageRecord`.
- Traits form a tree and carry typed attribute definitions (`DataType`,
  `TraitScope`); `ResolveTraitChain` walks the tree and `ResolveSchema` merges a
  trait set's attributes, child overriding parent.
- `ResolveEffectiveAttributes` resolves values rather than definitions, with
  provenance: the instance, its SKU, an assembly above it, or the definition's
  default.
- SKUs assemble from other SKUs, quantity included, with a cycle guard.
- Repository contracts for every aggregate, plus `IUnitOfWork`.
- Use cases for SKUs, assemblies, manufacturers, places, devices, traits,
  attribute definitions, images and meta.
- The in-memory backend used by this repo's own tests lives in `test/support/`
  and is **not** part of the published package.
