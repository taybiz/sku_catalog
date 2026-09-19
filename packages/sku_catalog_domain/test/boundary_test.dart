import 'dart:io';

import 'package:shouldly/shouldly.dart';
import 'package:test/test.dart';

/// The rule that keeps this package reusable.
///
/// A shared package is only shared if it cannot see its consumers. If a product
/// name or a product concept leaks into `lib/`, the boundary has moved without
/// anyone deciding it should. This test fails the build instead of leaving it
/// to review.
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
