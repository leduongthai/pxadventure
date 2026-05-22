import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/foundation.dart';
import 'package:pixel_adventure/components/background_tile.dart';
import 'package:pixel_adventure/components/checkpoint.dart';
import 'package:pixel_adventure/components/chicken.dart';
import 'package:pixel_adventure/components/collision_block.dart';
import 'package:pixel_adventure/components/enemies/blue_bird.dart';
import 'package:pixel_adventure/components/enemies/boss_big.dart';
import 'package:pixel_adventure/components/enemies/bunny.dart';
import 'package:pixel_adventure/components/enemies/mushroom.dart';
import 'package:pixel_adventure/components/fruit.dart';
import 'package:pixel_adventure/components/player.dart';
import 'package:pixel_adventure/components/saw.dart';
import 'package:pixel_adventure/components/secret_npc.dart';
import 'package:pixel_adventure/components/traps/falling_platform.dart';
import 'package:pixel_adventure/components/traps/fire.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class Level extends World with HasGameReference<PixelAdventure> {
  final String levelName;
  final Player player;
  Level({required this.levelName, required this.player});
  late TiledComponent level;
  List<CollisionBlock> collisionBlocks = [];
  TiledObject? _finishCheckpoint;
  TiledObject? _secretBossSpawnPoint;
  bool _secretBossSpawned = false;

  @override
  FutureOr<void> onLoad() async {
    level = await TiledComponent.load('$levelName.tmx', Vector2.all(16));
    add(level);
    game.configureCameraBounds(level.size);
    _scrollingBackground();
    _addCollisions();
    _spawningObjects();
    return super.onLoad();
  }

  void _scrollingBackground() {
    final backgroundLayer = level.tileMap.getLayer('Background');
    if (backgroundLayer != null) {
      final backgroundColor =
          backgroundLayer.properties.getValue('BackgroundColor');
      final backgroundTile = BackgroundTile(
        color: backgroundColor ?? 'Gray',
        position: Vector2(0, 0),
      );
      backgroundTile.size =
          level.size; // Đặt kích thước background bằng đúng kích thước map
      add(backgroundTile);
    }
  }

  void _spawningObjects() {
    final spawnPointsLayer = level.tileMap.getLayer<ObjectGroup>('Spawnpoints');
    if (spawnPointsLayer != null) {
      final fruitCount = spawnPointsLayer.objects
          .where((spawnPoint) => spawnPoint.class_ == 'Fruit')
          .length;
      game.scoreManager.setLevelFruitTotal(fruitCount);
      _finishCheckpoint = _findFinishCheckpoint(spawnPointsLayer);

      for (final spawnPoint in spawnPointsLayer.objects) {
        switch (spawnPoint.class_) {
          case 'Player':
            player.position = _adjustSolidPosition(
              Vector2(spawnPoint.x, spawnPoint.y),
              Vector2(spawnPoint.width, spawnPoint.height),
            );
            player.scale.x = 1;
            add(player);
            break;
          case 'Fruit':
            final position = _adjustFruitPosition(
              Vector2(spawnPoint.x, spawnPoint.y),
              Vector2(spawnPoint.width, spawnPoint.height),
            );
            add(Fruit(
              fruit: spawnPoint.name,
              position: position,
              size: Vector2(spawnPoint.width, spawnPoint.height),
            ));
            break;
          case 'Saw':
            final isVertical = spawnPoint.properties.getValue('isVertical');
            final offNeg = spawnPoint.properties.getValue('offNeg');
            final offPos = spawnPoint.properties.getValue('offPos');
            add(Saw(
              isVertical: isVertical,
              offNeg: offNeg,
              offPos: offPos,
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
            ));
            break;
          case 'Checkpoint':
            if (identical(spawnPoint, _finishCheckpoint)) {
              final checkpointSize =
                  Vector2(spawnPoint.width, spawnPoint.height);
              add(Checkpoint(
                position: _adjustCheckpointPosition(
                  Vector2(spawnPoint.x, spawnPoint.y),
                  checkpointSize,
                ),
                size: checkpointSize,
              ));
            }
            break;
          case 'Chicken':
            final offNeg = spawnPoint.properties.getValue('offNeg');
            final offPos = spawnPoint.properties.getValue('offPos');
            add(Chicken(
              position: _adjustSolidPosition(
                Vector2(spawnPoint.x, spawnPoint.y),
                Vector2(spawnPoint.width, spawnPoint.height),
              ),
              size: Vector2(spawnPoint.width, spawnPoint.height),
              offNeg: offNeg,
              offPos: offPos,
            ));
            break;
          case 'Bunny':
            final offNeg = spawnPoint.properties.getValue('offNeg');
            final offPos = spawnPoint.properties.getValue('offPos');
            add(Bunny(
              position: _adjustSolidPosition(
                Vector2(spawnPoint.x, spawnPoint.y),
                Vector2(spawnPoint.width, spawnPoint.height),
              ),
              size: Vector2(spawnPoint.width, spawnPoint.height),
              offNeg: offNeg ?? 0,
              offPos: offPos ?? 0,
            ));
            break;
          case 'BlueBird':
            final offNeg = spawnPoint.properties.getValue('offNeg');
            final offPos = spawnPoint.properties.getValue('offPos');
            add(BlueBird(
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
              offNeg: offNeg ?? 0,
              offPos: offPos ?? 0,
            ));
            break;
          case 'NPC':
            final npc = SecretNpc(
              position: _adjustGroundedPosition(
                Vector2(spawnPoint.x, spawnPoint.y),
                Vector2(spawnPoint.width, spawnPoint.height),
              ),
              size: Vector2(spawnPoint.width, spawnPoint.height),
            );
            add(npc);
            if (game.secretRun) game.registerSecretNpc(npc);
            break;
          case 'Mushroom':
            final offNeg = spawnPoint.properties.getValue('offNeg');
            final offPos = spawnPoint.properties.getValue('offPos');
            add(Mushroom(
              position: _adjustSolidPosition(
                Vector2(spawnPoint.x, spawnPoint.y),
                Vector2(spawnPoint.width, spawnPoint.height),
              ),
              size: Vector2(spawnPoint.width, spawnPoint.height),
              offNeg: offNeg ?? 0,
              offPos: offPos ?? 0,
            ));
            break;
          case 'Boss':
            try {
              final secretVariant =
                  spawnPoint.properties.getValue('imageVariant')?.toString();
              if (game.secretRun && secretVariant == 'secret') {
                _secretBossSpawnPoint = spawnPoint;
                break;
              }
              game.scoreManager.levelHasBoss = true; // Đánh dấu màn này có Boss
              final offNeg = spawnPoint.properties.getValue('offNeg');
              final offPos = spawnPoint.properties.getValue('offPos');
              final imageVariant =
                  spawnPoint.properties.getValue('imageVariant')?.toString();
              add(BossPig(
                position: _adjustGroundedPosition(
                  Vector2(spawnPoint.x, spawnPoint.y),
                  Vector2(spawnPoint.width, spawnPoint.height),
                ),
                size: Vector2(spawnPoint.width, spawnPoint.height),
                offNeg: offNeg is num ? offNeg.toDouble() : 0.0,
                offPos: offPos is num ? offPos.toDouble() : 0.0,
                pattern: _bossPatternFor(spawnPoint),
                useSecretSprite: imageVariant == 'secret',
              ));
            } catch (e) {
              debugPrint('Error loading Boss: $e');
            }
            break;
          case 'FallingPlatform':
            final platformBlock = CollisionBlock(
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
              isPlatform: true,
            );
            collisionBlocks.add(platformBlock);
            add(platformBlock);
            add(FallingPlatform(
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
              collisionBlock: platformBlock,
            ));
            break;
          case 'Fire':
            add(Fire(
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
            ));
            break;
          default:
        }
      }
      player.collisionBlocks = List.unmodifiable(collisionBlocks);
    }
  }

  void summonSecretBoss() {
    if (_secretBossSpawned || _secretBossSpawnPoint == null) return;

    final spawnPoint = _secretBossSpawnPoint!;
    _secretBossSpawned = true;
    game.scoreManager.levelHasBoss = true;
    final offNeg = spawnPoint.properties.getValue('offNeg');
    final offPos = spawnPoint.properties.getValue('offPos');
    final bossSize = Vector2(spawnPoint.width, spawnPoint.height);
    final bossPosition = _adjustGroundedPosition(
      Vector2(spawnPoint.x, spawnPoint.y),
      bossSize,
    );
    _movePlayerAwayFromBossSpawn(bossPosition, bossSize);

    add(BossPig(
      position: bossPosition,
      size: bossSize,
      offNeg: offNeg is num ? offNeg.toDouble() : 0.0,
      offPos: offPos is num ? offPos.toDouble() : 0.0,
      pattern: _bossPatternFor(spawnPoint),
      useSecretSprite: true,
    ));
  }

  void _movePlayerAwayFromBossSpawn(Vector2 bossPosition, Vector2 bossSize) {
    final playerBox = Rect.fromLTWH(
      player.position.x,
      player.position.y,
      player.width,
      player.height,
    );
    final dangerBox = Rect.fromLTWH(
      bossPosition.x - 32,
      bossPosition.y - 16,
      bossSize.x + 64,
      bossSize.y + 32,
    );

    if (!playerBox.overlaps(dangerBox)) return;

    final safeX = (bossPosition.x - player.width - 48)
        .clamp(0, level.size.x - player.width)
        .toDouble();
    player.position.x = safeX;
    player.velocity = Vector2.zero();
    player.horizontalMovement = 0;
  }

  TiledObject? _findFinishCheckpoint(ObjectGroup spawnPointsLayer) {
    final checkpoints = spawnPointsLayer.objects
        .where((spawnPoint) => spawnPoint.class_ == 'Checkpoint')
        .toList();
    if (checkpoints.isEmpty) return null;
    checkpoints.sort((a, b) => a.x.compareTo(b.x));
    return checkpoints.last;
  }

  BossPattern _bossPatternFor(TiledObject spawnPoint) {
    final patternValue =
        spawnPoint.properties.getValue('pattern')?.toString().toLowerCase();

    if (patternValue == 'stomper' || patternValue == 'leaper') {
      return BossPattern.stomper;
    }
    if (patternValue == 'charger') return BossPattern.charger;

    final currentLevelNumber = game.currentLevelIndex + 1;
    return currentLevelNumber >= 10 ? BossPattern.stomper : BossPattern.charger;
  }

  Vector2 _adjustFruitPosition(
    Vector2 position,
    Vector2 size,
  ) {
    final adjusted = position.clone();

    for (var pass = 0; pass < 4; pass++) {
      var moved = false;
      for (final block in collisionBlocks) {
        final overlaps = adjusted.x < block.x + block.width &&
            adjusted.x + size.x > block.x &&
            adjusted.y < block.y + block.height &&
            adjusted.y + size.y > block.y;

        if (overlaps) {
          adjusted.y = block.y - size.y - 2;
          moved = true;
        }
      }
      if (!moved) break;
    }

    if (_finishCheckpoint != null) {
      final checkpoint = _finishCheckpoint!;
      final nearFinish = adjusted.x < checkpoint.x + checkpoint.width + 24 &&
          adjusted.x + size.x > checkpoint.x - 24 &&
          adjusted.y < checkpoint.y + checkpoint.height + 24 &&
          adjusted.y + size.y > checkpoint.y - 24;

      if (nearFinish) {
        adjusted.x = checkpoint.x - size.x - 48;
        adjusted.y = checkpoint.y - size.y - 8;
      }
    }

    return adjusted;
  }

  Vector2 _adjustSolidPosition(Vector2 position, Vector2 size) {
    final adjusted = position.clone();

    for (var pass = 0; pass < 6; pass++) {
      var moved = false;
      for (final block in collisionBlocks) {
        final overlaps = adjusted.x < block.x + block.width &&
            adjusted.x + size.x > block.x &&
            adjusted.y < block.y + block.height &&
            adjusted.y + size.y > block.y;

        if (overlaps) {
          adjusted.y = block.y - size.y;
          moved = true;
        }
      }
      if (!moved) break;
    }

    return adjusted;
  }

  Vector2 _adjustGroundedPosition(Vector2 position, Vector2 size) {
    final adjusted = _adjustSolidPosition(position, size);
    final bottom = adjusted.y + size.y;
    double? closestGroundTop;

    for (final block in collisionBlocks) {
      final horizontallyOverlaps =
          adjusted.x < block.x + block.width && adjusted.x + size.x > block.x;
      final groundIsBelow = block.y >= bottom - 2 && block.y <= bottom + 56;

      if (horizontallyOverlaps && groundIsBelow) {
        if (closestGroundTop == null || block.y < closestGroundTop) {
          closestGroundTop = block.y;
        }
      }
    }

    if (closestGroundTop != null) {
      adjusted.y = closestGroundTop - size.y;
    }

    final maxX = (level.size.x - size.x).clamp(0, double.infinity);
    final maxY = (level.size.y - size.y).clamp(0, double.infinity);
    adjusted.x = adjusted.x.clamp(0, maxX).toDouble();
    adjusted.y = adjusted.y.clamp(0, maxY).toDouble();

    return _adjustSolidPosition(adjusted, size);
  }

  Vector2 _adjustCheckpointPosition(Vector2 position, Vector2 size) {
    final adjusted = position.clone();
    final bottom = position.y + size.y;
    double? closestGroundTop;

    for (final block in collisionBlocks) {
      final horizontallyOverlaps =
          adjusted.x < block.x + block.width && adjusted.x + size.x > block.x;
      final groundTopInsideSprite = block.y >= adjusted.y && block.y <= bottom;

      if (horizontallyOverlaps && groundTopInsideSprite) {
        if (closestGroundTop == null || block.y < closestGroundTop) {
          closestGroundTop = block.y;
        }
      }
    }

    if (closestGroundTop != null) {
      adjusted.y = closestGroundTop - size.y;
    }

    return adjusted;
  }

  void _addCollisions() {
    final tileCollisionCount = _addTileCollisions();
    if (tileCollisionCount > 0) {
      return;
    }

    _addObjectCollisions();
  }

  int _addTileCollisions() {
    var collisionCount = 0;
    final terrainLayer = level.tileMap.getLayer<TileLayer>('Background');
    if (terrainLayer != null && terrainLayer.data != null) {
      final data = terrainLayer.data!;
      final tileWidth = level.tileMap.map.tileWidth.toDouble();
      final tileHeight = level.tileMap.map.tileHeight.toDouble();

      for (var y = 0; y < terrainLayer.height; y++) {
        var runStart = -1;
        var runIsPlatform = false;
        for (var x = 0; x <= terrainLayer.width; x++) {
          final gid =
              x < terrainLayer.width ? data[(y * terrainLayer.width) + x] : 0;
          final isSolid = _isSolidTile(gid);
          final isPlatform = _isOneWayPlatformTile(gid);

          if (isSolid && runStart == -1) {
            runStart = x;
            runIsPlatform = isPlatform;
          } else if ((!isSolid || isPlatform != runIsPlatform) &&
              runStart != -1) {
            final block = CollisionBlock(
              position: Vector2(runStart * tileWidth, y * tileHeight),
              size: Vector2((x - runStart) * tileWidth, tileHeight),
              isPlatform: runIsPlatform,
            );
            collisionBlocks.add(block);
            add(block);
            collisionCount++;
            runStart = isSolid ? x : -1;
            runIsPlatform = isPlatform;
          }
        }
      }
    }
    return collisionCount;
  }

  void _addObjectCollisions() {
    final collisionsLayer = level.tileMap.getLayer<ObjectGroup>('Collisions');
    if (collisionsLayer == null) return;

    for (final object in collisionsLayer.objects) {
      final block = CollisionBlock(
        position: Vector2(object.x, object.y),
        size: Vector2(object.width, object.height),
        isPlatform: object.class_ == 'Platform',
      );
      collisionBlocks.add(block);
      add(block);
    }
  }

  bool _isSolidTile(int gid) {
    return gid != 0 && gid != 24;
  }

  bool _isOneWayPlatformTile(int gid) {
    return gid == 13 ||
        gid == 14 ||
        gid == 15 ||
        gid == 40 ||
        gid == 41 ||
        gid == 42;
  }
}
