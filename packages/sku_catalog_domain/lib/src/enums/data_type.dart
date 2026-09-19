/// The data type of a trait attribute's value.
enum DataType {
  /// Numeric value.
  number,

  /// Text value.
  string,

  /// Boolean toggle.
  boolean,

  /// Constrained to a set of string options.
  enumType,
}

/// Extension on [DataType] for wire-format parsing.
extension DataTypeX on DataType {
  /// Parses a stored wire value into a [DataType], defaulting to
  /// [DataType.string] when the value is missing or unknown.
  static DataType? fromWire(Object? v) {
    switch (v?.toString().toLowerCase()) {
      case 'number':
        return DataType.number;
      case 'boolean':
        return DataType.boolean;
      case 'enum':
      case 'enumtype':
        return DataType.enumType;
      case 'string':
        return DataType.string;
      default:
        return null;
    }
  }
}
