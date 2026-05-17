import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:pixel_adventure/components/background_tile.dart';
import 'package:pixel_adventure/components/checkpoint.dart';
import 'package:pixel_adventure/components/chicken.dart';
import 'package:pixel_adventure/components/collision_block.dart';
import 'package:pixel_adventure/components/enemies/blue_bird.dart';
import 'package:pixel_adventure/components/enemies/bunny.dart';
import 'package:pixel_adventure/components/enemies/mushroom.dart';
import 'package:pixel_adventure/components/fruit.dart';
import 'package:pixel_adventure/components/player.dart';
import 'package:pixel_adventure/components/saw.dart';
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
          color: backgroundColor ?? 'Gray', position: Vector2(0, 0));
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

  TiledObject? _findFinishCheckpoint(ObjectGroup spawnPointsLayer) {
    final checkpoints = spawnPointsLayer.objects
        .where((spawnPoint) => spawnPoint.class_ == 'Checkpoint')
        .toList();
    if (checkpoints.isEmpty) return null;
    checkpoints.sort((a, b) => a.x.compareTo(b.x));
    return checkpoints.last;
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
