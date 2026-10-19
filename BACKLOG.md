# Backlog or Bugs

## Open

- [ ] **Every write-time rule scans its whole store, and an adapter cannot fix that.**
  `AssertUniqueInstanceName`, `AssertUniqueAttributeValues`,
  `AssertUniqueModelNumber`, `DeleteSku` and `DeleteInstanceAndUnusedSku` each read
  `fetchAll()` and scan in Dart. One of them is already avoidable:
  `IInstanceRepository` declares `fetchByLocate`, and the name rule scans every
  instance instead of using it. The others need a read the contracts do not have —
  `ISkuRepository` is `fetchAll`/`fetchById`/`create`/`update`/`delete`, nothing by
  manufacturer. So the README's "a real adapter that wants that cheap indexes the
  unique keys on its own side" is not achievable today: there is no narrower call for
  an adapter to index. Either give the contracts the reads a real store wants and let
  the rules use them, or correct that sentence and say plainly that a large catalog
  pays one scan per write. Nothing is wrong at the current scale — this is the item to
  pick up before a consumer holds hundreds of thousands of rows.

