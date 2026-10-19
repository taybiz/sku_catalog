# Backlog or Bugs

## Open

- [ ] **Every write-time rule scans its whole store, and an adapter cannot fix that.**
  `AssertUniqueInstanceName`, `AssertUniqueAttributeValues`,
  `AssertUniqueModelNumber`, `DeleteSku` and `DeleteInstanceAndUnusedSku` each read
  `fetchAll()` and scan in Dart. The closest thing to a narrow read is
  `IInstanceRepository.fetchByLocate`, and even it cannot serve the name rule: it takes
  `required String locateId`, while the rule also covers the unplaced group
  (`locateId == null`), where no store can index anything. The rest need reads the
  contracts do not have — `ISkuRepository` is `fetchAll`/`fetchById`/`create`/`update`/
  `delete`, nothing by manufacturer. So the README's "a real adapter that wants that
  cheap indexes the unique keys on its own side" is not achievable today: there is no
  narrower call for an adapter to index. Either give the contracts the reads a real
  store wants and let the rules use them, or correct that sentence and say plainly that
  a large catalog pays one scan per write. Widening or adding a contract method breaks
  every adapter author that implements it, so the shop window for that is a MAJOR.
  Nothing is wrong at the current scale — this is the item to pick up before a consumer
  holds hundreds of thousands of rows.

