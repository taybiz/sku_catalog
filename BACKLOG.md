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

