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

