# Superseded — see `2026-10-08_091700-device-to-instance-rename.md`

The entity word was decided as **`Instance`** (not `Item`) and the release is a **major bump to
`1.0.0`**. This file is kept only as history; the plan to execute is
[`2026-10-08_091700-device-to-instance-rename.md`](2026-10-08_091700-device-to-instance-rename.md).

---

# (superseded) Rename `Device` → `Item` (and `DeviceType` → `Sku`) in `sku_catalog`

Status: **superseded** — the word is `Instance`; use the file linked above.

---

## Goal

Give the "SKU instantiated at a place" entity a neutral name so `sku_catalog` reads
correctly for books as well as electrical gear — recommended: **`Device` → `Item`**,
and the SKU entity **`DeviceType` → `Sku`** — with the existing 86-test suite plus one
new guard test proving the old word is gone.

## Current context / assumptions

Repo: `C:\awork_local\mine\sku_catalog`, branch `main` → `origin/main` (HTTPS push, PAT
helper), clean. Dart 3.13.1 via fvm (`export PATH="/c/Users/stayl/fvm/default/bin:$PATH"`).
Melos "workspace of one", gate = four scripts in `pubspec.yaml`.

The two entities in question (read from the source, do not re-guess them):

- `DeviceType` (`lib/src/domain/entities/device_type.dart`) — doc: *"A stock-keeping unit
  (product model) manufactured by a Manufacturer."* **It already is the SKU** — the README
  maps it 1:1 to "SKU", and the codebase around it is already SKU-flavoured
  (`SkuComponent`, `ISkuComponentRepository`, `skuModelNumber`, `abbreviateSku`,
  `skuRepository`). Only its class name still says "device".
- `Device` (`lib/src/domain/entities/device.dart`) — doc: *"A concrete installed device —
  one instance of a DeviceType (SKU) … The SKU is the class … a Device is the individual
  article."* Fields: `meta`, `deviceTypeId`, `locateId` (nullable — a device may be
  unplaced), `name`, `skuModelNumber`, `serialNumber`, `imageIds`, `traitIds`,
  `attributeValues`, `icon`. **It is the mapping of SKU → Locate plus instance traits.',
  Exactly as the user described.

Scale of the change (measured, `grep` over `lib test example`):
`Device` 411 occurrences, `device` 411, `DeviceType` 256, `deviceType` 147,
`IDevice*` 49 — across ~70 `.dart` files, 29 of which are **files whose name** contains
`device`.

Assumptions:
- This is a **pre-adoption breaking rename**; `sku_catalog` is `0.2.0` (pre-1.0) and
  `library_scanner` has not shipped on it yet. If that is wrong, see Open Questions.
- `test/` and `example/` are renamed too (they are not published, but a stale name in
  them breaks compile).
- **CHANGELOG/git history are not rewritten** — only a new entry is added. Historical
  entries that say "Device" are accurate history and stay.

## The name — decision

Measured against Flutter 3.47.1 (`packages/flutter/lib`), Dart core + `dart:ui`, and the
resolved deps in `pubspec.lock`:

| Instance word | Flutter word-hits | real clash? | verdict |
|---|---|---|---|
| **`Instance`** | 1342 — **all prose, 0 symbols** | analyzer/vm_service declare one (dev-only deps, never imported by a consumer) | **OK — recommended** |
| `Piece` | 55 | none | OK — plainest physical word |
| `Article` | 18 | none | OK, but in SAP/ERP "article" = the *product*, inverting the meaning |
| `Stock` (or `StockItem`) | **0** | none | OK; "stock" is uncountable so reads oddly as a class |
| `Item` | 1130 / 90 files | `DropdownMenuItem`, `BottomNavigationBarItem`, … | **out** |
| `Asset` | 173 / 20 files | `Image.asset`, `AssetImage`, `AssetBundle`, `rootBundle` | **out** |
| `Unit` | 129 | **fpdart declares a top-level `Unit`**, used in nearly every use-case signature here | **out (hard)** |
| `Copy` | 294 (all `copyWith`) | unreadable next to `copyWith` | **out** |
| `Record` | — | Dart 3 built-in `Record` type | **out** |
| `Part` | 459 | Dart keyword `part` | **out** |
| `Thing` | 82 (prose) | none | valid, but a bad *public* name — keep it for a private `typedef` if you like |

**Recommendation: `Instance`** for the entity, **`Sku`** for the model (`DeviceType` →
`Sku`; optional — drop the `device_type*` tasks to keep `DeviceType`). `Instance` is the
only candidate that needs no metaphor — an instance *of* a SKU is exactly what it is, and
`lib/src/domain/entities/device.dart`'s own doc already teaches it ("the SKU is the class;
a Device is the individual article"). Use-case names stay clean: `CreateInstance`,
`FetchInstancesByLocate`, `IInstanceRepository`. `Piece` is the fallback if you want the
plainer physical word (`CreatePiece`, `FetchPiecesByLocate`).

> **NOTE — the steps below are written for the word `Item`.** They are otherwise
> word-agnostic: on picking `Instance` (or `Piece`), the substitution table in "Architecture"
> and the handful of code snippets get one mechanical find/replace (`Item`→`Instance`,
> `item`→`instance`, plus `item_repository.dart`/`item.dart` file names) and are then ready
> to execute.

If you later want a product word inside `library_scanner`, keep it there:
`typedef Copy = Item;` — the published API stays neutral (the boundary test enforces that).

### Name-collision check for `Item` (verified, not assumed)

`Item` is **not** a Dart reserved word or built-in identifier, is absent from `dart:core`,
and no resolved dependency (`fpdart`, `equatable`, `shouldly`, `test`, `melos` + transitives,
from `pubspec.lock`) declares a top-level `Item`. Flutter 3.47.1
(`packages/flutter/lib` = material + widgets + foundation) declares no bare `Item` — the
only `Item*` top-level is `typedef ItemExtentBuilder`. So importing
`package:sku_catalog/sku_catalog.dart` next to `flutter/material.dart` is unambiguous; same
for `Sku`. Residual risks are social, not syntactic: (a) a *future* dependency that exports
a top-level `Item` needs `hide Item`/a prefix at the call site — no change in this package;
(b) Flutter widget names are `*Item`-suffixed (`DropdownMenuItem`, `PopupMenuItem`), so a
bare `Item` reads clearest in `domain`/`usecases` files and could momentarily confuse in a
widget file — cosmetic only.

## Architecture / proposed approach

A pure **mechanical rename** — no behaviour changes, no new logic — driven by one ordered
substitution table (longest/most-specific token first, so `DeviceType` is replaced before
`Device`). Files are moved with `git mv`, contents rewritten with a single `perl` pass over
the tracked `.dart` files, then the existing suite is the oracle. One new boundary test is
added **first** (it fails), so the rename is driven and then locked in by a failing→passing
test rather than by hope.

Ordered substitution (apply `s/…/…/g` in exactly this order — order is load-bearing):
```
1  DeviceType   -> Sku
2  deviceTypeId -> skuId
3  deviceType   -> sku
4  device_type_id -> sku_id
5  device_type  -> sku
6  Device       -> Item
7  deviceId     -> itemId
8  device_id    -> item_id
9  device       -> item
```
(Substrings are matched deliberately: camelCase has no word boundaries, so `\bDevice\b`
would miss `CreateDevice`. Ordering makes each replacement safe.)

---

## Step-by-step tasks

Set up the shell once (used by every task):
```bash
cd /c/awork_local/mine/sku_catalog
export PATH="/c/Users/stayl/fvm/default/bin:$PATH"
dart --version   # expect: Dart SDK version: 3.13.1 (stable) ... on "windows_x64"
```
Baseline (do this once, before touching anything):
```bash
dart pub get
dart test        # expect: All tests passed!  (86 tests)
```
If the baseline is not green, **stop** — fix that first; a rename cannot be verified on a
red suite.

### Task 1 — Add the guard test (RED)  [~4 min]

File: `test/boundary_test.dart`. Inside the existing
`group('When every file under lib/ is read', …)`, add a fourth `test(...)` as a sibling of
`Then none of them names a product` (append after that test's closing `});`):

```dart
      test('Then none of them still calls anything a device', () {
        final offenders = <String>[];
        for (final entity in Directory('lib').listSync(recursive: true)) {
          if (entity is! File || !entity.path.endsWith('.dart')) continue;
          final text = entity.readAsStringSync().toLowerCase();
          if (text.contains('device')) offenders.add(entity.path);
        }

        offenders.should.beEmpty();
      });
```

Run:
```bash
dart test test/boundary_test.dart
```
Expected: **FAIL** — a long `offenders` list of nearly every file under `lib/`
(e.g. `lib/src/domain/entities/device.dart`, `lib/src/usecases/create_device.dart`, …).
This proves the guard fires. If it passes here, the guard is wrong — fix it before going on.

Commit:
```bash
git add test/boundary_test.dart
git commit -m "test(boundary): guard that lib/ stops naming a device (RED)"
```

### Task 2 — Move the files with `git mv`  [~4 min]

```bash
cd /c/awork_local/mine/sku_catalog
git mv lib/src/domain/entities/device.dart                    lib/src/domain/entities/item.dart
git mv lib/src/domain/entities/device_type.dart               lib/src/domain/entities/sku.dart
git mv lib/src/domain/contracts/device_repository.dart        lib/src/domain/contracts/item_repository.dart
git mv lib/src/domain/contracts/device_type_repository.dart   lib/src/domain/contracts/sku_repository.dart
git mv lib/src/domain/value_objects/device_report_property.dart lib/src/domain/value_objects/report_property.dart
git mv lib/src/usecases/create_device.dart                    lib/src/usecases/create_item.dart
git mv lib/src/usecases/update_device.dart                    lib/src/usecases/update_item.dart
git mv lib/src/usecases/delete_device.dart                    lib/src/usecases/delete_item.dart
git mv lib/src/usecases/duplicate_device.dart                 lib/src/usecases/duplicate_item.dart
git mv lib/src/usecases/fetch_device_by_id.dart               lib/src/usecases/fetch_item_by_id.dart
git mv lib/src/usecases/fetch_all_devices.dart                lib/src/usecases/fetch_all_items.dart
git mv lib/src/usecases/fetch_devices_by_locate.dart          lib/src/usecases/fetch_items_by_locate.dart
git mv lib/src/usecases/assert_unique_device_name.dart        lib/src/usecases/assert_unique_item_name.dart
git mv lib/src/usecases/device_naming.dart                    lib/src/usecases/item_naming.dart
git mv lib/src/usecases/device_type_use_cases.dart            lib/src/usecases/sku_use_cases.dart
git mv lib/src/usecases/create_device_type.dart               lib/src/usecases/create_sku.dart
git mv lib/src/usecases/update_device_type.dart               lib/src/usecases/update_sku.dart
git mv lib/src/usecases/delete_device_type.dart               lib/src/usecases/delete_sku.dart
git mv lib/src/usecases/duplicate_device_type.dart            lib/src/usecases/duplicate_sku.dart
git mv lib/src/usecases/fetch_device_type_by_id.dart          lib/src/usecases/fetch_sku_by_id.dart
git mv lib/src/usecases/fetch_all_device_types.dart           lib/src/usecases/fetch_all_skus.dart
git mv lib/src/usecases/fetch_sku_components_by_device_type.dart lib/src/usecases/fetch_components_by_sku.dart
git mv test/support/memory_device_repository.dart             test/support/memory_item_repository.dart
git mv test/support/memory_device_type_repository.dart        test/support/memory_sku_repository.dart
git mv test/device_lifecycle_test.dart                        test/item_lifecycle_test.dart
git mv test/device_naming_test.dart                           test/item_naming_test.dart
```
If you chose Option B (keep `DeviceType`), drop the 8 `device_type*` moves above and
Task 6/7's `DeviceType` steps.

Verify:
```bash
git status --short | grep 'device'
```
Expected: only `R` (rename) lines are gone — i.e. **no output** (every device-named file is
now moved). `git status` will still show the destination names as renamed.

### Task 3 — Rewrite the identifiers (GREEN, part 1)  [~5 min]

```bash
cd /c/awork_local/mine/sku_catalog
FILES=$(git ls-files 'lib/*.dart' 'lib/**/*.dart' 'test/*.dart' 'test/**/*.dart' 'example/*.dart')
perl -pi -e 's/DeviceType/Sku/g; s/deviceTypeId/skuId/g; s/deviceType/sku/g; s/device_type_id/sku_id/g; s/device_type/sku/g; s/Device/Item/g; s/deviceId/itemId/g; s/device_id/item_id/g; s/device/item/g;' $FILES
```
(Option B: use `'s/Device/Item/g; s/deviceId/itemId/g; s/device_id/item_id/g; s/device/item/g;'` only.)

Then fix the two stutters the machine produces (prose/paths already handled by the pass):
- `lib/src/usecases/fetch_components_by_sku.dart`: rename class
  `FetchSkuComponentsBySku` → `FetchComponentsBySku` and its `call` stays
  `TaskEither<DomainFailure, List<SkuComponent>>`.
- `lib/src/domain/value_objects/report_property.dart`: the class is now
  `ItemReportProperty`; rename it to `ReportProperty` (update the doc comment and any
  references — `grep -rn 'ItemReportProperty' lib test`).

Verify no stragglers in the tracked dart files:
```bash
git ls-files '*.dart' | xargs grep -In 'device' || echo "clean"
```
Expected: `clean` (the word "device" appears nowhere in any Dart file).

### Task 4 — Refresh the barrels and re-run the gate  [~4 min]

The barrel files were rewritten by Task 3 (their `export '…'` lines now point at the new
file names). Confirm and format:
```bash
dart format .                       # rewrites in place (the gate's `format` script only checks)
dart analyze --fatal-infos --fatal-warnings
```
Expected: `Formatted … changed N files`, then **`No issues found!`**. If `analyze` reports
a broken import, a barrel line was missed — `grep -rn "device" lib/` and fix by hand.

```bash
dart test
```
Expected: **`All tests passed!`** — the 86 originals plus the Task 1 guard.

Commit:
```bash
git add -A
git commit -m "refactor: rename Device->Item and DeviceType->Sku (breaking)"
```

### Task 5 — Update README, CHANGELOG, version  [~5 min]

- `pubspec.yaml` line 4: `version: 0.2.0` → `version: 0.3.0`.
- `README.md`: replace the two model-table rows (lines ~26, 32) — `DeviceType` → `Sku`
  (drop "A **SKU** — " since it *is* the SKU) and `Device` → `Item`; update every code
  sample (`DeviceType(`, `Device(`, `CreateDevice`, `CreateDeviceType`, `ResolveSchema`
  sample's `breaker.traitIds`, `AggregateBillOfMaterials`, and the `IDeviceTypeRepository`
  contract excerpt → `ISkuRepository`). Reword the "devices that instantiate them" line in
  the intro to "items that instantiate them".
- `CHANGELOG.md`: add under `## Unreleased` (or a fresh `## 0.3.0` heading):

  ```md
  ## 0.3.0

  - **Breaking:** the SKU entity is renamed `DeviceType` → `Sku` and the instance entity
    `Device` → `Item` (files, classes, contracts, use cases, JSON keys
    `device_type_id` → `sku_id`). The model is unchanged; only the vocabulary. A book copy
    and a breaker instance are both `Item`s now. `Locate` is untouched.
  ```

  Do **not** rewrite the 0.1.0/0.2.0 entries — they are history.

Verify:
```bash
grep -In 'device' README.md pubspec.yaml   # expect: no output
dart run melos run format && dart run melos run analyze && dart run melos run test
```
Expected: `All tests passed!` and `No issues found!` (the melos scripts are the CI gate).

Commit:
```bash
git add -A
git commit -m "docs: rename vocabulary to Sku/Item; bump to 0.3.0"
```

### Task 6 — (Option A only) Confirm the SKU side is coherent  [~4 min]

```bash
grep -rn "Sku" lib/src/domain/contracts/sku_repository.dart lib/src/domain/entities/sku.dart | head
git ls-files | grep -i device || echo "no device-named files"
```
Expected: `no device-named files`, and `ISkuRepository`/`class Sku` present. Then:
```bash
dart run melos run publish-dry
```
Expected: `Package has 0 warnings.` and a ~1 s/36 KB archive. **Check the printed file
list**: `lib/…skus.dart`, `lib/…/sku.dart`, `lib/…/item.dart` must be present;
`test/support/` must be absent.

### Task 7 — Publish-dry on a committed tree + push  [~3 min]

```bash
git status --short         # expect: clean (pub rejects a dirty tree)
dart run melos run publish-dry
git push origin main
```
Expected: push succeeds via the HTTPS PAT helper. If it 403s, stop and report — do not
retry blindly.

---

## Tests / validation

- A mechanical rename adds **no new behaviour**, so the 86 existing tests are the
  correctness oracle — they must stay green throughout (this *is* the verification for
  Tasks 2–4). The only new test is the Task 1 guard, which is genuinely TDD-driven:
  it must **fail before** the rename and **pass after**, and it then ratchets the word out
  of `lib/` for good.
- Gate (identical to CI), run at the end of Tasks 4, 5 and 7:
  ```bash
  dart run melos run format && dart run melos run analyze && dart run melos run test && dart run melos run publish-dry
  ```
  Expected terminal lines: `No issues found!`, `All tests passed!`, `Package has 0 warnings.`
- Completeness check (must be empty):
  ```bash
  git ls-files '*.dart' | xargs grep -In 'device'
  ```

## Risks, tradeoffs, and open questions

- **Wire format.** Task 3 changes the JSON key `device_type_id` → `sku_id` (the other keys
  are untouched). Safe **only** if `library_scanner` has no persisted records yet. If it
  does: keep the wire stable by hand-editing `item.dart`'s `toJson`/`fromJson` to read/write
  the old key, and split the rename into "Dart names now, wire keys later".
- **`Sku` vs `DeviceType` churn.** Option A touches 256 `DeviceType` occurrences and
  cascades into `SkuComponent` (`parentDeviceTypeId` → `parentSkuId`); Option B is ~⅓ the
  diff but leaves the model word odd. This is the one call worth making deliberately.
- **Two stutters the machine cannot fix** (`FetchSkuComponentsBySku`, `ItemReportProperty`)
  are called out in Task 3 as manual touch-ups — skip them and you get awkward names, not
  broken code.
- **`test/` names are not published** (`.pubignore` drops the tree), so their rename is
  cosmetic but still required to keep the suite compiling.
- **No deprecation/alias layer.** Because the consumer has not adopted the package, a hard
  rename (bump 0.3.0) is cleaner than `@Deprecated typedef`s, which would keep the word
  alive and trip the Task 1 guard. If a *published* consumer existed, we would instead ship
  `typedef Item = Device;` for one minor and drop it next.
- **Open questions for you:**
  1. Pick the word: **A `Item`/`Sku`** (recommended), B `Item`/keep `DeviceType`,
     C `Instance`, D `Asset`, or your own.
  2. Has `library_scanner` already persisted `sku_catalog` records? If yes, keep the
     `device_type_id` wire key (see Wire format above).
  3. Does `library_scanner` live in `C:\awork_local\mine\` — point me at it and I can add a
     follow-on plan for the consumer-side swap (its own `inventory` type → `Item`,
     backend implementing `IItemRepository`/`ISkuRepository`).

## Appendix — consumer side (`library_scanner`), out of scope for this plan

Once 0.3.0 is pushed, `library_scanner` consumes it as:
- `DeviceType` → `Sku` becomes "Book/Edition title"; `Device` → `Item` becomes "the physical
  copy". Both are already `Locate`-aware, and `Item.attributeValues` gets filled from the
  resolved traits — the behaviour you liked is unchanged, only the noun.
- If you want a product word *inside* `library_scanner`, alias locally:
  `typedef Copy = Item;` and `typedef Title = Sku;` — never in the package (the boundary
  test forbids product words in `lib/`).
- Its backend implements `ISkuRepository`, `IItemRepository`, `ILocateRepository`, … over
  whatever store it has; the in-memory doubles in `test/support/` in this repo are the
  reference shape (not published).
