import 'dart:async';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';

class BackgroundTile extends PositionComponent
    with HasGameReference<FlameGame> {
  final String color;

  BackgroundTile({
    this.color = 'Gray',
    super.position,
    super.size,
  });

  static const double _scrollSpeed = 18;

  final ui.Paint _paint = ui.Paint();
  late ui.Image _image;
  double _scrollOffset = 0;

  @override
  FutureOr<void> onLoad() {
    priority = -10;
    if (size.x <= 0 || size.y <= 0) {
      size = game.size;
    }
    _image = game.images.fromCache('Background/$color.png');
    return super.onLoad();
  }

  @override
  void update(double dt) {
    final tileHeight = _image.height.toDouble();
    _scrollOffset = (_scrollOffset + _scrollSpeed * dt) % tileHeight;
    super.update(dt);
  }

  @override
  void render(ui.Canvas canvas) {
    final tileWidth = _image.width.toDouble();
    final tileHeight = _image.height.toDouble();

    canvas.save();
    canvas.clipRect(ui.Rect.fromLTWH(0, 0, size.x, size.y));

    for (var y = -tileHeight + _scrollOffset; y < size.y; y += tileHeight) {
      for (var x = 0.0; x < size.x; x += tileWidth) {
        canvas.drawImage(_image, ui.Offset(x, y), _paint);
      }
    }

    canvas.restore();
  }
}
