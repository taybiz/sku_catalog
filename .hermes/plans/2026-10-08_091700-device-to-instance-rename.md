# Rename `Device` → `Instance` (and `DeviceType` → `Sku`) — sku_catalog 1.0.0

Status: **plan only** — no code changed. Word decided (`Instance` / `Sku`), version decided
(**major → 1.0.0**); ready to execute.

---

## Goal

Rename the "SKU instantiated at a place" entity **`Device` → `Instance`** and the SKU entity
**`DeviceType` → `Sku`**, then release the rename as **1.0.0** — with the existing 86-test
suite plus one new guard test proving the old word is gone.

## Current context / assumptions

Repo: `C:\awork_local\mine\sku_catalog`, branch `main` → `origin/main` (HTTPS push, PAT
helper), clean. Dart 3.13.1 via fvm (`export PATH="/c/Users/stayl/fvm/default/bin:$PATH"`).
Melos "workspace of one"; gate = four scripts in `pubspec.yaml`.

The two entities in question (read from source, do not re-guess):

- `DeviceType` (`lib/src/domain/entities/device_type.dart`) — doc: *"A stock-keeping unit
  (product model) manufactured by a Manufacturer."* **It already is the SKU** — the README
  maps it 1:1 to "SKU", and the code around it is already SKU-flavoured (`SkuComponent`,
  `ISkuComponentRepository`, `skuModelNumber`, `abbreviateSku`, `skuRepository`). Only its
  class name still says "device".
- `Device` (`lib/src/domain/entities/device.dart`) — doc: *"A concrete installed device — one
  instance of a DeviceType (SKU) … The SKU is the class … a Device is the individual
  article."* Fields: `meta`, `deviceTypeId`, `locateId` (nullable — may be unplaced), `name`,
  `skuModelNumber`, `serialNumber`, `imageIds`, `traitIds`, `attributeValues`, `icon`.
  **It is the mapping of SKU → Locate plus instance traits.**

Scale (measured, `grep` over `lib test example`): `Device` 411 occurrences, `device` 411,
`DeviceType` 256, `deviceType` 147, `IDevice*` 49 — across ~70 `.dart` files, 29 of which are
**files whose name** contains `device`.

Assumptions:
- **Breaking, for a published package**: `sku_catalog` is currently `0.2.0`; this rename ships
  as **`1.0.0`** (major). No known consumer has adopted it yet, but the published-package rule
  still applies.
- `test/` and `example/` are renamed too (not published, but a stale name breaks compile).
- **CHANGELOG/git history are not rewritten** — historical 0.1.0/0.2.0 entries stay; the
  rename gets a new `## 1.0.0` entry.

## The name — decided

`Instance` for the entity, `Sku` for the model. (`Sku` is optional — drop the `device_type*`
tasks to keep `DeviceType`.)

Collision evidence, measured against Flutter 3.47.1 (`packages/flutter/lib`), Dart core +
`dart:ui`, and the resolved deps in `pubspec.lock`:

| Candidate | Verdict |
|---|---|
| **`Instance`** | **chosen** — 1342 Flutter word-hits but **all prose, 0 top-level symbols**; no `Instance` in Flutter/`dart:core`/`dart:ui` (only analyzer/vm_service, dev-only deps never imported by a consumer). An instance *of* a SKU is definitionally what it is |
| `Piece` | clean fallback (55 hits); plainer but vaguer |
| `Item` | out — 1130 Flutter hits (`DropdownMenuItem`, `PopupMenuItem`, …) |
| `Asset` | out — 173 hits (`Image.asset`, `AssetImage`, `AssetBundle`) |
| `Unit` | out hard — **fpdart declares a top-level `Unit`**, used in nearly every use-case signature here |
| `Copy` | out — collides with `copyWith` |
| `Record` | out — Dart 3 built-in `Record` type |
| `Part` | out — Dart keyword `part` |
| `Thing` | valid, but a bad public API name — keep it for a private `typedef` if you like |

## Version policy — major bump to 1.0.0

This is a **breaking change to a published package**, so the version goes **`0.2.0` →
`1.0.0`** (major), not a 0.x minor. Consequences baked into the plan:
- **No deprecation/alias shim.** A major bump is exactly the licence to remove the old name;
  shipping `@Deprecated typedef Instance = Device;` would contradict the bump (and trip the
  Task 1 guard). Breaking it cleanly is the point.
- The `1.0.0` release also signals the vocabulary is now **final** — the generic
  `Sku`/`Instance` pair is the last word on these two entities.
- `dart pub publish` (the real publish) is a **human step** after the dry run passes; the plan
  stops at a pushed `main` with a green dry run.

## Architecture / proposed approach

A pure **mechanical rename** — no behaviour changes, no new logic — driven by one ordered
substitution table (longest/most-specific token first, so `DeviceType` is replaced before
`Device`). Files are moved with `git mv`, contents rewritten with a single `perl` pass over
tracked `.dart` files, then the existing suite is the oracle. One new boundary test is added
**first** (it fails), so the rename is driven and locked in by a failing→passing test.

Ordered substitution (apply `s/…/…/g` in exactly this order — order is load-bearing):
```
1  DeviceType     -> Sku
2  deviceTypeId   -> skuId
3  deviceType     -> sku
4  device_type_id -> sku_id
5  device_type    -> sku
6  Device         -> Instance
7  deviceId       -> instanceId
8  device_id      -> instance_id
9  device         -> instance
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
Baseline (once, before touching anything):
```bash
dart pub get
dart test        # expect: All tests passed!  (86 tests)
```
If the baseline is not green, **stop** — a rename cannot be verified on a red suite.

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
Expected: **FAIL** — a long `offenders` list of nearly every file under `lib/` (e.g.
`lib/src/domain/entities/device.dart`, `lib/src/usecases/create_device.dart`, …). This proves
the guard fires. If it passes here, the guard is wrong — fix it before going on.

Commit:
```bash
git add test/boundary_test.dart
git commit -m "test(boundary): guard that lib/ stops naming a device (RED)"
```

### Task 2 — Move the files with `git mv`  [~4 min]

```bash
cd /c/awork_local/mine/sku_catalog
git mv lib/src/domain/entities/device.dart                      lib/src/domain/entities/instance.dart
git mv lib/src/domain/entities/device_type.dart                 lib/src/domain/entities/sku.dart
git mv lib/src/domain/contracts/device_repository.dart          lib/src/domain/contracts/instance_repository.dart
git mv lib/src/domain/contracts/device_type_repository.dart     lib/src/domain/contracts/sku_repository.dart
git mv lib/src/domain/value_objects/device_report_property.dart lib/src/domain/value_objects/report_property.dart
git mv lib/src/usecases/create_device.dart                      lib/src/usecases/create_instance.dart
git mv lib/src/usecases/update_device.dart                      lib/src/usecases/update_instance.dart
git mv lib/src/usecases/delete_device.dart                      lib/src/usecases/delete_instance.dart
git mv lib/src/usecases/duplicate_device.dart                   lib/src/usecases/duplicate_instance.dart
git mv lib/src/usecases/fetch_device_by_id.dart                 lib/src/usecases/fetch_instance_by_id.dart
git mv lib/src/usecases/fetch_all_devices.dart                  lib/src/usecases/fetch_all_instances.dart
git mv lib/src/usecases/fetch_devices_by_locate.dart            lib/src/usecases/fetch_instances_by_locate.dart
git mv lib/src/usecases/assert_unique_device_name.dart          lib/src/usecases/assert_unique_instance_name.dart
git mv lib/src/usecases/device_naming.dart                      lib/src/usecases/instance_naming.dart
git mv lib/src/usecases/device_type_use_cases.dart              lib/src/usecases/sku_use_cases.dart
git mv lib/src/usecases/create_device_type.dart                 lib/src/usecases/create_sku.dart
git mv lib/src/usecases/update_device_type.dart                 lib/src/usecases/update_sku.dart
git mv lib/src/usecases/delete_device_type.dart                 lib/src/usecases/delete_sku.dart
git mv lib/src/usecases/duplicate_device_type.dart              lib/src/usecases/duplicate_sku.dart
git mv lib/src/usecases/fetch_device_type_by_id.dart            lib/src/usecases/fetch_sku_by_id.dart
git mv lib/src/usecases/fetch_all_device_types.dart             lib/src/usecases/fetch_all_skus.dart
git mv lib/src/usecases/fetch_sku_components_by_device_type.dart lib/src/usecases/fetch_components_by_sku.dart
git mv test/support/memory_device_repository.dart               test/support/memory_instance_repository.dart
git mv test/support/memory_device_type_repository.dart          test/support/memory_sku_repository.dart
git mv test/device_lifecycle_test.dart                          test/instance_lifecycle_test.dart
git mv test/device_naming_test.dart                             test/instance_naming_test.dart
```
If you keep `DeviceType` (no `Sku`), drop the 8 `device_type*` moves above and Task 6's `Sku`
checks.

Verify:
```bash
git status --short | grep device ; echo "exit=$?"   # expect: no lines, exit=1
```
(`git status` shows the destinations as `R` renames — every device-named file is now moved.)

### Task 3 — Rewrite the identifiers (GREEN, part 1)  [~5 min]

```bash
cd /c/awork_local/mine/sku_catalog
FILES=$(git ls-files 'lib/*.dart' 'lib/**/*.dart' 'test/*.dart' 'test/**/*.dart' 'example/*.dart')
perl -pi -e 's/DeviceType/Sku/g; s/deviceTypeId/skuId/g; s/deviceType/sku/g; s/device_type_id/sku_id/g; s/device_type/sku/g; s/Device/Instance/g; s/deviceId/instanceId/g; s/device_id/instance_id/g; s/device/instance/g;' $FILES
```
(Keeping `DeviceType`: use
`'s/Device/Instance/g; s/deviceId/instanceId/g; s/device_id/instance_id/g; s/device/instance/g;'` only.)

Then fix the stutters the machine produces:
- `lib/src/usecases/fetch_components_by_sku.dart`: class is now `FetchSkuComponentsBySku` —
  rename to `FetchComponentsBySku` (return type unchanged:
  `TaskEither<DomainFailure, List<SkuComponent>>`).
- `lib/src/domain/value_objects/report_property.dart`: the class is now
  `InstanceReportProperty`; rename to `ReportProperty` — update the doc comment and all
  references: `grep -rn 'InstanceReportProperty' lib test`.

Verify no stragglers in tracked Dart files:
```bash
git ls-files '*.dart' | xargs grep -In 'device' || echo "clean"
```
Expected: `clean`.

### Task 4 — Refresh the barrels and re-run the gate  [~4 min]

The barrels (`lib/src/domain/domain.dart`, `lib/src/domain/contracts/contracts.dart`,
`lib/src/usecases/usecases.dart`, `test/support/memory_backends.dart`) were rewritten by
Task 3, so their `export '…'` lines point at the new file names. Confirm and format:
```bash
dart format .
dart analyze --fatal-infos --fatal-warnings
```
Expected: `Formatted … changed N files`, then **`No issues found!`**. A broken import means a
barrel line was missed — `grep -rn "device" lib/` and fix by hand.

```bash
dart test
```
Expected: **`All tests passed!`** — the 86 originals plus the Task 1 guard.

Commit:
```bash
git add -A
git commit -m "refactor!: rename Device->Instance and DeviceType->Sku"
```

### Task 5 — Bump to 1.0.0, update README + CHANGELOG  [~6 min]

- `pubspec.yaml` line 4: `version: 0.2.0` → `version: 1.0.0`.
- `README.md`: replace the two model-table rows (~lines 26, 32) — `DeviceType` → `Sku` (drop
  the "A **SKU** —" lead-in since it *is* the SKU) and `Device` → `Instance`; update every
  code sample (`DeviceType(`, `Device(`, `CreateDevice`, `CreateDeviceType`,
  `AggregateBillOfMaterials`, and the `IDeviceTypeRepository` contract excerpt →
  `ISkuRepository`). Reword the intro "devices that instantiate them" → "instances that
  instantiate them".
- `CHANGELOG.md`: add a fresh `## 1.0.0` heading **above** `## 0.2.0` (do **not** rewrite the
  older entries — they are history):

  ```md
  ## 1.0.0

  - **Breaking (major):** the SKU entity is renamed `DeviceType` → `Sku` and the instance
    entity `Device` → `Instance` — files, classes, contracts, use cases, and the JSON key
    `device_type_id` → `sku_id`. The model and its behaviour are unchanged; only the
    vocabulary. A book copy and a breaker instance are both `Instance`s now. `Locate` is
    untouched. No deprecation shims: adopters rename, in one step. This release also marks
    the vocabulary as final (1.0).
  ```

Verify:
```bash
grep -n '^version:' pubspec.yaml            # expect: version: 1.0.0
grep -In 'device' README.md pubspec.yaml || echo "clean"   # expect: clean
dart run melos run format && dart run melos run analyze && dart run melos run test
```
Expected: `All tests passed!` and `No issues found!` (the melos scripts are the CI gate).

Commit:
```bash
git add -A
git commit -m "chore!: release 1.0.0 - Sku/Instance vocabulary"
```

### Task 6 — Confirm the SKU side is coherent  [~4 min]

```bash
grep -rn "Sku" lib/src/domain/contracts/sku_repository.dart lib/src/domain/entities/sku.dart | head
git ls-files | grep -i device || echo "no device-named files"
dart run melos run publish-dry
```
Expected: `no device-named files`; `ISkuRepository`/`class Sku` present; publish-dry prints
`Package has 0 warnings.` and a small archive. **Check the printed file list**:
`lib/…/instance.dart`, `lib/…/sku.dart`, `lib/…/skus.dart` present; `test/support/` absent.

### Task 7 — Publish-dry on a committed tree + push  [~3 min]

```bash
git status --short          # expect: clean (pub rejects a dirty tree)
dart run melos run publish-dry
git push origin main
```
Expected: push succeeds via the HTTPS PAT helper. If it 403s, stop and report — do not retry
blindly. **`dart pub publish` (the real release of 1.0.0) is your call, not this plan's** —
run it after reviewing the 1.0.0 archive the dry run prints.

---

## Tests / validation

- A mechanical rename adds **no new behaviour**, so the 86 existing tests are the correctness
  oracle and must stay green throughout (this *is* the verification for Tasks 2–4). The only
  new test is the Task 1 guard — genuinely TDD-driven: **fail before**, **pass after**, and it
  ratchets the word out of `lib/` for good.
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

- **Major-version release.** 1.0.0 is a deliberate API freeze; the cost is that any future
  rename is *again* a major. If you would rather stay in 0.x, `0.3.0` is the semver-correct
  pre-1.0 "breaking" bump — say so and Task 5 changes one line. Default per your instruction:
  **1.0.0**.
- **Wire format.** Task 3 changes the JSON key `device_type_id` → `sku_id` (other keys
  untouched). Safe **only** if `library_scanner` has no persisted records yet. If it does:
  hand-edit `instance.dart`'s `toJson`/`fromJson` to keep reading/writing the old key, and
  split the rename into "Dart names now, wire keys later".
- **`Sku` churn.** Renaming `DeviceType` touches 256 occurrences and cascades into
  `SkuComponent` (`parentDeviceTypeId` → `parentSkuId`). Keeping `DeviceType` is ~⅓ the diff
  but leaves the model word odd.
- **Two stutters the machine cannot fix** (`FetchSkuComponentsBySku`,
  `InstanceReportProperty`) are called out in Task 3 — skip them and you get awkward names,
  not broken code.
- **`test/` names are not published** (`.pubignore` drops the tree), so their rename is
  cosmetic but required to keep the suite compiling.
- **`Instance` is a common English word** — it appears in Flutter/dep *prose* (doc comments)
  but declares no top-level symbol anywhere a consumer imports, so there is no ambiguity
  error; if a future dependency ever exports a top-level `Instance`, the fix is a one-line
  `hide Instance`/prefix at the call site, no change in this package.
- **Open question:** Has `library_scanner` already persisted `sku_catalog` records? If yes, keep
  the `device_type_id` wire key (see Wire format).

## Appendix — consumer side (`library_scanner`), out of scope for this plan

Once 1.0.0 is pushed, `library_scanner` consumes it as:
- `DeviceType` → `Sku` becomes "title/edition"; `Device` → `Instance` becomes "the physical
  copy". Both stay `Locate`-aware, and `Instance.attributeValues` is filled from the resolved
  traits — the behaviour you liked is unchanged, only the noun.
- Want a product word *inside* `library_scanner`? Alias locally: `typedef Copy = Instance;`
  — never in the package (the boundary test forbids product words in `lib/`).
- Its backend implements `ISkuRepository`, `IInstanceRepository`, `ILocateRepository`, … over
  whatever store it has; the in-memory doubles in this repo's `test/support/` are the
  reference shape (not published).
