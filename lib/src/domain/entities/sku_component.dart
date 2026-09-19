import 'package:equatable/equatable.dart';

import 'meta.dart';

/// A BOM edge: parent SKU contains [quantity] of child SKU.
class SkuComponent extends Equatable {
  /// Creation metadata.
  final Meta meta;

  /// Id of the parent [DeviceType].
  final String parentDeviceTypeId;

  /// Id of the child [DeviceType].
  final String childDeviceTypeId;

  /// Quantity of the child in one unit of the parent.
  final int quantity;

  /// Creates a [SkuComponent].
  const SkuComponent({
    required this.meta,
    required this.parentDeviceTypeId,
    required this.childDeviceTypeId,
    required this.quantity,
  });

  /// Converts to JSON with snake_case keys.
  Map<String, dynamic> toJson() => {
    ...meta.toJson(),
    'parent_device_type_id': parentDeviceTypeId,
    'child_device_type_id': childDeviceTypeId,
    'quantity': quantity,
  };

  /// Parses a [SkuComponent] from the original app's snake_case JSON record.
  factory SkuComponent.fromJson(Map<String, dynamic> json) => SkuComponent(
    meta: Meta.fromJson(json),
    parentDeviceTypeId: json['parent_device_type_id'] as String? ?? '',
    childDeviceTypeId: json['child_device_type_id'] as String? ?? '',
    quantity: (json['quantity'] as num?)?.toInt() ?? 1,
  );

  @override
  List<Object?> get props => [
    meta,
    parentDeviceTypeId,
    childDeviceTypeId,
    quantity,
  ];
}
