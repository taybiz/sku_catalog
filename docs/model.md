# Domain model

## The model in one screen

| Concept | What it is |
|---|---|
| `Sku` | A **SKU** (product model) made by a manufacturer (`QO120`, `ESP32-S3 IO node rev B`). |
| `Trait` | A **classification attached to a SKU, a place or a manufacturer** — never to an instance: an article holds the *values* of the traits in scope for it. Traits form a tree: `Switch → Breaker` inherits `Switch`'s attributes and may override them. |
| `TraitAttributeDefinition` | A **typed field** a trait contributes: `rated_amps` (number, `A`, required), `gfci` (boolean), `load_type` (enum). |
| `SkuComponent` | An **assembly edge**: this SKU contains *n* of that SKU. |
| `SkuAssociation` | A **labeled relationship edge**: this SKU acts *as `kind`* on that SKU (an author `edited` an anthology). A fact of the models. |
| `InstanceAssociation` | A **labeled relationship edge between two articles**: this article acts *as `kind`* on that one (a copy `bound_with` its neighbour). A fact of particular articles — an edge connects peers. |
| `Manufacturer` | Who makes it, with its own traits (`is_preferred`) and attributes. |
| `Locate` | A **place**, as a tree — a hole, a mount, a rack slot, a room. Places outlive their occupants. |
| `Instance` | An **instance of a SKU**, sitting at exactly one `Locate`, holding the attribute values of the traits in scope for it. |
| `ImageRecord` | A photo attached to a SKU, an instance or a place — **the only home for an entity's images**; none of the three carries a list of its own. |

Two ideas do most of the work:

- **Traits + typed attributes** instead of a wide table per kind of thing. A new
  kind of part is data, not a schema change. Inheritance means the shared
  vocabulary (`Switch`) is written once and the specific case (`Breaker`) adds
  only what differs.
- **SKUs assemble from SKUs.** A panel is a SKU containing breakers, a machine
  is a SKU containing boards and mechanisms. The assembly is a graph with a
  quantity per edge, and a cycle guard that refuses to close a loop.
- **Edges come in two kinds.** `SkuComponent` is *composition* — "this is made
  of N of that", folded into a bill of materials with a cycle guard.
  `SkuAssociation` is *relationship* — "this acts as `kind` on that", a labeled,
  directed edge with no quantity and no fold, for facts that are not parts of a
  build (an author `edited` an anthology). `InstanceAssociation` is the same
  relation one level down, between two *articles*, for facts the models cannot
  state at all: this copy is `bound_with` that copy, this copy was `replaced_by`
  that one. Both edges are real and neither store sees the other's rows, and both
  connect peers — an edge names two things of the same level, never a SKU on one
  end and an article on the other.


## Serial numbers, and the one trait the package names

A serial number is not a field on `Instance`. It is an attribute value, because the
two halves are different facts: the **model** is serializable — a trait on the SKU,
which is why the trait is `sku`-scoped — and the **article** carries one particular
number. The package names that pair, because the rule that comes with it is a
catalog invariant rather than your spelling of it: `SerializableTrait.define` mints
that pair — the trait `Serializable`, scoped to SKUs, and its one attribute
`serial_number`, a string marked `isUnique`.

`isUnique` is a flag **any** trait's attribute can carry — `serializable` is not
special. It means *at most one **holder** in the catalog may hold a value for this
attribute*, and three kinds of record are holders: an **article** (an `Instance`),
the **place** it sits at (a `Locate`) and the **maker** of its model (a
`Manufacturer`). All four records — a SKU too — carry an `attributeValues` map;
being a holder is about the rule, not about the field. A unique value is unique
across all three at once, so a serial number one article holds cannot be minted by
a place or a maker either.

The rule is one object, built where your stores are. `AssertUniqueAttributeValues`
takes the three holder repositories and two schema resolvers — an article's schema is
its own traits plus its model's, walked up their parent chains, while a place's or a
maker's is the traits it carries itself — and every write path that can claim a value
takes it: `CreateInstance` and `UpdateInstance`, and the same rule guards
`CreateLocate`, `UpdateLocate`, `CreateManufacturer` and `UpdateManufacturer`. The
first article to take `SN-0001` gets it; anything else claiming it — a second article,
a place, a maker — is refused with a `DuplicateAttributeValueFailure` instead of being
stored, and the reference backend hands you all of those paths already wired.

A **model** is not a holder: a value on a SKU describes the class, not one article,
so nothing on a SKU is unique in this sense — a model *declares* that serial numbers
exist (that is the trait), and holding one is an article's, a place's or a maker's
act. A place or a maker that carries the trait is checked like an article.

**`Trait.scope` is not consulted here.** A trait records which carrier it is for
(`sku`, `locate`, `manufacturer`) as data; the package stores that and does not gate
on it, so this rule does not either. What makes a clash a clash is a **value under a
key**, not a declared carrier: a place holding a stray value under a key whose
definition is not in its own scope still blocks that value — the number is taken,
and refusing the write is the answer that needs no interpretation.

Values compare the way this package's other identity rules compare them: strings
trimmed and case-insensitively, numbers by value, different types as different
values, and a value nobody set never clashes with anything. A copy is a new
article, so `DuplicateInstance` carries the classification and the non-unique
values over and starts with the unique ones unset — the same shape as the locate a
copy does not inherit. Deleting the holder frees its value.

Nothing new to implement in a backend: the check reads through `fetchAll()` on the
three contracts, so the contracts you already implement are enough, and the rule
stays a use case rather than a storage feature.


## Identity

**An id is an opaque string.** The catalog stores, returns and compares ids and
does nothing else with them: nothing in `lib/` parses an id, sorts on it, or does
arithmetic on it. So the shape is yours — a UUID, an int-backed string, a
prefixed `DEV-0007`.

You already choose the id wherever you hand a whole entity to a create use case
(`CreateSku`, `CreateInstance`, `CreateSkuComponent`, …). For the four operations
that mint ids *internally* — `DuplicateSku`, `DuplicateInstance`,
`AddSkuComponent`, `UpdateSkuComponent` — pass an optional `IdGenerator`
(a `String Function()`) to the constructor; the default is a random UUID v4. The
one rule the catalog asks of a generator is **stability**: whatever an adapter
stores must read back unchanged.

**A model number is the maker's production number, unique against the maker.**
`AssertUniqueModelNumber` keeps that rule on the SKU write paths, so a second model
from the same `manufacturerId` cannot take a number another model already holds, and
an edit that keeps its own number is not a clash with itself. The comparison is
**exact** — a production number is an identifier, so `QO120` and `qo120` are two
different numbers, unlike an instance name, which the per-locate rule compares
case-insensitively because it is prose a person reads. `DuplicateSku` mints the next
free "(copy)" number rather than being refused. What a maker *calls* a thing, when
that differs from its production number, is a different fact: optional, with no rule
to keep, so it is a trait you declare rather than a field here.

Two deliberate consequences worth knowing:

- **Domain vocabulary stays out.** What a short code on an article means, and
  which trait holds it, are *your* words and *your* screen. The package names
  exactly one pair, `serializable` and its `serial_number`, because `isUnique`
  turns it into a catalog-wide rule rather than a convention (see above).
- **The catalog cascades only what it owns.** `DeleteInstance` removes the article,
  its images and the `InstanceAssociation` edges that name it — everything the
  catalog itself stores *about* that article. If something else references instances
  — a wiring graph, a harness, a bill of materials — that is yours to cascade, and
  the use case documents it.
- **A model that exists only for its articles goes with the last one.**
  `DeleteInstanceAndUnusedSku` is for a book's *edition*: nobody catalogues it, its
  copies only instantiate it, and two copies share it — so the model is removed when
  nothing else names it, not when the first copy leaves. There is no flag for that:
  choosing the operation is the assertion.


## What is deliberately not here

The package is the instance/SKU heart plus the places and assemblies around it,
and nothing else. Left out on purpose, because they belong to a consumer's
domain: electrical concepts (panels, breakers, slot layouts, ampacity),
topology graphs, reports, import/export bundles, and any naming convention. If
you need one of those, compose it around this package rather than inside it.

The one backend in the repository is the **reference** one
(`lib/in_memory.dart`, repo-only): it exists to be read and copied, and it is not
a supported storage layer — no durability, no indexes, no concurrency.

