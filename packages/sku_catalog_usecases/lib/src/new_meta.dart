import 'dart:math';

import 'package:sku_catalog_domain/sku_catalog_domain.dart';

/// Builds a fresh [Meta] with a random id and the current UTC timestamp.
///
/// Use case internals that construct entities (naming flows, duplication,
/// topology rewrites) share this so every write path gets consistent
/// created/updated stamps without depending on the UI ring.
Meta newMeta([String notes = '']) {
  final now = DateTime.now().toUtc().toIso8601String();
  return Meta(id: _uuid4(), notes: notes, createdAt: now, updatedAt: now);
}

String _uuid4() {
  final rng = Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int start, int end) => bytes
      .sublist(start, end)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}
