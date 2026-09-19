import 'dart:io';

import 'package:shouldly/shouldly.dart';
import 'package:test/test.dart';

/// The rules that keep this package reusable, and its layers one-way.
///
/// A shared package is only shared if it cannot see its consumers. If a product
/// name or a product concept leaks into `lib/`, the boundary has moved without
/// anyone deciding it should. This test fails the build instead of leaving it
/// to review.
///
/// It also carries the two rules that package separation used to enforce for
/// free, and the compiler can no longer:
///
/// - the dependency graph between areas of `lib/src/` is one-way (operations may
///   use the model; the model may not use the operations), written down in one
///   table below;
/// - `lib/` never reaches for the test doubles, so the published library cannot
///   start depending on the in-memory backend.
void main() {
  group('Given the shared catalog boundary', () {
    group('When every file under lib/ is read', () {
      test('Then none of them imports a product package', () {
        final offenders = <String>[];
        for (final entity in Directory('lib').listSync(recursive: true)) {
          if (entity is! File || !entity.path.endsWith('.dart')) continue;
          for (final line in entity.readAsLinesSync()) {
            final t = line.trim();
            if (!t.startsWith('import ') && !t.startsWith('export ')) continue;
            if (t.contains('circuit_planner') ||
                t.contains('package:pinball')) {
              offenders.add('${entity.path}: $t');
            }
          }
        }

        offenders.should.beEmpty();
      });

      test('Then none of them reaches for the test doubles', () {
        final offenders = <String>[];
        for (final entity in Directory('lib').listSync(recursive: true)) {
          if (entity is! File || !entity.path.endsWith('.dart')) continue;
          for (final line in entity.readAsLinesSync()) {
            final t = line.trim();
            if (!t.startsWith('import ') && !t.startsWith('export ')) continue;
            if (t.contains('test/support') || t.contains('support/memory')) {
              offenders.add('${entity.path}: $t');
            }
          }
        }

        offenders.should.beEmpty();
      });

      test('Then the areas only depend in the allowed direction', () {
        // The one place the dependency graph between areas of lib/src is written
        // down. An import that crosses an area has to be listed here, so the
        // shape of the code is a decision rather than an accident. This is what
        // separating the model and the operations into their own packages used
        // to enforce for free; one published package means something has to say
        // it out loud.
        const allowedEdges = <String, Set<String>>{
          'domain': <String>{},
          'usecases': <String>{'domain'},
        };

        final offenders = <String>[];
        for (final area in allowedEdges.keys) {
          final directory = Directory('lib/src/$area');
          if (!directory.existsSync()) {
            offenders.add('lib/src/$area: named in the edge table but missing');
            continue;
          }
          for (final entity in directory.listSync(recursive: true)) {
            if (entity is! File || !entity.path.endsWith('.dart')) continue;
            for (final line in entity.readAsLinesSync()) {
              final t = line.trim();
              if (!t.startsWith('import ') && !t.startsWith('export ')) {
                continue;
              }

              if (t.contains('package:sku_catalog/')) {
                // An internal file reaching through the public entry point is a
                // cycle through the front door.
                offenders.add(
                  '${entity.path}: uses the public entry point: $t',
                );
                continue;
              }

              final relative = RegExp("['\"](\\.[^'\"]*)['\"]").firstMatch(t);
              if (relative == null) continue;
              final reached = _areaOf(
                _resolve(entity.path, relative.group(1)!),
              );
              if (reached == null || reached == area) continue;
              if (!allowedEdges[area]!.contains(reached)) {
                offenders.add(
                  '${entity.path}: $area -> $reached is not an allowed edge',
                );
              }
            }
          }
        }

        offenders.should.beEmpty();
      });

      test('Then none of them names a product', () {
        final offenders = <String>[];
        for (final entity in Directory('lib').listSync(recursive: true)) {
          if (entity is! File || !entity.path.endsWith('.dart')) continue;
          final text = entity.readAsStringSync().toLowerCase();
          for (final word in const ['circuit_planner', 'pinball']) {
            if (text.contains(word)) offenders.add('${entity.path}: $word');
          }
        }

        offenders.should.beEmpty();
      });
    });
  });
}

/// The area of `lib/src/` a path sits in, or null when it is not in one.
String? _areaOf(String path) =>
    RegExp(r'^lib/src/([^/]+)/').firstMatch(path)?.group(1);

/// Resolves a relative import against the file that wrote it. Package imports
/// are not resolved here: the only one that matters, the public entry point, is
/// rejected before this is called.
String _resolve(String fromFile, String relative) {
  final parts = fromFile.split('/')..removeLast();
  for (final segment in relative.split('/')) {
    if (segment.isEmpty || segment == '.') continue;
    if (segment == '..') {
      if (parts.isNotEmpty) {
        parts.removeLast();
      }
    } else {
      parts.add(segment);
    }
  }
  return parts.join('/');
}
