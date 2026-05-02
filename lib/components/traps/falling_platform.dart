import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum _FPState { on, off }

class FallingPlatform extends SpriteAnimationGroupComponent
    with HasGameRef<PixelAdventure>, CollisionCallbacks {
  FallingPlatform({super.position, super.size});

  static const stepTime = 0.1;
  final textureSize = Vector2(32, 10);

  Vector2 _originalPosition = Vector2.zero();
  bool _isFalling = false;
  bool _isRespawning = false;
  double _fallVelocity = 0;
  double _shakeTimer = 0;
  double _fallTimer = 0;
  bool _triggered = false;

  late final RectangleHitbox _hitbox;

  @override
  FutureOr<void> onLoad() {
    _originalPosition = position.clone();

    _hitbox = RectangleHitbox(
      position: Vector2.zero(),
      size: Vector2(size.x, size.y),
      collisionType: CollisionType.passive,
    );
    add(_hitbox);

    animations = {
      _FPState.on: SpriteAnimation.fromFrameData(
        game.images.fromCache('Traps/Falling Platforms/On (32x10).png'),
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: stepTime,
          textureSize: textureSize,
        ),
      ),
      _FPState.off: SpriteAnimation.fromFrameData(
        game.images.fromCache('Traps/Falling Platforms/Off.png'),
        SpriteAnimationData.sequenced(
          amount: 1,
          stepTime: 1,
          textureSize: textureSize,
        ),
      ),
    };
    current = _FPState.on;
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (_isRespawning) {
      super.update(dt);
      return;
    }

    // Check if player is standing on top by proximity
    final player = game.player;
    final playerBottom = player.y + player.height;
    final platformTop = position.y;

    final playerOnTop = (playerBottom >= platformTop - 4 &&
        playerBottom <= platformTop + 8 &&
        player.x + player.width > position.x &&
        player.x < position.x + size.x &&
        player.velocity.y >= 0);

    if (playerOnTop && !_triggered && !_isFalling) {
      _triggered = true;
      _shakeTimer = 0;
    }

    if (_triggered && !_isFalling) {
      _shakeTimer += dt;
      // Shake effect
      position.x = _originalPosition.x + ((_shakeTimer * 20).floor() % 2 == 0 ? 1.5 : -1.5);

      if (_shakeTimer >= 0.5) {
        _fallTimer += dt;
      }
      if (_fallTimer >= 0.5) {
        _isFalling = true;
        _triggered = false;
        current = _FPState.off;
        _hitbox.collisionType = CollisionType.inactive;
      }
    }

    if (_isFalling) {
      _fallVelocity += 200 * dt;
      position.y += _fallVelocity * dt;

      if (position.y > 800) {
        _startRespawn();
      }
    }

    super.update(dt);
  }

  void _startRespawn() {
    _isFalling = false;
    _isRespawning = true;
    _fallVelocity = 0;
    _shakeTimer = 0;
    _fallTimer = 0;
    _triggered = false;

    Future.delayed(const Duration(seconds: 3), () {
      if (!isMounted) return;
      position = _originalPosition.clone();
      current = _FPState.on;
      _hitbox.collisionType = CollisionType.passive;
      _isRespawning = false;
    });
  }
}
