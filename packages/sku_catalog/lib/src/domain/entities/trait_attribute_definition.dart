import 'package:equatable/equatable.dart';

import '../enums/data_type.dart';
import '../json_coercion.dart';
import 'meta.dart';

/// A typed attribute definition belonging to a [Trait].
class TraitAttributeDefinition extends Equatable {
  /// Creation metadata.
  final Meta meta;

  /// Id of the parent trait.
  final String traitId;

  /// Machine key (e.g. "trip_amperage", "load_amps").
  final String key;

  /// Human-readable display label.
  final String displayLabel;

  /// Value type.
  final DataType dataType;

  /// Optional unit suffix (e.g. "A", "V", "VA").
  final String? unit;

  /// Allowed values when [dataType] is [DataType.enumType].
  final List<String> enumOptions;

  /// Whether this attribute is required.
  final bool isRequired;

  /// Creates a [TraitAttributeDefinition].
  const TraitAttributeDefinition({
    required this.meta,
    required this.traitId,
    required this.key,
    required this.displayLabel,
    required this.dataType,
    this.unit,
    this.enumOptions = const [],
    this.isRequired = false,
  });

  /// Converts to JSON with snake_case keys.
  Map<String, dynamic> toJson() => {
    ...meta.toJson(),
    'trait_id': traitId,
    'key': key,
    'display_label': displayLabel,
    'data_type': dataType.name,
    if (unit != null) 'unit': unit,
    'enum_options': enumOptions,
    'is_required': isRequired,
  };

  /// Parses a [TraitAttributeDefinition] from the original app's snake_case
  /// JSON record.
  factory TraitAttributeDefinition.fromJson(Map<String, dynamic> json) =>
      TraitAttributeDefinition(
        meta: Meta.fromJson(json),
        traitId: json['trait_id'] as String? ?? '',
        key: json['key'] as String? ?? '',
        displayLabel: json['display_label'] as String? ?? '',
        dataType: DataTypeX.fromWire(json['data_type']) ?? DataType.string,
        unit: json['unit'] as String?,
        enumOptions: stringListFromWire(json['enum_options']),
        isRequired: json['is_required'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [
    meta,
    traitId,
    key,
    displayLabel,
    dataType,
    unit,
    enumOptions,
    isRequired,
  ];
}
