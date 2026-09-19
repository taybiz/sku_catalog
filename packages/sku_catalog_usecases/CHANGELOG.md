## 0.1.0

- First release.
- CRUD for every aggregate, the trait-chain and attribute-schema resolvers, the
  assembly cycle guard and the place-tree guard.
- `ResolveEffectiveAttributes` resolves the value of every attribute in scope for
  a device or a SKU, nearest claim wins, reporting where each value came from:
  the instance, the SKU, an assembly above it, or the definition's default.
- Repository contracts take an optional `IUnitOfWork`, and `DeleteDeviceType` and
  `DeleteDevice` run their two writes inside it.
