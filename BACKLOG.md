# Backlog or Bugs

## Open

- [ ] **The contracts are minimal, and every write-time rule pays for it.** Each rule
  scans its whole store, because they call `fetchAll()`: `AssertUniqueInstanceName`,
  `AssertUniqueAttributeValues`, `AssertUniqueModelNumber`, `DeleteSku`,
  `DeleteInstanceAndUnusedSku`. No contract read is narrow enough to help —
  `IInstanceRepository.fetchByLocate` takes a `required String locateId` while the name
  rule also covers the unplaced group (`locateId == null`), and `ISkuRepository` has
  nothing by manufacturer. The README states the scan cost plainly, so the open
  question is the capability set itself: give a real store the reads (and the wipe) it
  wants, in one MAJOR — a widened or added method breaks every adapter author that
  implements the contracts. Nothing is wrong at the current scale; pick this up before
  a consumer holds hundreds of thousands of rows.

