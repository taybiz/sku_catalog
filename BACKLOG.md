# Backlog or Bugs

## Open

- [ ] **`ReportProperty` is exported and used by nothing.**
  `lib/src/domain/value_objects/report_property.dart` is public API — the domain
  barrel and the front door both export it — with no producer and no consumer
  anywhere in `lib/`, `test/` or `example/`. It is the one file the coverage floor
  does not reach, deliberately: writing a test for it would bless dead API. Either
  remove it in the next major (breaking, which is why it is not done here) or give
  it a producer in `ResolveEffectiveAttributes`.

- [ ] **`imageIds` lives on the three entities `ImageRecord` already owns.**
  `Sku`, `Instance` and `Locate` each carry `imageIds`, while `ImageRecord` names
  its owner (`owner`, `ownerId`) — and that is the copy `lib/` reads:
  `DeleteInstance` cascades an article's images by owner and `FetchImageRecords`
  fetches by owner. Nothing in `lib/` maintains or consults the owning entity's
  list, so the two copies of one fact can only disagree. Remove the field (a
  MAJOR) or give it a producer and a consumer — one home, not two.

- [ ] **`Instance.skuModelNumber` is a projection the SKU already holds.**
  Its doc says "copied from the SKU for labelling", and the only code that touches
  it is `DuplicateInstance`, which copies the copy's own value forward — so it can
  disagree with `Sku.modelNumber` and nothing reconciles them. The sibling
  consumer `dacalcd` carries it through its own `Disc`, so removing it is a MAJOR
  that reaches that consumer; the alternative is a resolver that reads the value
  through `skuId` (as `ResolveInstanceSchema` reads the rest of the model).

## Deviations from the Bible (flagged for review — do NOT auto-fix)

A deviation is a place the code and the bible disagree; it is recorded for a
human decision, not auto-fixed. Empty at the moment — the last one to sit here
(the adapter rules, which a package with no adapters never owed) is a decision
recorded in the CHANGELOG.

