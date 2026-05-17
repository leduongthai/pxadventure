import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart' as flame_geometry;
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, ValueNotifier, defaultTargetPlatform, kIsWeb;
import 'package:flutter/painting.dart';
import 'package:pixel_adventure/components/hud/game_hud.dart';
import 'package:pixel_adventure/components/jump_button.dart';
import 'package:pixel_adventure/components/level.dart';
import 'package:pixel_adventure/components/player.dart';
import 'package:pixel_adventure/managers/achievement_manager.dart';
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
  final ValueNotifier<double> transitionOpacity = ValueNotifier(0);
  Vector2 currentMapSize = Vector2.zero();
  bool _levelCompleteVisible = false;
  bool _pauseMenuVisible = false;
  bool _gameOverVisible = false;

  final List<String> levelNames = [
    'Level-01',
    'Level-02',
    'Level-03',
    'Level-04',
    'Level-05',
    'Level-06',
    'Level-07',
    'Level-08',
    'Level-09',
    'Level-10',
    'Level-11',
  ];
  int currentLevelIndex = 0;
  bool get isLastLevel => currentLevelIndex >= levelNames.length - 1;

  final ScoreManager scoreManager = ScoreManager.instance;

  bool get isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

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
      background:
          SpriteComponent(sprite: Sprite(images.fromCache('HUD/Joystick.png'))),
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

  Future<void> loadNextLevel() async {
    if (_levelCompleteVisible) return;

    final completedLevel = currentLevelIndex + 1;
    final earnedStars = scoreManager.calculateStars();

    await scoreManager.saveHighScore(completedLevel, scoreManager.currentScore);
    await scoreManager.saveBestStars(completedLevel, earnedStars);
    await SaveManager.instance.unlockNextLevel(completedLevel);
    await SaveManager.instance.addLeaderboardEntry(
      SaveManager.instance.getPlayerName(),
      scoreManager.currentScore,
      completedLevel,
    );
    await AchievementManager.instance.recordLevelComplete(
      completedLevel: completedLevel,
      deathCount: scoreManager.deathCount,
      score: scoreManager.currentScore,
      unlockedLevels: SaveManager.instance.getUnlockedLevels(),
    );

    _levelCompleteVisible = true;
    overlays.add('LevelComplete');
    pauseEngine();
  }

  Future<void> continueToNextLevel() async {
    if (isLastLevel) return;

    dismissLevelComplete();
    await _fadeTransition(to: 1);
    currentLevelIndex++;
    scoreManager.reset();
    await _reloadLevel(delay: Duration.zero);
    await Future.delayed(const Duration(milliseconds: 200));
    await _fadeTransition(to: 0);
  }

  void resetCurrentLevel() {
    _levelCompleteVisible = false;
    _pauseMenuVisible = false;
    _gameOverVisible = false;
    overlays.remove('LevelComplete');
    overlays.remove('PauseMenu');
    overlays.remove('GameOver');
    resumeEngine();
    scoreManager.reset();
    final character = SaveManager.instance.getSelectedCharacter();
    player = Player(character: character);
    _reloadLevel();
  }

  void showPauseMenu() {
    if (_pauseMenuVisible || _levelCompleteVisible || _gameOverVisible) return;

    _pauseMenuVisible = true;
    overlays.add('PauseMenu');
    pauseEngine();
  }

  void dismissPauseMenu() {
    if (_pauseMenuVisible) {
      overlays.remove('PauseMenu');
      _pauseMenuVisible = false;
    }
    resumeEngine();
  }

  void showGameOver() {
    if (_gameOverVisible) return;

    _gameOverVisible = true;
    overlays.add('GameOver');
    pauseEngine();
  }

  void dismissGameOver() {
    if (_gameOverVisible) {
      overlays.remove('GameOver');
      _gameOverVisible = false;
    }
    resumeEngine();
  }

  void dismissLevelComplete() {
    if (_levelCompleteVisible) {
      overlays.remove('LevelComplete');
      _levelCompleteVisible = false;
    }
    resumeEngine();
  }

  Future<void> _reloadLevel(
      {Duration delay = const Duration(milliseconds: 500)}) async {
    // Remove old world and camera
    removeWhere(
        (component) => component is Level || component is CameraComponent);

    await Future.delayed(delay);
    _buildLevel();
  }

  void _loadLevel() {
    Future.delayed(const Duration(seconds: 1), () {
      _buildLevel();
    });
  }

  void _buildLevel() {
    final character = SaveManager.instance.getSelectedCharacter();
    player = Player(character: character);

    final world = Level(
      player: player,
      levelName: levelNames[currentLevelIndex],
    );

    cam = CameraComponent.withFixedResolution(
        world: world, width: 640, height: 360);
    cam.follow(player, snap: true);

    final hud = GameHUD();
    cam.viewport.add(hud);

    addAll([cam, world]);
  }

  void configureCameraBounds(Vector2 mapSize) {
    currentMapSize = mapSize;
    cam.setBounds(
      flame_geometry.Rectangle.fromLTWH(0, 0, mapSize.x, mapSize.y),
      considerViewport: true,
    );
  }

  Future<void> _fadeTransition({required double to}) async {
    const duration = Duration(milliseconds: 450);
    const frame = Duration(milliseconds: 16);
    final from = transitionOpacity.value;
    final steps = (duration.inMilliseconds / frame.inMilliseconds).ceil();

    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      transitionOpacity.value = from + (to - from) * t;
      await Future.delayed(frame);
    }
    transitionOpacity.value = to;
  }
}
