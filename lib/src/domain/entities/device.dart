import 'package:equatable/equatable.dart';

import '../json_coercion.dart';
import 'meta.dart';

/// A concrete installed device — one instance of a [DeviceType] (SKU).
///
/// The SKU is the class ("a 20 A single-pole switch"); a [Device] is the
/// individual article ("the one in rack 3, position 2"). Everything true of
/// the model lives on the SKU; everything true of *this* article lives here,
/// and this class carries its own traits and attribute values so an instance
/// can be classified and valued independently of the model it came from.
class Device extends Equatable {
  static const Object _unset = Object();

  /// Creation metadata.
  final Meta meta;

  /// Id of the [DeviceType] (SKU) this device instantiates.
  final String deviceTypeId;

  /// Id of the [Locate] this device sits at, or null when it is not placed.
  ///
  /// A device sits at exactly one place; a place may hold many devices.
  final String? locateId;

  /// Display name.
  final String name;

  /// SKU model number, copied from the device type for labelling.
  final String? skuModelNumber;

  /// Optional serial number.
  final String? serialNumber;

  /// Ids of images attached to this device.
  final List<String> imageIds;

  /// Ids of traits attached to this device (instance-level classification).
  final List<String> traitIds;

  /// Trait attribute values keyed by attribute key, for this instance.
  final Map<String, dynamic> attributeValues;

  /// Optional icon name for the UI.
  final String? icon;

  /// Creates a [Device].
  const Device({
    required this.meta,
    required this.deviceTypeId,
    required this.locateId,
    required this.name,
    this.skuModelNumber,
    this.serialNumber,
    this.imageIds = const [],
    this.traitIds = const [],
    this.attributeValues = const {},
    this.icon,
  });

  /// Shorthand for `meta.id`.
  String get deviceId => meta.id;

  /// Whether this device is placed at a locate.
  bool get isPlaced => locateId != null;

  /// Creates a copy with optional field overrides. Nullable fields use the
  /// sentinel pattern so they can be explicitly cleared
  /// (e.g. `copyWith(locateId: null)` un-places the device).
  Device copyWith({
    Meta? meta,
    String? deviceTypeId,
    Object? locateId = _unset,
    String? name,
    Object? skuModelNumber = _unset,
    Object? serialNumber = _unset,
    List<String>? imageIds,
    List<String>? traitIds,
    Map<String, dynamic>? attributeValues,
    Object? icon = _unset,
  }) => Device(
    meta: meta ?? this.meta,
    deviceTypeId: deviceTypeId ?? this.deviceTypeId,
    locateId: locateId == _unset ? this.locateId : locateId as String?,
    name: name ?? this.name,
    skuModelNumber: skuModelNumber == _unset
        ? this.skuModelNumber
        : skuModelNumber as String?,
    serialNumber: serialNumber == _unset
        ? this.serialNumber
        : serialNumber as String?,
    imageIds: imageIds ?? this.imageIds,
    traitIds: traitIds ?? this.traitIds,
    attributeValues: attributeValues ?? this.attributeValues,
    icon: icon == _unset ? this.icon : icon as String?,
  );

  /// Converts to JSON with snake_case keys.
  Map<String, dynamic> toJson() => {
    ...meta.toJson(),
    'device_type_id': deviceTypeId,
    'locate_id': locateId,
    'name': name,
    if (skuModelNumber != null) 'sku_model_number': skuModelNumber,
    if (serialNumber != null) 'serial_number': serialNumber,
    'image_ids': imageIds,
    'trait_ids': traitIds,
    'attribute_values': attributeValues,
    'icon': icon,
  };

  /// Creates a [Device] from snake_case JSON.
  factory Device.fromJson(Map<String, dynamic> json) => Device(
    meta: Meta.fromJson(json),
    deviceTypeId: json['device_type_id'] as String? ?? '',
    locateId: json['locate_id'] as String?,
    name: json['name'] as String? ?? '',
    skuModelNumber: json['sku_model_number'] as String?,
    serialNumber: json['serial_number'] as String?,
    imageIds: stringListFromWire(json['image_ids']),
    traitIds: stringListFromWire(json['trait_ids']),
    attributeValues: asStringMap(json['attribute_values']),
    icon: json['icon'] as String?,
  );

  @override
  List<Object?> get props => [
    meta,
    deviceTypeId,
    locateId,
    name,
    skuModelNumber,
    serialNumber,
    imageIds,
    traitIds,
    attributeValues,
    icon,
  ];
}
