/// Returns a `Map<String, dynamic>` view of [v], or `{}` if [v] is not a map.
///
/// Defensive parse of legacy records that may be null, primitives, or lists.
Map<String, dynamic> asStringMap(Object? v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return <String, dynamic>{};
}

/// Converts a wire list of strings into a typed [List<String>].
///
/// Returns an empty list when [v] is missing or malformed.
List<String> stringListFromWire(Object? v) =>
    (v as List?)?.cast<String>() ?? <String>[];
