import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'package:test/test.dart';

/// The tree-cycle rule is a pure function over parent links, so it is tested
/// directly rather than through the two operations that use it (a place move and a
/// trait move). The rule it replaced took JSON rows plus the name of the parent
/// key, which is how a wire format ends up deciding what a model rule means.
void main() {
  group('Given a tree of four places', () {
    final links = <ParentLink>[
      (id: 'root', parentId: null),
      (id: 'room', parentId: 'root'),
      (id: 'shelf', parentId: 'room'),
      (id: 'box', parentId: 'shelf'),
    ];

    group('When a node is made its own parent', () {
      test('Then it is a cycle', () {
        wouldCreateTreeCycle(
          links: links,
          nodeId: 'room',
          parentId: 'room',
        ).should.beTrue();
      });
    });

    group('When a node is moved under its own descendant', () {
      test('Then it is a cycle', () {
        wouldCreateTreeCycle(
          links: links,
          nodeId: 'room',
          parentId: 'box',
        ).should.beTrue();
      });
    });

    group('When a node is moved beside its old place', () {
      test('Then it is not a cycle', () {
        wouldCreateTreeCycle(
          links: links,
          nodeId: 'box',
          parentId: 'root',
        ).should.beFalse();
      });
    });

    group('When a node is made a root', () {
      test('Then it is not a cycle', () {
        wouldCreateTreeCycle(
          links: links,
          nodeId: 'shelf',
          parentId: null,
        ).should.beFalse();
      });
    });

    group('When the proposed parent is unknown', () {
      test('Then the walk ends and this rule says no', () {
        wouldCreateTreeCycle(
          links: links,
          nodeId: 'box',
          parentId: 'nowhere',
        ).should.beFalse();
      });
    });
  });

  group('Given a tree that already holds a loop', () {
    test('When a node is moved into it, Then the walk stops', () {
      wouldCreateTreeCycle(
        links: const [(id: 'a', parentId: 'b'), (id: 'b', parentId: 'a')],
        nodeId: 'c',
        parentId: 'a',
      ).should.beFalse();
    });
  });
}
