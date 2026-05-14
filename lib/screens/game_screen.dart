import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/managers/achievement_manager.dart';
import 'package:pixel_adventure/pixel_adventure.dart';
import 'package:pixel_adventure/screens/achievements_screen.dart';
import 'package:pixel_adventure/widgets/game_over_widget.dart';
import 'package:pixel_adventure/widgets/level_complete_widget.dart';
import 'package:pixel_adventure/widgets/pause_menu_widget.dart';

class GameScreen extends StatefulWidget {
  final int initialLevelIndex;

  const GameScreen({super.key, this.initialLevelIndex = 0});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late PixelAdventure _game;
  Achievement? _newAchievement;

  @override
  void initState() {
    super.initState();
    _game = PixelAdventure(initialLevelIndex: widget.initialLevelIndex);

    // Lắng nghe achievement mới unlock trong khi chơi
    AchievementManager.instance.onUnlock = (achievement) {
      if (mounted) {
        setState(() => _newAchievement = achievement);
        // Tự xóa toast sau 4s
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) setState(() => _newAchievement = null);
        });
      }
    };
  }

  @override
  void dispose() {
    AchievementManager.instance.onUnlock = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(
            game: _game,
            overlayBuilderMap: {
              'PauseMenu': (context, game) =>
                  PauseMenuWidget(game: game as PixelAdventure),
              'GameOver': (context, game) =>
                  GameOverWidget(game: game as PixelAdventure),
              'LevelComplete': (context, game) =>
                  LevelCompleteWidget(game: game as PixelAdventure),
            },
          ),
          ValueListenableBuilder<double>(
            valueListenable: _game.transitionOpacity,
            builder: (context, opacity, child) {
              if (opacity <= 0) return const SizedBox.shrink();
              return IgnorePointer(
                child: Opacity(
                  opacity: opacity.clamp(0, 1),
                  child: child,
                ),
              );
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Colors.black),
                Image.asset(
                  'assets/images/Other/Transition.png',
                  fit: BoxFit.cover,
                  repeat: ImageRepeat.repeat,
                ),
              ],
            ),
          ),
          // Achievement toast overlay
          if (_newAchievement != null)
            AchievementToast(
              key: ValueKey(_newAchievement!.id),
              achievement: _newAchievement!,
            ),
        ],
      ),
    );
  }
}

