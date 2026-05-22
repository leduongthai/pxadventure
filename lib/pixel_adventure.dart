import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart' as flame_geometry;
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/foundation.dart'
    show
        TargetPlatform,
        ValueNotifier,
        VoidCallback,
        defaultTargetPlatform,
        kIsWeb;
import 'package:flutter/painting.dart';
import 'package:pixel_adventure/components/hud/game_hud.dart';
import 'package:pixel_adventure/components/jump_button.dart';
import 'package:pixel_adventure/components/level.dart';
import 'package:pixel_adventure/components/player.dart';
import 'package:pixel_adventure/components/secret_npc.dart';
import 'package:pixel_adventure/managers/achievement_manager.dart';
import 'package:pixel_adventure/managers/save_manager.dart';
import 'package:pixel_adventure/managers/score_manager.dart';
import 'package:pixel_adventure/services/leaderboard_service.dart';

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
  bool _secretDialogueVisible = false;
  bool _secretBossSummoned = false;
  int lastSkillPointsEarned = 0;
  final bool secretRun;
  final VoidCallback? requestGameFocus;

  List<String> get levelNames => secretRun
      ? const ['Level-Secret']
      : const [
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
  int get displayedLevelNumber =>
      secretRun ? SaveManager.maxLevels + 1 : currentLevelIndex + 1;
  bool get isLastLevel => currentLevelIndex >= levelNames.length - 1;

  final ScoreManager scoreManager = ScoreManager.instance;
  Level? _activeLevel;
  SecretNpc? _secretNpc;

  bool get isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  PixelAdventure({
    int initialLevelIndex = 0,
    this.secretRun = false,
    this.requestGameFocus,
  }) {
    currentLevelIndex = secretRun ? 0 : initialLevelIndex;
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
    if (secretRun) {
      lastSkillPointsEarned = 0;
    } else {
      final previousBestStars = await scoreManager.getBestStars(completedLevel);
      final newSkillPoints = earnedStars - previousBestStars;
      lastSkillPointsEarned = newSkillPoints > 0 ? newSkillPoints : 0;
    }

    if (!secretRun) {
      await scoreManager.saveHighScore(
        completedLevel,
        scoreManager.currentScore,
      );
      await scoreManager.saveBestStars(completedLevel, earnedStars);
      await SaveManager.instance.unlockNextLevel(completedLevel);
      await LeaderboardService.instance.addLeaderboardEntry(
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
    }

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
    _secretDialogueVisible = false;
    _secretBossSummoned = false;
    overlays.remove('LevelComplete');
    overlays.remove('PauseMenu');
    overlays.remove('GameOver');
    overlays.remove('SecretDialogue');
    resumeEngine();
    requestGameFocus?.call();
    scoreManager.reset();
    lastSkillPointsEarned = 0;
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
    requestGameFocus?.call();
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
    requestGameFocus?.call();
  }

  void showSecretDialogue() {
    if (!secretRun || _secretDialogueVisible || _secretBossSummoned) return;
    if (_levelCompleteVisible || _pauseMenuVisible || _gameOverVisible) return;

    _secretDialogueVisible = true;
    overlays.add('SecretDialogue');
    pauseEngine();
  }

  void resolveSecretDialogue({required bool passed}) {
    if (!_secretDialogueVisible) return;

    overlays.remove('SecretDialogue');
    _secretDialogueVisible = false;

    if (passed) {
      unawaited(loadNextLevel());
      return;
    }

    _secretBossSummoned = true;
    _secretNpc?.removeFromParent();
    _secretNpc = null;
    _activeLevel?.summonSecretBoss();
    resumeEngine();
    requestGameFocus?.call();
  }

  void registerSecretNpc(SecretNpc npc) {
    _secretNpc = npc;
  }

  bool get canInteractSecretNpc {
    final npc = _secretNpc;
    return secretRun &&
        npc != null &&
        !_secretDialogueVisible &&
        !_secretBossSummoned &&
        !_levelCompleteVisible &&
        !_pauseMenuVisible &&
        !_gameOverVisible &&
        npc.isPlayerNear(player);
  }

  void tryInteractSecretNpc() {
    if (!canInteractSecretNpc) return;
    showSecretDialogue();
  }

  void dismissLevelComplete() {
    if (_levelCompleteVisible) {
      overlays.remove('LevelComplete');
      _levelCompleteVisible = false;
    }
    lastSkillPointsEarned = 0;
    resumeEngine();
    requestGameFocus?.call();
  }

  Future<void> _reloadLevel(
      {Duration delay = const Duration(milliseconds: 500)}) async {
    // Remove old world and camera
    removeWhere(
        (component) => component is Level || component is CameraComponent);
    _activeLevel = null;
    _secretNpc = null;

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
    _secretNpc = null;

    final world = Level(
      player: player,
      levelName: levelNames[currentLevelIndex],
    );
    _activeLevel = world;

    cam = CameraComponent.withFixedResolution(
        world: world, width: 640, height: 360);
    cam.follow(player, snap: true);

    final hud = GameHUD();
    cam.viewport.add(hud);

    addAll([cam, world]);
    requestGameFocus?.call();
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
