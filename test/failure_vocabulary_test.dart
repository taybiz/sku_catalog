import 'package:shouldly/shouldly.dart';
import 'package:sku_catalog/sku_catalog.dart';
import 'package:test/test.dart';

/// A product's own failure family, declared OUTSIDE this package.
///
/// This file is the reason `DomainFailure` stays open. The declarations below
/// compile only while the root can be extended from another library, so
/// re-sealing it does not fail a test — it stops the suite building at all,
/// which is the contract: a consumer composes in this channel instead of
/// translating into it.
sealed class _ProductFailure extends DomainFailure {
  const _ProductFailure(super.message);
}

final class _ProductUnreachable extends _ProductFailure {
  const _ProductUnreachable(super.message);
}

void main() {
  group('Given the failure vocabulary of sku_catalog', () {
    test(
      'When a product declares its own family, Then it is a DomainFailure',
      () {
        const DomainFailure failure = _ProductUnreachable('store unreachable');

        failure.message.should.be('store unreachable');
        failure.should.beAssignableTo<DomainFailure>();
      },
    );

    test('Then a product leaf is not part of the catalog set', () {
      const DomainFailure failure = _ProductUnreachable('store unreachable');

      (failure is CatalogFailure).should.beFalse();
    });

    test('When the catalog set is switched, Then it is closed and complete', () {
      // No `default`: this compiles only while [CatalogFailure] is sealed and
      // every leaf is named here. A leaf added upstream breaks this on purpose.
      String kindOf(CatalogFailure failure) => switch (failure) {
        NotFoundFailure() => 'not-found',
        AlreadyExistsFailure() => 'already-exists',
        WouldCreateCycleFailure() => 'cycle',
        InvalidInputFailure() => 'invalid',
        PermissionDeniedFailure() => 'denied',
        InUseFailure() => 'in-use',
        InternalFailure() => 'internal',
        DatasourceFailure() => 'datasource',
        SerializationFailure() => 'serialization',
        DuplicateAttributeValueFailure() => 'duplicate-value',
      };

      kindOf(const NotFoundFailure('missing')).should.be('not-found');
      kindOf(
        const DuplicateAttributeValueFailure('taken'),
      ).should.be('duplicate-value');
    });
  });
}
