import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum _FireState { on, hit }

class Fire extends SpriteAnimationGroupComponent
    with HasGameRef<PixelAdventure>, CollisionCallbacks {
  Fire({super.position, super.size});

  static const stepTime = 0.1;
  final textureSize = Vector2(16, 32);

  @override
  FutureOr<void> onLoad() {
    priority = -1;

    // Smaller hitbox for fair feel — offset 8px from top
    add(CircleHitbox(
      radius: 6,
      position: Vector2(size.x / 2 - 6, size.y / 2 + 2),
      collisionType: CollisionType.passive,
    ));

    animations = {
      _FireState.on: SpriteAnimation.fromFrameData(
        game.images.fromCache('Traps/Fire/On (16x32).png'),
        SpriteAnimationData.sequenced(amount: 3, stepTime: stepTime, textureSize: textureSize),
      ),
      _FireState.hit: SpriteAnimation.fromFrameData(
        game.images.fromCache('Traps/Fire/Hit (16x32).png'),
        SpriteAnimationData.sequenced(amount: 2, stepTime: stepTime, textureSize: textureSize, loop: false),
      ),
    };
    current = _FireState.on;
    return super.onLoad();
  }

  void collidedWithPlayer() {
    game.player.collidedwithEnemy();
  }
}
