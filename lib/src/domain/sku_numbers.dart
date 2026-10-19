import 'entities/sku.dart';

/// The next free "(copy)" model number for [baseNumber] at [manufacturerId].
///
/// The one naming rule the catalog owns for a model, and it exists because a copy
/// still has to be a model the maker's numbering does not already use:
/// "X (copy)", "X (copy 2)", … Everything else about a model number — how a maker
/// assigns one, how a screen shortens it for display — belongs to whoever assigns
/// it, not here.
///
/// The comparison is exact, the same comparison `AssertUniqueModelNumber` makes.
String uniqueCopyModelNumber({
  required String baseNumber,
  required String manufacturerId,
  required List<Sku> all,
}) {
  final taken = all
      .where((sku) => sku.manufacturerId == manufacturerId)
      .map((sku) => sku.modelNumber)
      .toSet();
  var candidate = '$baseNumber (copy)';
  var n = 2;
  while (taken.contains(candidate)) {
    candidate = '$baseNumber (copy $n)';
    n += 1;
  }
  return candidate;
}
