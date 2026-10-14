import 'entities/instance.dart';

/// Case-insensitive name clash at the same locate.
bool namesClash({required String a, required String b}) =>
    a.trim().toLowerCase() == b.trim().toLowerCase();

/// A unique "copy" name: "X copy", "X copy 2", ...
///
/// The one naming rule the catalog owns. A copy has to be called something, and
/// this is the name that satisfies the per-locate rule without the caller having
/// to invent one. Everything else about naming — templates, sequence tokens, how
/// a model number is shortened — belongs to the screen that offers it, not to the
/// model.
String uniqueCopyName({
  required String baseName,
  required String? locateId,
  required List<Instance> all,
}) {
  final atLocate = all.where((d) => d.locateId == locateId).toList();
  var candidate = '$baseName copy';
  var n = 2;
  while (atLocate.any((d) => namesClash(a: d.name, b: candidate))) {
    candidate = '$baseName copy $n';
    n += 1;
  }
  return candidate;
}
