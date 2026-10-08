import 'package:equatable/equatable.dart';

/// One key/value property in an instance report.
class ReportProperty extends Equatable {
  /// Display label.
  final String label;

  /// Raw value.
  final dynamic value;

  /// Unit suffix.
  final String? unit;

  /// Creates a [ReportProperty].
  const ReportProperty({required this.label, required this.value, this.unit});

  @override
  List<Object?> get props => [label, value, unit];
}
