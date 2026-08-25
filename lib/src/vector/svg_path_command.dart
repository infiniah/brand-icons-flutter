enum SVGCommandKind {
  move,
  close,
  line,
  horizontalLine,
  verticalLine,
  cubic,
  smoothCubic,
  quadratic,
  smoothQuadratic,
  arc,
}

/// One letter of SVG path data, split into what it draws and whether operands are relative.
class SVGPathCommand {
  const SVGPathCommand(this.kind, this.isRelative);

  final SVGCommandKind kind;
  final bool isRelative;

  /// What a bare run of extra operands means.
  ///
  /// The grammar lets a command letter be given once and its operands repeated, so `M0 0 1 1` is a
  /// move followed by a line. `Z` takes no operands, so it has no repeated form.
  SVGPathCommand? get repeated {
    switch (kind) {
      case SVGCommandKind.close:
        return null;
      case SVGCommandKind.move:
        return SVGPathCommand(SVGCommandKind.line, isRelative);
      default:
        return this;
    }
  }

  static SVGPathCommand? from(int codeUnit) {
    final lowered = String.fromCharCode(codeUnit).toLowerCase();
    final kind = switch (lowered) {
      'm' => SVGCommandKind.move,
      'z' => SVGCommandKind.close,
      'l' => SVGCommandKind.line,
      'h' => SVGCommandKind.horizontalLine,
      'v' => SVGCommandKind.verticalLine,
      'c' => SVGCommandKind.cubic,
      's' => SVGCommandKind.smoothCubic,
      'q' => SVGCommandKind.quadratic,
      't' => SVGCommandKind.smoothQuadratic,
      'a' => SVGCommandKind.arc,
      _ => null,
    };
    if (kind == null) return null;
    final isRelative = String.fromCharCode(codeUnit) == lowered;
    return SVGPathCommand(kind, isRelative);
  }
}
