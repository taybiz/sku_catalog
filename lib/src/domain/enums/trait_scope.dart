/// Which entity category a trait applies to.
///
/// Three carriers, no `instance`: an instance is the *realization* of a SKU —
/// it holds the **values** of the traits in scope for it, and is never a
/// classification target of its own. Do not add `instance` here.
enum TraitScope {
  /// SKU.
  sku,

  /// Manufacturer.
  manufacturer,

  /// Physical location.
  locate,
}
