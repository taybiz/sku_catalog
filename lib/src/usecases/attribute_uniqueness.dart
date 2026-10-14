import '../domain/domain.dart';

/// Whether two values for a unique attribute are the same claim.
///
/// The comparison normalizes the way this package's other identity rules do, so
/// a value typed by hand is not two values:
///
/// - **strings** are compared trimmed and case-insensitively, so `'SN-1'`,
///   `'sn-1'` and `' SN-1 '` are one serial number (`namesClash` makes the same
///   call for instance names);
/// - **numbers** are compared by value, so `20` and `20.0` are one number;
/// - **booleans** are compared as themselves;
/// - **different types are different values**: `20` and `'20'` do not clash.
///   Which type a value is comes from the definition's [DataType]; a string
///   where a number belongs is a data error, and quietly treating the two as one
///   value would hide it;
/// - **null never clashes**: an attribute nobody set is not a value, so two
///   articles that leave an attribute unset cannot collide over it.
bool attributeValuesClash({required Object? a, required Object? b}) {
  final left = _comparable(value: a);
  final right = _comparable(value: b);
  if (left == null || right == null) return false;
  return left == right;
}

/// The keys of [definitions] that are marked unique, as a set.
Set<String> uniqueAttributeKeys({
  required List<TraitAttributeDefinition> definitions,
}) => {
  for (final definition in definitions)
    if (definition.isUnique) definition.key,
};

/// [values] without the entries for [keys].
///
/// Used where a value must not be carried along with the entity: a copy is a new
/// article, so it inherits the classification but not a unique value — the serial
/// number on the original identifies the original.
Map<String, dynamic> withoutKeys({
  required Map<String, dynamic> values,
  required Set<String> keys,
}) => {
  for (final entry in values.entries)
    if (!keys.contains(entry.key)) entry.key: entry.value,
};

/// The comparable form of [value], or null when it is not a claim at all.
String? _comparable({required Object? value}) {
  if (value == null) return null;
  if (value is String) return 'string:${value.trim().toLowerCase()}';
  if (value is num) return 'number:${value.toDouble()}';
  if (value is bool) return 'boolean:$value';
  return '${value.runtimeType}:$value';
}
