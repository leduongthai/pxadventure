import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:pixel_adventure/components/player.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum _MushroomState { idle, run, hit }

class Mushroom extends SpriteAnimationGroupComponent
    with HasGameReference<PixelAdventure>, CollisionCallbacks {
  final double offNeg;
  final double offPos;

  Mushroom({
    super.position,
    super.size,
    this.offNeg = 0,
    this.offPos = 0,
  });

  static const stepTime = 0.05;
  static const tileSize = 16;
  static const runSpeed = 40.0;
  static const _bounceHeight = 260.0;
  final textureSize = Vector2(32, 32);

  Vector2 velocity = Vector2.zero();
  double rangeNeg = 0;
  double rangePos = 0;
  double moveDirection = 1;
  bool gotStomped = false;

  late final Player player;

  @override
  FutureOr<void> onLoad() {
    player = game.player;
    add(RectangleHitbox(position: Vector2(4, 4), size: Vector2(24, 24)));
    _loadAnimations();
    _calculateRange();
    return super.onLoad();
  }

  void _loadAnimations() {
    animations = {
      _MushroomState.idle: SpriteAnimation.fromFrameData(
        game.images.fromCache('Enemies/Mushroom/Idle (32x32).png'),
        SpriteAnimationData.sequenced(amount: 14, stepTime: stepTime, textureSize: textureSize),
      ),
      _MushroomState.run: SpriteAnimation.fromFrameData(
        game.images.fromCache('Enemies/Mushroom/Run (32x32).png'),
        SpriteAnimationData.sequenced(amount: 16, stepTime: stepTime, textureSize: textureSize),
      ),
      _MushroomState.hit: SpriteAnimation.fromFrameData(
        game.images.fromCache('Enemies/Mushroom/Hit.png'),
        SpriteAnimationData.sequenced(amount: 5, stepTime: stepTime, textureSize: textureSize, loop: false),
      ),
    };
    current = _MushroomState.idle;
  }

  void _calculateRange() {
    rangeNeg = position.x - offNeg * tileSize;
    rangePos = position.x + offPos * tileSize;
  }

  @override
  void update(double dt) {
    if (!gotStomped) {
      _patrol(dt);
      _updateState();
    }
    super.update(dt);
  }

  void _patrol(double dt) {
    if (position.x >= rangePos) {
      moveDirection = -1;
    } else if (position.x <= rangeNeg) {
      moveDirection = 1;
    }
    velocity.x = moveDirection * runSpeed;
    position.x += velocity.x * dt;
  }

  void _updateState() {
    current = velocity.x != 0 ? _MushroomState.run : _MushroomState.idle;
    if ((moveDirection > 0 && scale.x < 0) || (moveDirection < 0 && scale.x > 0)) {
      flipHorizontallyAroundCenter();
    }
  }

  void collidedWithPlayer() async {
    if (player.velocity.y > 0 && player.y + player.height > position.y) {
      if (game.playSounds) FlameAudio.play('bounce.wav', volume: game.soundVolume);
      gotStomped = true;
      current = _MushroomState.hit;
      player.velocity.y = -_bounceHeight;
      game.scoreManager.addEnemyKillScore();
      await animationTicker?.completed;
      removeFromParent();
    } else {
      player.collidedwithEnemy();
    }
  }
}
