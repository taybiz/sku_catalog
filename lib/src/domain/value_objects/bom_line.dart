import 'package:equatable/equatable.dart';

/// One line of a folded bill of materials: a part, and how many of it the build
/// needs.
///
/// One line per distinct SKU however many ways the assembly tree reaches it —
/// [quantity] is the sum over every path.
class BomLine extends Equatable {
  /// Id of the SKU this line is for.
  final String deviceTypeId;

  /// Model number of that SKU, or null when the catalog has no SKU row for it
  /// (an assembly edge pointing at something that is not there). The line still
  /// reports what the edge asks for.
  final String? modelNumber;

  /// Total the build needs, every path counted and multiplied by the build's
  /// unit count.
  final int quantity;

  /// Closest level the part is used at: 1 when the built SKU holds it directly,
  /// deeper when it sits inside a sub-assembly.
  final int depth;

  /// Whether the part has components of its own, so it can be built rather than
  /// bought.
  final bool isAssembly;

  /// Creates a [BomLine].
  const BomLine({
    required this.deviceTypeId,
    this.modelNumber,
    required this.quantity,
    required this.depth,
    required this.isAssembly,
  });

  @override
  List<Object?> get props => [
    deviceTypeId,
    modelNumber,
    quantity,
    depth,
    isAssembly,
  ];
}
