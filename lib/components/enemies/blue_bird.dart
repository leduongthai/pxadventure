import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/components/player.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum _BlueBirdState { flying, hit }

class BlueBird extends SpriteAnimationGroupComponent
    with HasGameRef<PixelAdventure>, CollisionCallbacks {
  final double offNeg;
  final double offPos;

  BlueBird({
    super.position,
    super.size,
    this.offNeg = 0,
    this.offPos = 0,
  });

  static const stepTime = 0.05;
  static const tileSize = 16;
  static const moveSpeed = 60.0;
  final textureSize = Vector2(32, 32);

  double moveDirection = 1;
  double rangeNeg = 0;
  double rangePos = 0;
  bool gotHit = false;

  @override
  FutureOr<void> onLoad() {
    add(RectangleHitbox(position: Vector2(4, 4), size: Vector2(24, 24)));
    _loadAnimations();
    _calculateRange();
    return super.onLoad();
  }

  void _loadAnimations() {
    animations = {
      _BlueBirdState.flying: SpriteAnimation.fromFrameData(
        game.images.fromCache('Enemies/BlueBird/Flying (32x32).png'),
        SpriteAnimationData.sequenced(amount: 9, stepTime: stepTime, textureSize: textureSize),
      ),
      _BlueBirdState.hit: SpriteAnimation.fromFrameData(
        game.images.fromCache('Enemies/BlueBird/Hit (32x32).png'),
        SpriteAnimationData.sequenced(amount: 5, stepTime: stepTime, textureSize: textureSize, loop: false),
      ),
    };
    current = _BlueBirdState.flying;
  }

  void _calculateRange() {
    rangeNeg = position.x - offNeg * tileSize;
    rangePos = position.x + offPos * tileSize;
  }

  @override
  void update(double dt) {
    if (!gotHit) _moveHorizontally(dt);
    super.update(dt);
  }

  void _moveHorizontally(double dt) {
    if (position.x >= rangePos) {
      moveDirection = -1;
      if (scale.x > 0) flipHorizontallyAroundCenter();
    } else if (position.x <= rangeNeg) {
      moveDirection = 1;
      if (scale.x < 0) flipHorizontallyAroundCenter();
    }
    position.x += moveDirection * moveSpeed * dt;
  }

  void collidedWithPlayer() {
    // BlueBird cannot be stomped — always damages player
    game.player.collidedwithEnemy();
  }
}
