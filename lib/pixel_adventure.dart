import 'dart:async';
import 'dart:io' show Platform;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/painting.dart';
import 'package:pixel_adventure/components/hud/game_hud.dart';
import 'package:pixel_adventure/components/jump_button.dart';
import 'package:pixel_adventure/components/level.dart';
import 'package:pixel_adventure/components/player.dart';
import 'package:pixel_adventure/managers/save_manager.dart';
import 'package:pixel_adventure/managers/score_manager.dart';

class PixelAdventure extends FlameGame
    with
        HasKeyboardHandlerComponents,
        DragCallbacks,
        HasCollisionDetection,
        TapCallbacks {
  @override
  Color backgroundColor() => const Color(0xFF211F30);

  late CameraComponent cam;
  late Player player;
  late JoystickComponent joystick;
  bool showControls = false;
  bool playSounds = true;
  double soundVolume = 1.0;

  final List<String> levelNames = [
    'Level-01',
    'Level-02',
    'Level-03',
    'Level-04',
    'Level-05',
  ];
  int currentLevelIndex = 0;

  final ScoreManager scoreManager = ScoreManager.instance;

  bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  PixelAdventure({int initialLevelIndex = 0}) {
    currentLevelIndex = initialLevelIndex;
  }

  @override
  FutureOr<void> onLoad() async {
    await images.loadAllImages();

    playSounds = SaveManager.instance.isSoundEnabled();
    final character = SaveManager.instance.getSelectedCharacter();
    player = Player(character: character);

    showControls = isMobile;

    _loadLevel();

    if (showControls) {
      _addMobileControls();
    }

    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (showControls) updateJoystick();
    super.update(dt);
  }

  void _addMobileControls() {
    joystick = JoystickComponent(
      priority: 10,
      knob: SpriteComponent(sprite: Sprite(images.fromCache('HUD/Knob.png'))),
      background: SpriteComponent(sprite: Sprite(images.fromCache('HUD/Joystick.png'))),
      margin: const EdgeInsets.only(left: 32, bottom: 64),
    );
    add(joystick);
    add(JumpButton());
  }

  void updateJoystick() {
    switch (joystick.direction) {
      case JoystickDirection.left:
      case JoystickDirection.upLeft:
      case JoystickDirection.downLeft:
        player.horizontalMovement = -1;
        break;
      case JoystickDirection.right:
      case JoystickDirection.upRight:
      case JoystickDirection.downRight:
        player.horizontalMovement = 1;
        break;
      default:
        player.horizontalMovement = 0;
        break;
    }
  }

  void loadNextLevel() async {
    await scoreManager.saveHighScore(currentLevelIndex + 1, scoreManager.currentScore);
    await SaveManager.instance.unlockNextLevel(currentLevelIndex + 1);
    await SaveManager.instance.addLeaderboardEntry(
      SaveManager.instance.getPlayerName(),
      scoreManager.currentScore,
      currentLevelIndex + 1,
    );

    if (currentLevelIndex < levelNames.length - 1) {
      currentLevelIndex++;
      scoreManager.reset();
      _reloadLevel();
    } else {
      overlays.add('LevelComplete');
    }
  }

  void resetCurrentLevel() {
    scoreManager.reset();
    final character = SaveManager.instance.getSelectedCharacter();
    player = Player(character: character);
    _reloadLevel();
  }

  void _reloadLevel() {
    // Remove old world and camera
    removeWhere((component) => component is Level || component is CameraComponent);

    Future.delayed(const Duration(milliseconds: 500), () {
      _buildLevel();
    });
  }

  void _loadLevel() {
    Future.delayed(const Duration(seconds: 1), () {
      _buildLevel();
    });
  }

  void _buildLevel() {
    final world = Level(
      player: player,
      levelName: levelNames[currentLevelIndex],
    );

    cam = CameraComponent.withFixedResolution(world: world, width: 640, height: 360);
    cam.viewfinder.anchor = Anchor.topLeft;

    final hud = GameHUD();
    cam.viewport.add(hud);

    addAll([cam, world]);
  }
}
