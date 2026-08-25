/// One drawing step, in the source coordinate space.
///
/// The parser produces these rather than a `ui.Path` so parsing can be tested without a render
/// surface, and so the same parsed shape can be handed to any painter.
sealed class PathSegment {
  const PathSegment();
}

class MoveToSegment extends PathSegment {
  const MoveToSegment(this.x, this.y);
  final double x;
  final double y;
}

class LineToSegment extends PathSegment {
  const LineToSegment(this.x, this.y);
  final double x;
  final double y;
}

class CubicToSegment extends PathSegment {
  const CubicToSegment(this.c1x, this.c1y, this.c2x, this.c2y, this.x, this.y);
  final double c1x;
  final double c1y;
  final double c2x;
  final double c2y;
  final double x;
  final double y;
}

class QuadToSegment extends PathSegment {
  const QuadToSegment(this.cx, this.cy, this.x, this.y);
  final double cx;
  final double cy;
  final double x;
  final double y;
}

class CloseSegment extends PathSegment {
  const CloseSegment();
}
