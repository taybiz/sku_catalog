# Backlog or Bugs

## Open

- [ ] **`isUnique` is enforced on the instance layer only.** `CreateInstance`,
  `UpdateInstance` and `DuplicateInstance` assert it against instances; a value
  written on a SKU, a `Locate` or a `Manufacturer` — all three hold
  `attributeValues` — is not asserted, because uniqueness is a statement about
  articles. If a unique attribute on a place or a maker is wanted, the same
  `AssertUniqueAttributeValues` shape extends to those write paths.

## Deviations from the Bible (flagged for review — do NOT auto-fix)

A deviation is a place the code and the bible disagree; it is recorded for a
human decision, not auto-fixed. Empty at the moment — the last one to sit here
(the adapter rules, which a package with no adapters never owed) is a decision
recorded in the CHANGELOG.

