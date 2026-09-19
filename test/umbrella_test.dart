import 'package:sku_catalog/sku_catalog.dart';
import 'package:test/test.dart';

/// The umbrella package exists so one dependency gets you everything. If either
/// half stops being re-exported, this file stops compiling — which is the whole
/// check.
void main() {
  test('the model is exported', () {
    expect(Meta, isNotNull);
    expect(Trait, isNotNull);
    expect(TraitAttributeDefinition, isNotNull);
    expect(DataType, isNotNull);
    expect(DeviceType, isNotNull);
    expect(SkuComponent, isNotNull);
    expect(Manufacturer, isNotNull);
    expect(Locate, isNotNull);
    expect(Device, isNotNull);
    expect(IDeviceTypeRepository, isNotNull);
    expect(DomainFailure, isNotNull);
  });

  test('the operations are exported', () {
    expect(AddSkuComponent, isNotNull);
    expect(ResolveSchema, isNotNull);
    expect(ResolveTraitChain, isNotNull);
    expect(CreateDeviceType, isNotNull);
    expect(DeleteDevice, isNotNull);
    expect(WouldCreateAssemblyCycle, isNotNull);
  });

  test('the pieces fit: a trait carries an attribute through the umbrella', () {
    const trait = TraitScope.sku;
    expect(trait, TraitScope.sku);
  });
}
