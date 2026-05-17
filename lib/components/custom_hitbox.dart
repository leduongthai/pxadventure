import 'package:flame/components.dart';

class CustomHitbox {
  final double offsetX;
  final double offsetY;
  final double width;
  final double height;

  CustomHitbox({
    required this.offsetX,
    required this.offsetY,
    required this.width,
    required this.height,
  });

  Vector2 scaledPosition(Vector2 renderedSize, Vector2 sourceSize) {
    return Vector2(
      offsetX * renderedSize.x / sourceSize.x,
      offsetY * renderedSize.y / sourceSize.y,
    );
  }

  Vector2 scaledSize(Vector2 renderedSize, Vector2 sourceSize) {
    return Vector2(
      width * renderedSize.x / sourceSize.x,
      height * renderedSize.y / sourceSize.y,
    );
  }

  double scaledTop(Vector2 renderedSize, Vector2 sourceSize) {
    return offsetY * renderedSize.y / sourceSize.y;
  }
}
