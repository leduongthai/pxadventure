import 'dart:async';
import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/components/player.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum BossState { idle, run, hit, attack, charging }

enum BossPattern { charger, stomper }

class BossPig extends SpriteAnimationGroupComponent
    with HasGameReference<PixelAdventure>, CollisionCallbacks {
  final double offNeg;
  final double offPos;
  final BossPattern pattern;
  final bool useSecretSprite;

  BossPig({
    super.position,
    super.size,
    this.offNeg = 0,
    this.offPos = 0,
    this.pattern = BossPattern.charger,
    this.useSecretSprite = false,
  });

  static const stepTime = 0.05;
  static const tileSize = 16;

  int health = 10;
  int maxHealth = 10;
  double moveDirection = 1;
  double rangeNeg = 0;
  double rangePos = 0;
  bool isInvulnerable = false;
  bool isDead = false;
  bool isCharging = false;
  bool _isLeaping = false;

  double attackTimer = 0;
  double attackInterval = 4.0;
  double _baseSpeed = 60;
  double _attackSpeed = 250;
  double _baseY = 0;
  double _leapElapsed = 0;
  double _leapDuration = 0.9;
  double _leapHeight = 54;
  double _leapStartX = 0;
  double _leapTargetX = 0;
  double _skillTimer = 0;
  double _skillInterval = 1.45;
  double _skillSpeed = 150;

  late final Player player;
  late final RectangleComponent _healthBar;
  late final RectangleComponent _healthBarBg;

  @override
  FutureOr<void> onLoad() async {
    player = game.player;
    _configurePattern();

    scale = useSecretSprite ? Vector2.all(1) : Vector2.all(2);
    if (!useSecretSprite) {
      position.y -= size.y * (scale.y - 1);
    }
    _baseY = position.y;

    add(RectangleHitbox(
      position: Vector2(2, 5),
      size: Vector2(size.x - 4, size.y - 5),
    ));

    _addHealthBar();
    _calculateRange();
    await _loadAllAnimations();
    return super.onLoad();
  }

  void _configurePattern() {
    switch (pattern) {
      case BossPattern.charger:
        maxHealth = 10;
        attackInterval = 4.0;
        _baseSpeed = 60;
        _attackSpeed = 250;
        break;
      case BossPattern.stomper:
        maxHealth = 12;
        attackInterval = 3.2;
        _baseSpeed = 45;
        _attackSpeed = 0;
        _leapDuration = 0.95;
        _leapHeight = 64;
        break;
    }
    if (useSecretSprite) {
      maxHealth = math.max(maxHealth, 14);
      attackInterval = 3.6;
      _skillInterval = 1.35;
      _skillSpeed = 165;
    }
    health = maxHealth;
  }

  void _addHealthBar() {
    _healthBarBg = RectangleComponent(
      position: Vector2(size.x / 2, -5),
      size: Vector2(size.x * 0.8, 2),
      anchor: Anchor.bottomCenter,
      paint: Paint()..color = Colors.black.withAlpha(128),
    );

    _healthBar = RectangleComponent(
      position: Vector2.zero(),
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
    if (health <= maxHealth * 0.3) {
      _healthBar.paint.color = Colors.red;
    } else if (health <= maxHealth * 0.6) {
      _healthBar.paint.color = Colors.orange;
    } else {
      _healthBar.paint.color = Colors.green;
    }
  }

  void _handleAttackLogic(double dt) {
    if (useSecretSprite) {
      _skillTimer += dt;
      if (_skillTimer >= _skillInterval) {
        _skillTimer = 0;
        _shootSkillProjectile();
      }
    }

    if (isCharging || _isLeaping) return;

    attackTimer += dt;
    if (attackTimer < attackInterval) return;

    switch (pattern) {
      case BossPattern.charger:
        _startChargeAttack();
        break;
      case BossPattern.stomper:
        _startLeapAttack();
        break;
    }
  }

  void _startChargeAttack() async {
    isCharging = true;
    current = BossState.charging;

    await Future.delayed(const Duration(milliseconds: 750));

    if (!isMounted || isDead) return;
    current = BossState.attack;

    await Future.delayed(const Duration(milliseconds: 1700));

    if (!isMounted || isDead) return;
    isCharging = false;
    attackTimer = 0;
  }

  void _startLeapAttack() async {
    isCharging = true;
    _facePlayer();
    current = BossState.charging;

    await Future.delayed(const Duration(milliseconds: 550));

    if (!isMounted || isDead) return;
    isCharging = false;
    _isLeaping = true;
    current = BossState.attack;
    _leapElapsed = 0;
    _leapStartX = position.x;
    _leapTargetX = player.position.x.clamp(rangeNeg, rangePos).toDouble();
    moveDirection = _leapTargetX >= position.x ? 1 : -1;
  }

  void _updateMovement(double dt) {
    if (_isLeaping) {
      _updateLeap(dt);
      return;
    }

    if (current == BossState.charging) return;

    var currentSpeed = isCharging ? _attackSpeed : _baseSpeed;
    if (health <= maxHealth / 2) currentSpeed *= 1.35;

    position.x += moveDirection * currentSpeed * dt;

    if (moveDirection < 0 && position.x <= rangeNeg) {
      position.x = rangeNeg;
      moveDirection = 1;
      if (isCharging) _stopChargeAttack();
    } else if (moveDirection > 0 && position.x >= rangePos) {
      position.x = rangePos;
      moveDirection = -1;
      if (isCharging) _stopChargeAttack();
    }
  }

  void _updateLeap(double dt) {
    _leapElapsed += dt;
    final progress = (_leapElapsed / _leapDuration).clamp(0, 1).toDouble();
    final arc = math.sin(progress * math.pi);

    position.x = _lerpDouble(_leapStartX, _leapTargetX, progress);
    position.y = _baseY - arc * _leapHeight;

    if (progress >= 1) {
      position.y = _baseY;
      _isLeaping = false;
      attackTimer = 0;
      current = BossState.run;
    }
  }

  void _stopChargeAttack() {
    isCharging = false;
    attackTimer = 0;
  }

  void _updateState() {
    if (_isLeaping) {
      current = BossState.attack;
    } else if (isCharging) {
      if (current != BossState.attack) current = BossState.charging;
    } else if (current != BossState.hit) {
      current = BossState.run;
    }

    if ((moveDirection > 0 && scale.x > 0) ||
        (moveDirection < 0 && scale.x < 0)) {
      flipHorizontallyAroundCenter();
    }
  }

  void _facePlayer() {
    moveDirection = player.position.x >= position.x ? 1 : -1;
  }

  void _shootSkillProjectile() {
    if (parent == null || isDead) return;

    final start = position + Vector2(size.x / 2, size.y * 0.42);
    final target =
        player.position + Vector2(player.width / 2, player.height / 2);
    final direction = target - start;
    if (direction.length2 == 0) {
      direction.x = moveDirection;
    }
    direction.normalize();
    moveDirection = direction.x >= 0 ? 1 : -1;

    parent!.add(SecretBossSkillProjectile(
      position: start - Vector2.all(14),
      size: Vector2.all(28),
      velocity: direction * _skillSpeed,
    ));
  }

  void _applyVisualEffects() {
    if (isInvulnerable) {
      paint.color = Colors.red.withAlpha(185);
    } else if (_isLeaping || isCharging) {
      paint.color = pattern == BossPattern.stomper
          ? const Color(0xFFC4F1FF)
          : const Color(0xFFFFD1D1);
    } else if (health <= maxHealth / 2) {
      paint.color = Colors.orangeAccent.withAlpha(210);
    } else {
      paint.color = Colors.white;
    }
  }

  void takeDamage() {
    if (isInvulnerable || isDead) return;

    health--;
    current = BossState.hit;
    isInvulnerable = true;

    position.x -= moveDirection * 24;
    position.x = position.x.clamp(rangeNeg, rangePos).toDouble();

    if (health <= 0) {
      _die();
    } else {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!isMounted) return;
        isInvulnerable = false;
      });
    }
  }

  void _die() async {
    isDead = true;
    current = BossState.hit;
    game.scoreManager.bossKilled = true;
    if (game.secretRun) {
      game.scoreManager.addSecretBossClearScore();
    } else {
      game.scoreManager.addBossKillScore();
    }

    for (var i = 0; i < 5; i++) {
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
    if (useSecretSprite) {
      await _loadSecretBossAnimation();
      return;
    }

    final idleImg = await game.images.load('Enemies/AngryPig/Idle (36x30).png');
    final walkImg = await game.images.load('Enemies/AngryPig/Walk (36x30).png');
    final runImg = await game.images.load('Enemies/AngryPig/Run (36x30).png');
    final hitImg = await game.images.load('Enemies/AngryPig/Hit 1 (36x30).png');

    animations = {
      BossState.idle: SpriteAnimation.fromFrameData(
        idleImg,
        SpriteAnimationData.sequenced(
          amount: 9,
          stepTime: stepTime,
          textureSize: Vector2(36, 30),
        ),
      ),
      BossState.run: SpriteAnimation.fromFrameData(
        walkImg,
        SpriteAnimationData.sequenced(
          amount: 16,
          stepTime: stepTime,
          textureSize: Vector2(36, 30),
        ),
      ),
      BossState.attack: SpriteAnimation.fromFrameData(
        runImg,
        SpriteAnimationData.sequenced(
          amount: 12,
          stepTime: stepTime,
          textureSize: Vector2(36, 30),
        ),
      ),
      BossState.charging: SpriteAnimation.fromFrameData(
        idleImg,
        SpriteAnimationData.sequenced(
          amount: 9,
          stepTime: 0.02,
          textureSize: Vector2(36, 30),
        ),
      ),
      BossState.hit: SpriteAnimation.fromFrameData(
        hitImg,
        SpriteAnimationData.sequenced(
          amount: 5,
          stepTime: stepTime,
          textureSize: Vector2(36, 30),
          loop: false,
        ),
      ),
    };
    current = BossState.idle;
  }

  Future<void> _loadSecretBossAnimation() async {
    final bossImg = await game.images.load('Secret/boss.png');

    SpriteAnimation oneFrame() {
      return SpriteAnimation.fromFrameData(
        bossImg,
        SpriteAnimationData.sequenced(
          amount: 1,
          stepTime: 1,
          textureSize: Vector2(
            bossImg.width.toDouble(),
            bossImg.height.toDouble(),
          ),
        ),
      );
    }

    animations = {
      BossState.idle: oneFrame(),
      BossState.run: oneFrame(),
      BossState.attack: oneFrame(),
      BossState.charging: oneFrame(),
      BossState.hit: oneFrame(),
    };
    current = BossState.idle;
  }

  double _lerpDouble(double start, double end, double progress) {
    return start + (end - start) * progress;
  }
}

class SecretBossSkillProjectile extends SpriteComponent
    with HasGameReference<PixelAdventure>, CollisionCallbacks {
  final Vector2 velocity;

  SecretBossSkillProjectile({
    required super.position,
    required super.size,
    required this.velocity,
  });

  double _lifeTime = 0;

  @override
  FutureOr<void> onLoad() {
    sprite = Sprite(game.images.fromCache('Secret/skill.png'));
    add(CircleHitbox());
    return super.onLoad();
  }

  @override
  void update(double dt) {
    position += velocity * dt;
    _lifeTime += dt;

    final outsideMap = position.x < -size.x ||
        position.y < -size.y ||
        position.x > game.currentMapSize.x + size.x ||
        position.y > game.currentMapSize.y + size.y;
    if (_lifeTime > 4 || outsideMap) {
      removeFromParent();
    }

    super.update(dt);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (other is Player) {
      other.collidedwithEnemy();
      removeFromParent();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}
