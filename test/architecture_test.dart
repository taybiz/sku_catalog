// Architecture & boundary rules for sku_catalog, enforced with dart_arch_test.
// Doctrine: dart-flutter-bible docs/02-toolchain.md §2.9 ("Package-boundary
// rules: dart_arch_test, not melos, and not import_rules"). The gate is a plain
// test() over the RESOLVED import graph, so `dart test` enforces it with
// everything else — no config file, no separate gate to remember.
//
// Assertions are written over `package:` URIs directly. dart_arch_test's glob
// DSL strips the `package:<name>/` prefix before matching, so whole-area
// patterns match nothing and a planted violation sails through (§2.9) — this
// file deliberately uses Collector + plain prefix checks instead.
//
// The rules, each a decision written down:
//  - Dependencies point inward. `domain` is the inner area: it sees only itself
//    and its sanctioned value-type packages. `usecases` may use `domain`, never
//    the reverse.
//  - No internal library reaches through the public entry point (a cycle via the
//    front door).
//  - `lib/src/` is private: the barrel (`sku_catalog.dart`) is the only public
//    door, so nothing outside `lib/src/` may import a `.../src/...` URI.
//  - The published library reaches no `file:` URI (where the test doubles live)
//    and no product package.
//  - No import cycles, workspace-wide.
//
// This is a rule test, not a behavior test: GWT naming and shouldly apply to
// behavior suites, not architecture assertions (docs/06-testing.md).

import 'dart:io';

import 'package:dart_arch_test/dart_arch_test.dart';
import 'package:test/test.dart';

/// The public entry point — the one door into the package (§2.6).
const _barrel = 'package:sku_catalog/sku_catalog.dart';

/// The only two areas of `lib/src/`, each with the packages its files may
/// depend on. An import that crosses an area, or reaches a package that is not
/// listed, is a violation. Extending the graph means extending this table.
const _allowedEdges = <String, Set<String>>{
  // The model: itself, plus the sanctioned value-type packages (STACK).
  'domain': <String>{
    'package:sku_catalog/src/domain/',
    'package:fpdart/',
    'package:equatable/',
  },
  // The operations: may use the model, plus the same value-type packages.
  'usecases': <String>{
    'package:sku_catalog/src/usecases/',
    'package:sku_catalog/src/domain/',
    'package:fpdart/',
    'package:equatable/',
  },
};

/// The package root — CWD under `dart test`, absolutized.
///
/// Never `Platform.script`: under some runners it points at the kernel snapshot
/// in a scratch dir, the graph comes back empty, and every rule passes
/// vacuously (verified; §2.9).
String _packageRoot() => Directory.current.absolute.path;

void main() {
  late DependencyGraph graph;

  setUpAll(() async {
    graph = await Collector.buildGraph(_packageRoot(), force: true);
  });

  group('Given the architecture of sku_catalog', () {
    test(
      'When the graph is built, Then it resolved real libraries (not empty)',
      () {
        // Guards every rule below against passing vacuously on an empty graph.
        expect(graph, isNotEmpty);
        expect(Collector.allLibraries(graph), contains(_barrel));
        expect(
          Collector.allLibraries(graph),
          contains('package:sku_catalog/src/domain/domain.dart'),
        );
      },
    );

    for (final MapEntry(key: area, value: allowed) in _allowedEdges.entries) {
      test('Then $area depends only on the packages it is allowed', () {
        final violations = <String>[];
        for (final library in Collector.allLibraries(graph)) {
          if (!library.startsWith('package:sku_catalog/src/$area/')) continue;
          for (final dep in Collector.dependenciesOf(graph, library)) {
            if (dep.startsWith('dart:')) continue; // SDK is out of the graph
            if (!allowed.any(dep.startsWith)) {
              violations.add('$library -> $dep');
            }
          }
        }
        if (violations.isNotEmpty) {
          fail('BOUNDARY VIOLATIONS ($area):\n${violations.join('\n')}');
        }
      });
    }

    test('Then no internal library reaches through the public entry point', () {
      final violations = <String>[];
      for (final library in Collector.allLibraries(graph)) {
        if (!library.startsWith('package:sku_catalog/src/')) continue;
        if (Collector.dependenciesOf(graph, library).contains(_barrel)) {
          violations.add('$library -> $_barrel');
        }
      }
      if (violations.isNotEmpty) {
        fail('FRONT-DOOR CYCLES:\n${violations.join('\n')}');
      }
    });

    test('Then lib/src is private: only lib/src (and the barrel) touch it', () {
      final violations = <String>[];
      for (final library in Collector.allLibraries(graph)) {
        for (final dep in Collector.dependenciesOf(graph, library)) {
          if (!dep.startsWith('package:sku_catalog/src/')) continue;
          final callerInSrc = library.startsWith('package:sku_catalog/src/');
          if (!callerInSrc && library != _barrel) {
            violations.add('$library -> $dep');
          }
        }
      }
      if (violations.isNotEmpty) {
        fail('PRIVATE-IMPORT VIOLATIONS:\n${violations.join('\n')}');
      }
    });

    test('Then the published library reaches no file: URI (test doubles)', () {
      final violations = <String>[];
      for (final library in Collector.allLibraries(graph)) {
        if (!library.startsWith('package:sku_catalog/')) continue;
        for (final dep in Collector.dependenciesOf(graph, library)) {
          if (dep.startsWith('file:')) violations.add('$library -> $dep');
        }
      }
      if (violations.isNotEmpty) {
        fail('DOUBLE-DEPENDENCY VIOLATIONS:\n${violations.join('\n')}');
      }
    });

    test('Then none of them depends on a product package', () {
      const products = <String>['package:circuit_planner/', 'package:pinball'];
      final violations = <String>[];
      for (final library in Collector.allLibraries(graph)) {
        if (!library.startsWith('package:sku_catalog/')) continue;
        for (final dep in Collector.dependenciesOf(graph, library)) {
          if (products.any(dep.startsWith)) violations.add('$library -> $dep');
        }
      }
      if (violations.isNotEmpty) {
        fail('PRODUCT-LEAK VIOLATIONS:\n${violations.join('\n')}');
      }
    });

    test('Then there are no import cycles, workspace-wide', () {
      shouldBeFreeOfCycles(allFiles(), graph);
    });
  });
}
