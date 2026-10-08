import 'package:equatable/equatable.dart';

import 'bom_line.dart';

/// What a build consumes: a SKU's assembly tree folded into quantities.
///
/// Every quantity in [lines] is already multiplied by [units], so this is the
/// requirement for the build itself, not for one unit of [skuId]. The
/// SKU being built is [skuId] and has no line of its own.
class BillOfMaterials extends Equatable {
  /// Id of the SKU the build assembles.
  final String skuId;

  /// Model number of that SKU.
  final String modelNumber;

  /// How many of [skuId] the build assembles.
  final int units;

  /// The parts it consumes, one line per distinct SKU, in level order.
  final List<BomLine> lines;

  /// Creates a [BillOfMaterials].
  const BillOfMaterials({
    required this.skuId,
    required this.modelNumber,
    required this.units,
    required this.lines,
  });

  @override
  List<Object?> get props => [skuId, modelNumber, units, lines];
}
