## 0.2.0

- `AggregateBillOfMaterials`: folds a SKU's assembly tree into a
  `BillOfMaterials` — one `BomLine` per distinct part, with the total quantity a
  build of *n* units needs, the level it sits at, and whether it is itself an
  assembly. The flip side of resolution: `ResolveEffectiveAttributes` merges the
  layers that describe one thing, this folds the tree that builds one thing.
  Quantities multiply down the tree; a part reached by more than one path is one
  line whose quantity is the sum; a loop in the graph reports
  `WouldCreateCycleFailure` rather than a finite quantity that looks plausible.
- `BillOfMaterials` and `BomLine` value objects, exported with the model.
- An assembly edge pointing at a SKU the catalog does not have is still
  reported, with no model number, instead of dropping the part from the build.

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
