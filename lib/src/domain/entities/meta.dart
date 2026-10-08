import 'package:equatable/equatable.dart';

/// Immutable identity + timestamp record carried by every persistent entity.
class Meta extends Equatable {
  /// Opaque identifier. The catalog stores, returns and compares it and never
  /// parses, orders, or does arithmetic on it, so a consumer may choose the
  /// shape (a UUID, a prefixed sequence, an int-backed string). The default
  /// minted by `newMeta()` is a random UUID v4; a create use case takes a
  /// fully formed entity, so the id there is the consumer's own.
  final String id;

  /// Freeform notes.
  final String notes;

  /// UTC ISO-8601 creation timestamp.
  final String createdAt;

  /// UTC ISO-8601 last-update timestamp.
  final String updatedAt;

  /// Creates a [Meta].
  const Meta({
    required this.id,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Converts to JSON with snake_case keys.
  Map<String, dynamic> toJson() => {
    'id': id,
    'notes': notes,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  /// Parses a [Meta] from the original app's snake_case JSON record.
  factory Meta.fromJson(Map<String, dynamic> json) => Meta(
    id: json['id'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
    createdAt: json['created_at'] as String? ?? '',
    updatedAt: json['updated_at'] as String? ?? '',
  );

  @override
  List<Object?> get props => [id, notes, createdAt, updatedAt];
}
