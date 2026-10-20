import 'dart:convert';
import 'dart:io';

import 'package:shouldly/shouldly.dart';
import 'package:test/test.dart';

/// `example/` is a **published deliverable**: pub.dev builds the package's Example
/// tab from it, so what is in it has to run on published code alone. That is the
/// reason it carries its own little store instead of importing the repo-only
/// reference backend, and the reason this test runs it — an example nothing
/// executes is the example that stops compiling.
///
/// It is run as a process rather than imported, because that is how a consumer
/// meets it (`dart run example/sku_catalog_example.dart`), and because importing it
/// would put example lines into the coverage report.
void main() {
  test('the example runs to completion on published code alone', () async {
    final result = await Process.run(
      Platform.resolvedExecutable,
      ['run', 'example/sku_catalog_example.dart'],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    // utf8 on the way out: the tour prints `×` and `→`, and the default system
    // encoding would mangle them.

    if (result.exitCode != 0) {
      fail(
        'the example exited ${result.exitCode}\n'
        'stdout: ${result.stdout}\n'
        'stderr: ${result.stderr}',
      );
    }

    final output = result.stdout.toString();
    // The load-bearing lines: a refusal is a value, and the fold adds the levels up.
    output.contains('refused').should.beTrue();
    output.contains('rollback').should.beTrue();
    output.contains('skus       QO-16, QO120').should.beTrue();
    output.contains('parts      2 × QO-16 → 16 × QO120').should.beTrue();
  }, timeout: const Timeout(Duration(minutes: 2)));
}
