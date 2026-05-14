import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum _BlueBirdState { flying, hit }

class BlueBird extends SpriteAnimationGroupComponent
    with HasGameReference<PixelAdventure>, CollisionCallbacks {
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
  static const _bounceHeight = 260.0;
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

  void collidedWithPlayer() async {
    final player = game.player;
    final playerCenterY = player.y + player.height / 2;
    final birdCenterY = position.y + height / 2;
    final stompedFromAbove = player.velocity.y > 0 && playerCenterY < birdCenterY;

    if (stompedFromAbove) {
      if (game.playSounds) {
        FlameAudio.play('bounce.wav', volume: game.soundVolume);
      }
      gotHit = true;
      current = _BlueBirdState.hit;
      player.bounceFromEnemy(_bounceHeight);
      game.scoreManager.addEnemyKillScore();
      await animationTicker?.completed;
      removeFromParent();
    } else {
      player.collidedwithEnemy();
    }
  }
}
