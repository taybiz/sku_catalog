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

  /// Whether a value for this attribute may be held by at most one instance.
  ///
  /// A serial number is the case this exists for: the model says "this thing is
  /// serializable", and the value identifies *one* article, so two instances
  /// carrying the same one is not a coincidence, it is a mistake. The catalog
  /// enforces it on the instance write path — `AssertUniqueAttributeValues`
  /// refuses a value another instance already holds — so a definition is where
  /// the intent is stated and the rule is a use case, not a storage feature.
  ///
  /// Uniqueness is a statement about articles, not about models: a SKU-level
  /// value for a unique attribute (a default the instances inherit) is not
  /// asserted against, because only the articles hold an identity.
  final bool isUnique;

  /// Value that applies when neither an instance nor a SKU sets one.
  ///
  /// Typed by [dataType]. Null means there is no default, and an attribute
  /// nobody sets stays unset rather than being invented here.
  final dynamic defaultValue;

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
    this.isUnique = false,
    this.defaultValue,
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
    'is_unique': isUnique,
    if (defaultValue != null) 'default_value': defaultValue,
  };

  /// Parses a [TraitAttributeDefinition] from the original app's snake_case
  /// JSON record.
  factory TraitAttributeDefinition.fromJson(Map<String, dynamic> json) =>
      TraitAttributeDefinition(
        meta: Meta.fromJson(json),
        traitId: json['trait_id'] as String? ?? '',
        key: json['key'] as String? ?? '',
        displayLabel: json['display_label'] as String? ?? '',
        dataType:
            DataTypeX.fromWire(value: json['data_type']) ?? DataType.string,
        unit: json['unit'] as String?,
        enumOptions: stringListFromWire(value: json['enum_options']),
        isRequired: json['is_required'] as bool? ?? false,
        // A record written before the flag existed is not unique: the rule is
        // opted into, never inherited from silence.
        isUnique: json['is_unique'] as bool? ?? false,
        defaultValue: json['default_value'],
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
    isUnique,
    defaultValue,
  ];

  /// Whether [a] and [b] are the same value for this attribute.
  ///
  /// The attribute decides, because the value's meaning is the attribute's: a
  /// serial number is the same serial number whether it was typed with capitals
  /// or spaces around it. The comparison is the one this package makes for the
  /// other identities it keeps:
  ///
  /// - **strings** are trimmed and lower-cased, so `'SN-1'`, `'sn-1'` and
  ///   `' SN-1 '` are one value (`namesClash` makes the same call for names);
  /// - **numbers** are compared by value, so `20` and `20.0` are one number;
  /// - **different runtime types are different values**: `20` and `'20'` do not
  ///   match. [dataType] says what a value should be, and a value of the wrong
  ///   type is a data error rather than the same value spelled differently;
  /// - **null matches nothing**: an attribute nobody set is not a value, so two
  ///   instances that leave it unset cannot collide over it.
  bool valuesMatch({required Object? a, required Object? b}) {
    final left = _comparable(value: a);
    final right = _comparable(value: b);
    if (left == null || right == null) return false;
    return left == right;
  }

  /// The comparable form of [value], or null when it is not a value at all.
  static String? _comparable({required Object? value}) {
    if (value == null) return null;
    if (value is String) return 'string:${value.trim().toLowerCase()}';
    if (value is num) return 'number:${value.toDouble()}';
    if (value is bool) return 'boolean:$value';
    return '${value.runtimeType}:$value';
  }
}
