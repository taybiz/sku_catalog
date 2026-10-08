import 'package:equatable/equatable.dart';

import 'meta.dart';

/// A BOM edge: parent SKU contains [quantity] of child SKU.
class SkuComponent extends Equatable {
  /// Creation metadata.
  final Meta meta;

  /// Id of the parent [Sku].
  final String parentSkuId;

  /// Id of the child [Sku].
  final String childSkuId;

  /// Quantity of the child in one unit of the parent.
  final int quantity;

  /// Creates a [SkuComponent].
  const SkuComponent({
    required this.meta,
    required this.parentSkuId,
    required this.childSkuId,
    required this.quantity,
  });

  /// Converts to JSON with snake_case keys.
  Map<String, dynamic> toJson() => {
    ...meta.toJson(),
    'parent_sku_id': parentSkuId,
    'child_sku_id': childSkuId,
    'quantity': quantity,
  };

  /// Parses a [SkuComponent] from the original app's snake_case JSON record.
  factory SkuComponent.fromJson(Map<String, dynamic> json) => SkuComponent(
    meta: Meta.fromJson(json),
    parentSkuId: json['parent_sku_id'] as String? ?? '',
    childSkuId: json['child_sku_id'] as String? ?? '',
    quantity: (json['quantity'] as num?)?.toInt() ?? 1,
  );

  @override
  List<Object?> get props => [meta, parentSkuId, childSkuId, quantity];
}
