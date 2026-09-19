/// Owner category for an [ImageRecord].
enum ImageOwner {
  /// The image belongs to a [Device].
  device,

  /// The image belongs to a [Locate].
  locate,

  /// The image belongs to a [DeviceType] (SKU).
  sku,
}
