/// A store whose rows a transaction can snapshot and put back.
abstract interface class InMemoryRowSource {
  /// The rows, keyed by record id.
  Map<String, Map<String, dynamic>> get rows;

  /// A copy of every row — what a transaction keeps to undo itself.
  Map<String, Map<String, dynamic>> snapshot();

  /// Replaces every row — how a rollback restores a snapshot.
  void replaceAll(Map<String, Map<String, dynamic>> rows);
}

/// A map-backed table of records, keyed by id and stored as their JSON row.
///
/// This is the whole storage story a backend needs: one map from id to the row
/// `toJson()` produced, decoded with `fromJson()` on the way out. Keeping the row
/// as the wire form (rather than the entity) is the point — an adapter built this
/// way stores what the model round-trips, and a record written before a field
/// existed still parses.
class InMemoryTable<T> implements InMemoryRowSource {
  /// Creates an empty [InMemoryTable].
  InMemoryTable({
    required this.decode,
    required this.encode,
    required this.idOf,
  });

  /// Reads a record back from its row.
  final T Function(Map<String, dynamic> json) decode;

  /// Writes a record to its row.
  final Map<String, dynamic> Function(T entity) encode;

  /// The id a record is stored under.
  final String Function(T entity) idOf;

  final Map<String, Map<String, dynamic>> _rows = {};

  @override
  Map<String, Map<String, dynamic>> get rows => _rows;

  @override
  void replaceAll(Map<String, Map<String, dynamic>> rows) {
    _rows
      ..clear()
      ..addAll(rows);
  }

  /// Every record, in insertion order.
  List<T> all() => _rows.values.map(decode).toList();

  /// The record under [id], or null when the table holds none.
  T? find(String id) {
    final row = _rows[id];
    return row == null ? null : decode(row);
  }

  /// Whether the table holds [id].
  bool has(String id) => _rows.containsKey(id);

  /// Stores [entity] under its own id, replacing whatever row was there.
  void put(T entity) => _rows[idOf(entity)] = encode(entity);

  /// Removes [id]; true when a row was there to remove.
  bool remove(String id) => _rows.remove(id) != null;

  /// A copy of every row — what a transaction keeps to undo itself.
  @override
  Map<String, Map<String, dynamic>> snapshot() => {
    for (final entry in _rows.entries)
      entry.key: Map<String, dynamic>.from(entry.value),
  };
}

/// A repository backed by one [InMemoryTable], exposing that table's rows — so a
/// transaction snapshots the repository itself instead of reaching into it.
///
/// Every store in this backend mixes this in; it is why `InMemoryUnitOfWork` takes
/// the repositories, not their tables.
mixin InMemoryRowSourceBy<T> implements InMemoryRowSource {
  /// The rows behind this repository — what a transaction snapshots.
  InMemoryTable<T> get table;

  @override
  Map<String, Map<String, dynamic>> get rows => table.rows;

  @override
  Map<String, Map<String, dynamic>> snapshot() => table.snapshot();

  @override
  void replaceAll(Map<String, Map<String, dynamic>> rows) =>
      table.replaceAll(rows);
}
