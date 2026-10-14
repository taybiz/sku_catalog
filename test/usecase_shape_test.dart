import 'dart:io';

import 'package:shouldly/shouldly.dart';
import 'package:test/test.dart';

/// The use-case ring's shape rule, checked rather than trusted: **one use case per
/// file, and a use case answers through a single public `call()`**.
///
/// A second public method is two operations wearing one name; a public top-level
/// function is a use case that never got its class; a file that is neither is a
/// helper that belongs to the domain. The import graph cannot see any of it, so
/// this is a text scan — the same deliberate mechanism as `boundary_test.dart`,
/// and it fails the build rather than waiting for review.
///
/// Not scanned: `usecases.dart` itself, which is the area's barrel.
void main() {
  final sources = Directory('lib/src/usecases')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => !file.path.endsWith('usecases.dart'))
      .toList();

  /// The public class a file declares, or null when it declares none.
  String? publicClass(String source) => RegExp(
    r'^class (?!_)(\w+)',
    multiLine: true,
  ).firstMatch(source)?.group(1);

  /// The body of [name]'s class declaration: up to the first column-0 `}` after
  /// it. Dart classes do not nest, so that brace closes it.
  String bodyOf(String source, String name) {
    final start = source.indexOf('class $name');
    final end = source.indexOf(RegExp(r'^\}', multiLine: true), start);
    return end == -1 ? source.substring(start) : source.substring(start, end);
  }

  group('Given the use-case ring', () {
    test('When its files are listed, Then there are files to check', () {
      // Guards the rules below against passing vacuously.
      sources.should.not.beEmpty();
    });

    test('Then every file holds exactly one public class', () {
      final offenders = <String>[];
      for (final file in sources) {
        final declared = RegExp(
          r'^class (?!_)(\w+)',
          multiLine: true,
        ).allMatches(file.readAsStringSync()).map((m) => m.group(1)!).toList();
        if (declared.length != 1) {
          offenders.add(
            '${file.path}: ${declared.isEmpty ? 'no public class' : declared.join(', ')}',
          );
        }
      }

      offenders.should.beEmpty();
    });

    test('Then each answers only through call()', () {
      final offenders = <String>[];
      for (final file in sources) {
        final source = file.readAsStringSync();
        final name = publicClass(source);
        if (name == null) continue;
        // The class's own body: from its declaration to the column-0 brace that
        // closes it. Dart classes do not nest, so the first one is the end — and
        // a private class after it (a fold, a value) is its own business.
        final body = bodyOf(source, name);
        final members =
            RegExp(r'^  [A-Za-z_][\w<>,?\s\[\]]*\s+(\w+)\(', multiLine: true)
                .allMatches(body)
                .map((m) => m.group(1)!)
                .where((member) => !member.startsWith('_') && member != name)
                .toSet();
        if (members.length != 1 || !members.contains('call')) {
          offenders.add(
            '${file.path}: ${members.isEmpty ? 'no call()' : members.join(', ')}',
          );
        }
      }

      offenders.should.beEmpty();
    });

    test('Then none of them is a bare helper', () {
      const allowed = <String>[
        'class ',
        'import ',
        'export ',
        'part ',
        'library',
      ];
      final offenders = <String>[];
      for (final file in sources) {
        for (final line in file.readAsLinesSync()) {
          final trimmed = line.trimRight();
          if (trimmed.isEmpty || trimmed.startsWith('}')) continue;
          if (trimmed.startsWith('///') || trimmed.startsWith('//')) continue;
          if (line != trimmed || line.startsWith(' ')) continue; // indented
          if (allowed.any(trimmed.startsWith)) continue;
          offenders.add('${file.path}: $trimmed');
        }
      }

      offenders.should.beEmpty();
    });
  });
}
