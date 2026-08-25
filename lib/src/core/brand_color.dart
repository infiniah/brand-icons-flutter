/// A brand tint, kept as sRGB components so the library stays free of platform colour types.
class BrandColor {
  const BrandColor(this.red, this.green, this.blue);

  final int red;
  final int green;
  final int blue;

  /// `0xAARRGGBB`, which is what `dart:ui` wants.
  int get argb => 0xFF000000 | (red << 16) | (green << 8) | blue;

  /// Perceived brightness, 0 for black and 1 for white.
  ///
  /// sRGB weights rather than a plain average: a mean calls `#0000FF` as bright as `#00FF00`.
  double get relativeLuminance =>
      (0.2126 * red + 0.7152 * green + 0.0722 * blue) / 255;

  /// How far apart two colours read, 0 for identical brightness and 1 for black against white.
  double contrast(BrandColor other) =>
      (relativeLuminance - other.relativeLuminance).abs();

  /// Parses `F24E1E`, `#F24E1E`, the `FFF` and `FFFF` shorthands, and the eight digit form.
  ///
  /// The artwork writes white as `#fff`, so rejecting shorthand drops the light layer of a two
  /// tone mark and paints it in the fallback colour.
  static BrandColor? fromHex(String hex) {
    var text = hex.startsWith('#') ? hex.substring(1) : hex;
    if (text.length == 3 || text.length == 4) {
      text = text.split('').map((character) => '$character$character').join();
    }
    if (text.length != 6 && text.length != 8) return null;
    final value = int.tryParse(text, radix: 16);
    if (value == null) return null;
    if (text.length == 6) {
      return BrandColor((value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF);
    }
    return BrandColor((value >> 24) & 0xFF, (value >> 16) & 0xFF, (value >> 8) & 0xFF);
  }

  @override
  bool operator ==(Object other) =>
      other is BrandColor &&
      other.red == red &&
      other.green == green &&
      other.blue == blue;

  @override
  int get hashCode => Object.hash(red, green, blue);
}
