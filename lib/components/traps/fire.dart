import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/components/custom_hitbox.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum _FireState { on, hit }

class Fire extends SpriteAnimationGroupComponent
    with HasGameReference<PixelAdventure>, CollisionCallbacks {
  Fire({super.position, super.size});

  static const stepTime = 0.1;
  final textureSize = Vector2(16, 32);
  final hitbox = CustomHitbox(offsetX: 2, offsetY: 4, width: 12, height: 24);

  @override
  FutureOr<void> onLoad() {
    priority = -1;

    add(RectangleHitbox(
      position: hitbox.scaledPosition(size, textureSize),
      size: hitbox.scaledSize(size, textureSize),
      collisionType: CollisionType.passive,
    ));

    animations = {
      _FireState.on: SpriteAnimation.fromFrameData(
        game.images.fromCache('Traps/Fire/On (16x32).png'),
        SpriteAnimationData.sequenced(
            amount: 3, stepTime: stepTime, textureSize: textureSize),
      ),
      _FireState.hit: SpriteAnimation.fromFrameData(
        game.images.fromCache('Traps/Fire/Hit (16x32).png'),
        SpriteAnimationData.sequenced(
            amount: 2,
            stepTime: stepTime,
            textureSize: textureSize,
            loop: false),
      ),
    };
    current = _FireState.on;
    return super.onLoad();
  }

  void collidedWithPlayer() {
    game.player.collidedwithEnemy();
  }
}
