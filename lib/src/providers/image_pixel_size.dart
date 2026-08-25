import 'dart:math' as math;
import 'dart:typed_data';

/// Reads the pixel dimensions out of encoded image bytes, without decoding the image.
///
/// The point is to know how big an icon really is rather than how big a site said it was. A site
/// that declares `512x512` and serves a 32 pixel file should score as 32.
abstract final class ImagePixelSize {
  /// The shorter of width and height, or null if the bytes are not a format this reads.
  static int? shortestSide(Uint8List data) {
    final png = _png(data);
    if (png != null) return math.min(png.$1, png.$2);
    final ico = _ico(data);
    if (ico != null) return ico;
    final jpeg = _jpeg(data);
    if (jpeg != null) return math.min(jpeg.$1, jpeg.$2);
    return null;
  }

  static (int, int)? _png(Uint8List data) {
    if (data.length < 24) return null;
    const signature = [137, 80, 78, 71, 13, 10, 26, 10];
    for (var i = 0; i < signature.length; i++) {
      if (data[i] != signature[i]) return null;
    }
    return (_int32(data, 16), _int32(data, 20));
  }

  static int? _ico(Uint8List data) {
    if (data.length < 8) return null;
    if (data[0] != 0 || data[1] != 0 || data[2] != 1) return null;
    final count = data[4] | (data[5] << 8);
    if (count <= 0 || data.length < 6 + count * 16) return null;

    // An .ico is a bundle; a stored 0 means 256, which is the format's way of not having a byte
    // wide enough.
    var largest = 0;
    for (var entry = 0; entry < count; entry++) {
      final offset = 6 + entry * 16;
      final width = data[offset] == 0 ? 256 : data[offset];
      final height = data[offset + 1] == 0 ? 256 : data[offset + 1];
      largest = math.max(largest, math.min(width, height));
    }
    return largest > 0 ? largest : null;
  }

  static (int, int)? _jpeg(Uint8List data) {
    if (data.length < 4) return null;
    if (data[0] != 0xFF || data[1] != 0xD8) return null;

    var index = 2;
    while (index + 9 < data.length) {
      if (data[index] != 0xFF) {
        index++;
        continue;
      }
      final marker = data[index + 1];
      final length = (data[index + 2] << 8) | data[index + 3];

      // SOF0 through SOF15, excluding the four that are not frame headers.
      if (marker >= 0xC0 && marker <= 0xCF && marker != 0xC4 && marker != 0xC8 && marker != 0xCC) {
        final height = (data[index + 5] << 8) | data[index + 6];
        final width = (data[index + 7] << 8) | data[index + 8];
        return (width, height);
      }
      if (length <= 0) return null;
      index += 2 + length;
    }
    return null;
  }

  static int _int32(Uint8List data, int offset) =>
      (data[offset] << 24) | (data[offset + 1] << 16) | (data[offset + 2] << 8) | data[offset + 3];
}
