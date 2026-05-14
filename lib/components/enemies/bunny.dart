import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:pixel_adventure/components/player.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum _BunnyState { idle, run, jump, hit }

class Bunny extends SpriteAnimationGroupComponent
    with HasGameReference<PixelAdventure>, CollisionCallbacks {
  final double offNeg;
  final double offPos;

  Bunny({
    super.position,
    super.size,
    this.offNeg = 0,
    this.offPos = 0,
  });

  static const stepTime = 0.05;
  static const tileSize = 16;
  static const runSpeed = 70.0;
  static const _bounceHeight = 260.0;
  static const _jumpSpeed = -200.0;
  static const _detectionRange = 100.0;
  final textureSize = Vector2(34, 44);

  Vector2 velocity = Vector2.zero();
  double rangeNeg = 0;
  double rangePos = 0;
  double moveDirection = 1;
  double targetDirection = -1;
  double _groundY = 0;
  bool gotStomped = false;
  bool _isJumping = false;
  bool _isOnGround = true;
  final double _gravity = 9.8;
  final double _terminalVelocity = 300;

  late final Player player;

  @override
  FutureOr<void> onLoad() {
    player = game.player;
    _groundY = position.y;
    add(RectangleHitbox(position: Vector2(5, 6), size: Vector2(24, 36)));
    _loadAnimations();
    _calculateRange();
    return super.onLoad();
  }

  void _loadAnimations() {
    animations = {
      _BunnyState.idle: SpriteAnimation.fromFrameData(
        game.images.fromCache('Enemies/Bunny/Idle (34x44).png'),
        SpriteAnimationData.sequenced(amount: 7, stepTime: stepTime, textureSize: textureSize),
      ),
      _BunnyState.run: SpriteAnimation.fromFrameData(
        game.images.fromCache('Enemies/Bunny/Run (34x44).png'),
        SpriteAnimationData.sequenced(amount: 12, stepTime: stepTime, textureSize: textureSize),
      ),
      _BunnyState.jump: SpriteAnimation.fromFrameData(
        game.images.fromCache('Enemies/Bunny/Jump.png'),
        SpriteAnimationData.sequenced(amount: 1, stepTime: stepTime, textureSize: textureSize),
      ),
      _BunnyState.hit: SpriteAnimation.fromFrameData(
        game.images.fromCache('Enemies/Bunny/Hit (34x44).png'),
        SpriteAnimationData.sequenced(amount: 5, stepTime: stepTime, textureSize: textureSize, loop: false),
      ),
    };
    current = _BunnyState.idle;
  }

  void _calculateRange() {
    rangeNeg = position.x - offNeg * tileSize;
    rangePos = position.x + offPos * tileSize;
  }

  @override
  void update(double dt) {
    if (!gotStomped) {
      _updateState();
      _movement(dt);
      _applyGravity(dt);
    }
    super.update(dt);
  }

  void _applyGravity(double dt) {
    if (!_isOnGround) {
      velocity.y += _gravity;
      velocity.y = velocity.y.clamp(-_jumpSpeed.abs() * 1.5, _terminalVelocity);
      position.y += velocity.y * dt;
      if (position.y > _groundY + 96) {
        position.y = _groundY;
        velocity.y = 0;
        _isOnGround = true;
        _isJumping = false;
      }
    }
  }

  void _movement(double dt) {
    velocity.x = 0;
    double playerOffset = (player.scale.x > 0) ? 0 : -player.width;
    double bunnyOffset = (scale.x > 0) ? 0 : -width;

    double dx = (player.x + playerOffset) - (position.x + bunnyOffset);

    if (_playerInRange()) {
      targetDirection = dx < 0 ? -1 : 1;
      velocity.x = targetDirection * runSpeed;

      if (dx.abs() < _detectionRange && _isOnGround) {
        _jump();
      }
    }

    moveDirection = lerpDouble(moveDirection, targetDirection, 0.1) ?? 1;
    position.x += velocity.x * dt;
  }

  void _jump() {
    if (!_isOnGround) return;
    _isOnGround = false;
    _isJumping = true;
    velocity.y = _jumpSpeed;
    current = _BunnyState.jump;

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!gotStomped) {
        position.y = _groundY;
        _isOnGround = true;
        _isJumping = false;
        velocity.y = 0;
      }
    });
  }

  bool _playerInRange() {
    double playerOffset = (player.scale.x > 0) ? 0 : -player.width;
    return player.x + playerOffset >= rangeNeg &&
        player.x + playerOffset <= rangePos &&
        player.y + player.height > position.y &&
        player.y < position.y + height;
  }

  void _updateState() {
    if (_isJumping) {
      current = _BunnyState.jump;
    } else {
      current = velocity.x != 0 ? _BunnyState.run : _BunnyState.idle;
    }
    if ((moveDirection > 0 && scale.x > 0) || (moveDirection < 0 && scale.x < 0)) {
      flipHorizontallyAroundCenter();
    }
  }

  void collidedWithPlayer() async {
    if (player.velocity.y > 0 && player.y + player.height > position.y) {
      if (game.playSounds) FlameAudio.play('bounce.wav', volume: game.soundVolume);
      gotStomped = true;
      current = _BunnyState.hit;
      player.velocity.y = -_bounceHeight;
      game.scoreManager.addEnemyKillScore();
      await animationTicker?.completed;
      removeFromParent();
    } else {
      player.collidedwithEnemy();
    }
  }
}
