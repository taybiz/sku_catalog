# Example

A runnable tour of what a consumer of `sku_catalog` writes: implement the repository
contracts over your own storage, wire the rules, run the operations.

```
dart run example/sku_catalog_example.dart
```

The stores in that file keep their rows in `Map`s, because it has to be one runnable
file. A real one is a database, a file, or whatever you already have — the shape it
has to satisfy is the contract. The reference implementation to read next is
`lib/src/adapters/in_memory/` in the repository: the same contracts, an in-memory
store, and a snapshot-based transaction.
