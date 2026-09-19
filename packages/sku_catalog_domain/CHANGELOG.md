## 0.1.0

- First release.
- Entities: `Meta`, `Trait`, `TraitAttributeDefinition`, `DeviceType` (SKU),
  `SkuComponent` (assembly edge), `Manufacturer`, `Locate` (place tree),
  `Device` (instance), `ImageRecord`, and the `ResolvedAttribute` value object.
- `TraitAttributeDefinition` carries an optional `defaultValue`, so an attribute
  nobody sets can still have a documented value.
- Repository contracts for every aggregate, plus `IUnitOfWork` and
  `NoOpUnitOfWork`.
