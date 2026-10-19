# Backlog or Bugs

## Open

- [ ] **`ReportProperty` is reporting, and reporting belongs to whoever reports.**
  `lib/src/domain/value_objects/report_property.dart` is a label/value/unit row —
  the shape of a device *card* — exported by the domain barrel and the front door,
  with no producer in `lib/` and exactly one consumer outside it: `circuit_planner`'s
  `typedef DeviceReportProperty = ReportProperty`, used by its `DescribeDevice` to
  build four rows (Name, SKU, Manufacturer, Location). The README's "deliberately
  not here" list already names reports; this class is the stray exception. It is also
  the one file the coverage floor cannot reach (0/3 lines), since testing it would
  bless dead API. **Not a 3.0.0 item** — everything in that release cured a drift or
  enforced a claimed invariant, and this is a placement call with nothing wrong
  behind it.
  **Order:** the consumer defines its own row type first (it is *their* card, and
  whether it grows an attribute id or a data type for rendering is their call), then
  this package deletes the file and its export. Both are one edit in the same
  function: `circuit_planner`'s `describe_device.dart` already has to change a line
  for 3.0.0 — it reads `device.skuModelNumber`, which that release removed.

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

