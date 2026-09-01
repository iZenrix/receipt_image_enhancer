/// A 2D point in image pixel coordinates.
final class ReceiptPoint {
  /// Creates an immutable point.
  const ReceiptPoint(this.x, this.y);

  /// Horizontal coordinate.
  final double x;

  /// Vertical coordinate.
  final double y;

  @override
  String toString() => 'ReceiptPoint($x, $y)';
}
