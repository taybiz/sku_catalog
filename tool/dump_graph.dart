import 'dart:io';

import 'package:dart_arch_test/dart_arch_test.dart';
import 'package:path/path.dart' as p;

Future<void> main() async {
  final root = p.normalize(p.absolute(Directory.current.path));
  stdout.writeln('ROOT: $root');
  final graph = await Collector.buildGraph(root, force: true);
  final all = Collector.allLibraries(graph)..toList();
  final sorted = all.toList()..sort();

  stdout.writeln('\n# distinct URI schemes / prefixes');
  final prefixes = <String, int>{};
  for (final u in sorted) {
    final parts = u.split('/');
    final key = parts.length >= 3 ? parts.take(3).join('/') : u;
    prefixes[key] = (prefixes[key] ?? 0) + 1;
  }
  prefixes.forEach((k, v) => stdout.writeln('  $v  $k'));

  stdout.writeln('\n# sample lib uris');
  sorted.where((u) => u.startsWith('package:')).take(8).forEach(stdout.writeln);

  stdout.writeln('\n# non-package uris (test files?)');
  sorted.where((u) => !u.startsWith('package:')).take(30).forEach(stdout.writeln);

  stdout.writeln('\n# total libraries: ${sorted.length}');

  stdout.writeln('\n# domain libs and their deps (non-dart)');
  for (final u in sorted.where((u) => u.contains('/src/domain/'))) {
    final deps = Collector.dependenciesOf(graph, u)
        .where((d) => !d.startsWith('dart:'))
        .toList()
      ..sort();
    if (deps.isNotEmpty) stdout.writeln('  $u\n    -> ${deps.join("\n    -> ")}');
  }

  stdout.writeln('\n# usecases libs and their non-domainself deps');
  for (final u in sorted.where((u) => u.contains('/src/usecases/'))) {
    final deps = Collector.dependenciesOf(graph, u)
        .where((d) =>
            !d.startsWith('dart:') &&
            !d.startsWith('package:sku_catalog/src/usecases/'))
        .toList()
      ..sort();
    stdout.writeln('  $u -> $deps');
  }

  stdout.writeln('\n# cycles: ${Collector.cycles(graph).length}');
}
