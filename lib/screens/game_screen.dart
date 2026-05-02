import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/pixel_adventure.dart';
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

  @override
  void initState() {
    super.initState();
    _game = PixelAdventure(initialLevelIndex: widget.initialLevelIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
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
    );
  }
}
