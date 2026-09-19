import 'package:sku_catalog_domain/sku_catalog_domain.dart';

/// Default device name template (settings fallback).
const defaultNameTemplate = '{trait}_{locate}_{sku}_{n}';

/// Collapses doubled-up separators and trims leading/trailing ones — cleans
/// up the gaps left behind when an optional naming token is empty.
///
/// Uses `replaceAllMapped` so the group backreference substitutes correctly
/// (Dart's `replaceAll` treats `$1` as a literal).
String collapseSeparators(String text) {
  final collapsed = text.replaceAllMapped(
    RegExp(r'([_\-\\s#])\1+'),
    (m) => m.group(1)!,
  );
  return collapsed.replaceAll(RegExp(r'^[_\-\\s#]+|[_\-\\s#]+$'), '');
}

/// Fills every fixed token ({base}, {trait}, {locate}, {sku}, ...) in the
/// template, leaving {n} untouched for the caller to resolve.
String fillFixedTokens(String template, Map<String, String> tokens) =>
    collapseSeparators(
      template.replaceAllMapped(
        RegExp(r'\{(\w+)\}'),
        (m) => m.group(1) == 'n' ? m.group(0)! : (tokens[m.group(1)] ?? ''),
      ),
    );

/// Formats a name for sequence [n].
String formatName(String template, Map<String, String> tokens, int n) =>
    fillFixedTokens(template, tokens).replaceAll('{n}', '$n');

/// Error message when [template] cannot produce unique auto-names, else null.
///
/// Auto-names are uniquified per locate by the {n} sequence token; a template
/// without it would stamp every device in the locate with the same name.
String? validateNameTemplate(String template) => template.trim().contains('{n}')
    ? null
    : 'Naming template must include the "{n}" sequence token';

/// Highest N among existing names matching the template (with every fixed
/// token resolved and {n} captured) at this locate; the next unit starts at
/// that + 1.
int nextSequenceStart(
  String template,
  Map<String, String> tokens,
  List<String> existingNames,
) {
  final pattern = RegExp.escape(
    fillFixedTokens(template, tokens),
  ).replaceAll(r'\{n\}', r'(\d+)');
  final re = RegExp('^$pattern\$', caseSensitive: false);
  var max = 0;
  for (final name in existingNames) {
    final m = re.firstMatch(name.trim());
    if (m != null) {
      final n = int.tryParse(m.group(1) ?? '');
      if (n != null && n > max) max = n;
    }
  }
  return max + 1;
}

/// Case-insensitive name clash at the same locate.
bool namesClash(String a, String b) =>
    a.trim().toLowerCase() == b.trim().toLowerCase();

/// A unique "copy" name: "X copy", "X copy 2", ...
String uniqueCopyName(String baseName, String? locateId, List<Device> all) {
  final atLocate = all.where((d) => d.locateId == locateId).toList();
  var candidate = '$baseName copy';
  var n = 2;
  while (atLocate.any((d) => namesClash(d.name, candidate))) {
    candidate = '$baseName copy $n';
    n += 1;
  }
  return candidate;
}

/// Lower-cases and slugifies a locate name for the {locate} naming token
/// (max [maxLen] chars, trailing hyphens trimmed).
String slugifyLocate(String name, [int maxLen = 14]) {
  var slug = name
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  if (slug.length > maxLen) {
    slug = slug.substring(0, maxLen).replaceAll(RegExp(r'-+$'), '');
  }
  return slug;
}

/// Compacts a model number into a short uppercase token for the {sku} naming
/// token (max [maxLen] chars; falls back to "SKU" when empty).
String abbreviateSku(String modelNumber, [int maxLen = 10]) {
  final trimmed = modelNumber.trim();
  final compact = trimmed.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '');
  if (compact.length <= maxLen) {
    return compact.toUpperCase().isEmpty ? 'SKU' : compact.toUpperCase();
  }
  final parts = RegExp(
    r'[A-Za-z]+|\d+',
  ).allMatches(trimmed).map((m) => m.group(0)!).toList();
  final short = parts
      .map(
        (part) =>
            RegExp(r'^[0-9]+$').hasMatch(part) ? part : part.substring(0, 1),
      )
      .join();
  return (short.isNotEmpty ? short : compact.substring(0, maxLen))
      .toUpperCase()
      .substring(
        0,
        short.isNotEmpty && short.length < maxLen ? short.length : maxLen,
      );
}

/// The uppercase code held in [attributeKey] on the trait named [traitName],
/// else  — e.g. a "coded" trait's "code" attribute, for short tags.
///
/// The names are parameters rather than constants on purpose: which trait
/// carries a short code, and which attribute holds it, is one product's
/// convention. This package carries no product vocabulary.
String resolveAttributeAbbreviation(
  List<String> traitIds,
  List<Trait> traits,
  Map<String, dynamic> attributeValues, {
  required String traitName,
  required String attributeKey,
}) {
  final named = traits
      .where((t) => t.name.toLowerCase() == traitName.toLowerCase())
      .toList();
  if (named.isNotEmpty && traitIds.contains(named.first.meta.id)) {
    final code = attributeValues[attributeKey];
    if (code is String) {
      final trimmed = code.trim().toUpperCase();
      if (trimmed.isNotEmpty) return trimmed;
    }
  }
  return '';
}

/// Whether the SKU [typeId] carries any of [traitNames], inherited or direct.
///
/// This is how a caller expresses its own structural conventions — "a Slottable
/// SKU lives inside another device, so it carries no locate of its own" — without
/// the catalog having to know the word.
bool isSlotBound(
  String typeId,
  List<DeviceType> deviceTypes,
  List<Trait> traits,
  Set<String> traitNames,
) {
  if (traitNames.isEmpty) return false;
  final names = traitNamesForType(typeId, deviceTypes, traits);
  return traitNames.any((n) => names.contains(n.toLowerCase()));
}

/// Every trait name reachable from [typeId]'s trait ids, walking parent
/// chains (lower-cased, deduped).
Set<String> traitNamesForType(
  String typeId,
  List<DeviceType> deviceTypes,
  List<Trait> traits,
) {
  final names = <String>{};
  final dts = deviceTypes.where((d) => d.meta.id == typeId).toList();
  if (dts.isEmpty) return names;
  final byId = {for (final t in traits) t.meta.id: t};
  for (final tid in dts.first.traitIds) {
    final guard = <String>{};
    Trait? cur = byId[tid];
    while (cur != null && !guard.contains(cur.meta.id)) {
      guard.add(cur.meta.id);
      names.add(cur.name.toLowerCase());
      cur = cur.parentTraitId != null ? byId[cur.parentTraitId] : null;
    }
  }
  return names;
}

/// Whether [device]'s SKU carries [traitName] (inherited or direct).
bool deviceHasTrait(
  Device device,
  List<DeviceType> deviceTypes,
  List<Trait> traits,
  String traitName,
) => traitNamesForType(
  device.deviceTypeId,
  deviceTypes,
  traits,
).contains(traitName.toLowerCase());
