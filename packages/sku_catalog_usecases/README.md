# sku_catalog_usecases

The **operations** on the [`sku_catalog_domain`](https://pub.dev/packages/sku_catalog_domain)
model: CRUD for every aggregate, trait-chain and attribute-schema resolution,
assembly edges with a cycle guard, and the device and place rules.

Every use case is typed against the repository contracts — this package ships no
persistence. Pair it with an implementation of those contracts
([`sku_catalog_memory`](https://pub.dev/packages/sku_catalog_memory), or your
own over a file, SQLite, a service).

```yaml
dependencies:
  sku_catalog_usecases: ^0.1.0
```

## What you get back

This package presents **FP-style tuples**, not exceptions: repository methods and
use case calls return a **lazy** fpdart `TaskEither<DomainFailure, T>`. Nothing
runs until you `.run()` it, and `.run()` gives you back a
`Future<Either<DomainFailure, T>>`.
`isRight()`/`isLeft()` are methods, and `getOrElse`/`fold` receive the failure.
Why this seam is a tuple rather than a `Future` is recorded in
[`AGENTS.md`](https://github.com/taybiz/sku_catalog/blob/main/AGENTS.md).

## What is here

- **SKUs**: `CreateDeviceType`, `UpdateDeviceType`, `DeleteDeviceType`,
  `DuplicateDeviceType`, `FetchAllDeviceTypes`, `FetchDeviceTypeById`
- **Assemblies**: `AddSkuComponent` (refuses a loop or a missing SKU),
  `CreateSkuComponent`, `UpdateSkuComponent`, `DeleteSkuComponent`,
  `FetchSkuComponentsByDeviceType`, `WouldCreateAssemblyCycle`
- **Traits and attributes**: `CreateTrait` / `UpdateTrait` / `DeleteTrait`,
  the same for `TraitAttributeDefinition`, `FetchAttributesByTrait`
- **Resolution**: `ResolveTraitChain` (root to leaf) and `ResolveSchema`
  (merges a trait set's attributes; a child's definition of a key overrides the
  one it inherited, and the key keeps its first-seen position)
- **Places**: locate CRUD, `DescendantLocateIds`, `ResolveLocatePath`,
  `WouldCreateTreeCycle`
- **Devices**: create/update/delete/duplicate, `FetchDevicesByLocate`,
  `AssertUniqueDeviceName`
- **Manufacturers, images, meta**: CRUD and fetch

## Conventions are parameters, not constants

Two rules that a caller owns and this package therefore takes as arguments:

- `slotBoundTraitNames` on `UpdateDevice` / `DuplicateDevice` — the trait names
  meaning "this SKU lives inside a host", so those devices carry no place of
  their own. Pass your own words.
- `resolveAttributeAbbreviation(..., traitName:, attributeKey:)` — which trait
  carries a short code, and which attribute holds it.

## License

MIT.
