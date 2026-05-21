import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/components/player.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum BossState { idle, run, hit, attack, charging }

class BossPig extends SpriteAnimationGroupComponent
    with HasGameReference<PixelAdventure>, CollisionCallbacks {
  final double offNeg;
  final double offPos;

  BossPig({
    super.position,
    super.size,
    this.offNeg = 0,
    this.offPos = 0,
  });

  static const stepTime = 0.05;
  static const speed = 60.0;
  static const attackSpeed = 250.0;
  static const tileSize = 16;
  
  int health = 10;
  int maxHealth = 10;
  double moveDirection = 1;
  double rangeNeg = 0;
  double rangePos = 0;
  bool isInvulnerable = false;
  bool isDead = false;
  bool isCharging = false;
  
  double attackTimer = 0;
  final double attackInterval = 4.0;
  
  late final Player player;
  late final RectangleComponent _healthBar;
  late final RectangleComponent _healthBarBg;

  @override
  FutureOr<void> onLoad() async {
    player = game.player;

    scale = Vector2.all(2.0); 

    position.y -= size.y * (scale.y - 1);

    add(RectangleHitbox(
      position: Vector2(2, 5),
      size: Vector2(size.x - 4, size.y - 5),
    ));

    _addHealthBar();

    _calculateRange();
    await _loadAllAnimations();
    return super.onLoad();
  }

  void _addHealthBar() {
    _healthBarBg = RectangleComponent(
      position: Vector2(size.x / 2, -5),
      size: Vector2(size.x * 0.8, 2),
      anchor: Anchor.bottomCenter,
      paint: Paint()..color = Colors.black.withOpacity(0.5),
    );

    _healthBar = RectangleComponent(
      position: Vector2(0, 0),
      size: Vector2(_healthBarBg.size.x, _healthBarBg.size.y),
      paint: Paint()..color = Colors.green,
    );

    _healthBarBg.add(_healthBar);
    add(_healthBarBg);
  }

  void _calculateRange() {
    rangeNeg = position.x - offNeg * tileSize;
    rangePos = position.x + offPos * tileSize;
  }

  @override
  void update(double dt) {
    if (isDead || health <= 0) return;
    
    _handleAttackLogic(dt);
    _updateMovement(dt);
    _updateState();
    _applyVisualEffects();
    _updateHealthBar();
    
    super.update(dt);
  }

  void _updateHealthBar() {
    _healthBar.size.x = _healthBarBg.size.x * (health / maxHealth);
    if (health <= 3) {
      _healthBar.paint.color = Colors.red;
    } else if (health <= 6) {
      _healthBar.paint.color = Colors.orange;
    }
  }

  void _handleAttackLogic(double dt) {
    attackTimer += dt;
    if (attackTimer >= attackInterval && !isCharging) {
      _startChargeAttack();
    }
  }

  void _startChargeAttack() async {
    isCharging = true;
    current = BossState.charging;

    await Future.delayed(const Duration(seconds: 1));
    
    if (isDead) return;
    current = BossState.attack;

    await Future.delayed(const Duration(seconds: 2));
    
    isCharging = false;
    attackTimer = 0;
  }

  void _updateMovement(double dt) {
    if (current == BossState.charging) return;

    double currentSpeed = isCharging ? attackSpeed : speed;
    if (health <= 5) currentSpeed *= 1.5;

    position.x += moveDirection * currentSpeed * dt;

    if (moveDirection < 0 && position.x <= rangeNeg) {
      moveDirection = 1;
      if (isCharging) _stopCharging();
    } else if (moveDirection > 0 && position.x >= rangePos) {
      moveDirection = -1;
      if (isCharging) _stopCharging();
    }
  }

  void _stopCharging() {
    isCharging = false;
    attackTimer = 0;
  }

  void _updateState() {
    if (isCharging) {
      if (current != BossState.attack) current = BossState.charging;
    } else if (current != BossState.hit) {
      current = BossState.run;
    }

    if ((moveDirection > 0 && scale.x > 0) || (moveDirection < 0 && scale.x < 0)) {
      flipHorizontallyAroundCenter();
    }
  }

  void _applyVisualEffects() {
    if (isInvulnerable || health <= 5) {
      paint.color = Colors.red.withOpacity(0.7);
    } else {
      paint.color = Colors.white;
    }
  }

  void takeDamage() {
    if (isInvulnerable || isDead) return;

    health--;
    current = BossState.hit;
    isInvulnerable = true;

    position.x -= moveDirection * 30;

    if (health <= 0) {
      _die();
    } else {
      Future.delayed(const Duration(milliseconds: 600), () {
        isInvulnerable = false;
      });
    }
  }

  void _die() async {
    isDead = true;
    current = BossState.hit;
    game.scoreManager.bossKilled = true;

    for (int i = 0; i < 5; i++) {
      opacity = 0;
      await Future.delayed(const Duration(milliseconds: 100));
      opacity = 1;
      await Future.delayed(const Duration(milliseconds: 100));
    }
    removeFromParent();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player && !isDead) {
      final bossHitboxTop = y + 10; 
      final isFalling = other.velocity.y > 0;
      if (isFalling && other.hitboxBottom < bossHitboxTop + 20) {
        takeDamage();
        other.bounceFromEnemy(300);
      } else if (!isInvulnerable) {
        other.collidedwithEnemy();
      }
    }
    super.onCollision(intersectionPoints, other);
  }

  Future<void> _loadAllAnimations() async {
    final idleImg = await game.images.load('Enemies/AngryPig/Idle (36x30).png');
    final walkImg = await game.images.load('Enemies/AngryPig/Walk (36x30).png');
    final runImg = await game.images.load('Enemies/AngryPig/Run (36x30).png');
    final hitImg = await game.images.load('Enemies/AngryPig/Hit 1 (36x30).png');

    animations = {
      BossState.idle: SpriteAnimation.fromFrameData(
        idleImg,
        SpriteAnimationData.sequenced(amount: 9, stepTime: stepTime, textureSize: Vector2(36, 30)),
      ),
      BossState.run: SpriteAnimation.fromFrameData(
        walkImg,
        SpriteAnimationData.sequenced(amount: 16, stepTime: stepTime, textureSize: Vector2(36, 30)),
      ),
      BossState.attack: SpriteAnimation.fromFrameData(
        runImg,
        SpriteAnimationData.sequenced(amount: 12, stepTime: stepTime, textureSize: Vector2(36, 30)),
      ),
      BossState.charging: SpriteAnimation.fromFrameData(
        idleImg,
        SpriteAnimationData.sequenced(amount: 9, stepTime: 0.02, textureSize: Vector2(36, 30)),
      ),
      BossState.hit: SpriteAnimation.fromFrameData(
        hitImg,
        SpriteAnimationData.sequenced(amount: 5, stepTime: stepTime, textureSize: Vector2(36, 30), loop: false),
      ),
    };
    current = BossState.idle;
  }
}
