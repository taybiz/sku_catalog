# Backlog or Bugs

## Open

- [ ] **`ReportProperty` is exported and used by nothing.**
  `lib/src/domain/value_objects/report_property.dart` is public API — the domain
  barrel and the front door both export it — with no producer and no consumer
  anywhere in `lib/`, `test/` or `example/`. It is the one file the coverage floor
  does not reach, deliberately: writing a test for it would bless dead API. Either
  remove it in the next major (breaking, which is why it is not done here) or give
  it a producer in `ResolveEffectiveAttributes`.

