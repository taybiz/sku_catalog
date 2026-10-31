# Backlog or Bugs

## Open

- [ ] **The seam's docs name only the closure, never the tear-off route.** An adapter that
  already holds a client writes the seam as a class with a generic `call` and hands it over
  as `uow.call` — the shape both `library_scanner` adapters use (`SembastUnitOfWork` in
  `datastore_sembast`, `InMemoryUnitOfWork` in `datastore_inmemory`). Neither place that
  tells a consumer how to implement the seam says so: `UnitOfWork`'s doc has an adapter
  "write one as a closure over its client" and the class reference beside it is about the
  `implements` form the function type replaced, and the README carries the same
  closure-only sentence. The distinction the sentence is missing is not cosmetic: the
  object is not a value of the seam type — it coerces only where a context demands the
  function type, so a `Map<String, Object>` holding the object and cast to `UnitOfWork`
  throws at runtime, where `store.call` works. One sentence in each place; no API change,
  no version worth a number.

