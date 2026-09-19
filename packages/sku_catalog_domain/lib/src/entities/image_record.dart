import 'package:equatable/equatable.dart';

import '../enums/image_owner.dart';

/// An image file attached to a catalog entity: a [Device], [Locate], or
/// [DeviceType] (SKU).
///
/// Unifies the former DeviceImage/LocateImage pair into one record with an
/// owner selector; SKU images are a new capability the original app lacked.
class ImageRecord extends Equatable {
  /// Image record id.
  final String id;

  /// Which catalog entity owns this image.
  final ImageOwner owner;

  /// Id of the owning entity (device/locate/sku).
  final String ownerId;

  /// Original filename.
  final String filename;

  /// Stored path (data URL, or path relative to the image directory).
  final String storedPath;

  /// UTC ISO-8601 creation timestamp.
  final String createdAt;

  /// Creates an [ImageRecord].
  const ImageRecord({
    required this.id,
    required this.owner,
    required this.ownerId,
    required this.filename,
    required this.storedPath,
    required this.createdAt,
  });

  /// Converts to snake_case JSON with the owner-typed key used on the wire
  /// (e.g. `device_id`, `locate_id`, `device_type_id`).
  Map<String, dynamic> toJson() => {
    'id': id,
    'owner': owner.name,
    'owner_id': ownerId,
    'filename': filename,
    'stored_path': storedPath,
    'created_at': createdAt,
  };

  /// Creates an [ImageRecord] from snake_case JSON.
  factory ImageRecord.fromJson(Map<String, dynamic> json) => ImageRecord(
    id: json['id'] as String? ?? '',
    owner: _parseOwner(json['owner']),
    ownerId: json['owner_id'] as String? ?? '',
    filename: json['filename'] as String? ?? '',
    storedPath: json['stored_path'] as String? ?? '',
    createdAt: json['created_at'] as String? ?? '',
  );

  /// Creates a copy with optional field overrides.
  ImageRecord copyWith({
    String? id,
    ImageOwner? owner,
    String? ownerId,
    String? filename,
    String? storedPath,
    String? createdAt,
  }) => ImageRecord(
    id: id ?? this.id,
    owner: owner ?? this.owner,
    ownerId: ownerId ?? this.ownerId,
    filename: filename ?? this.filename,
    storedPath: storedPath ?? this.storedPath,
    createdAt: createdAt ?? this.createdAt,
  );

  static ImageOwner _parseOwner(Object? v) {
    switch (v?.toString().toLowerCase()) {
      case 'device':
        return ImageOwner.device;
      case 'locate':
        return ImageOwner.locate;
      case 'sku':
        return ImageOwner.sku;
      default:
        return ImageOwner.device;
    }
  }

  @override
  List<Object?> get props => [
    id,
    owner,
    ownerId,
    filename,
    storedPath,
    createdAt,
  ];
}
