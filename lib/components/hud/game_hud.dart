import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:pixel_adventure/managers/score_manager.dart';
import 'package:pixel_adventure/pixel_adventure.dart';
import 'package:flutter/material.dart';

class GameHUD extends PositionComponent with HasGameRef<PixelAdventure> {
  late TextComponent _scoreText;
  late TextComponent _levelText;
  late TextComponent _deathText;

  // Camera fixed resolution width is 640
  static const double _camWidth = 640;

  GameHUD() : super(priority: 10);

  @override
  Future<void> onLoad() async {
    const style = TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold);
    final renderer = TextPaint(style: style);

    _scoreText = TextComponent(text: 'Score: 0', textRenderer: renderer, position: Vector2(8, 8));
    _levelText = TextComponent(text: 'Level: 1', textRenderer: renderer, position: Vector2(8, 28));
    _deathText = TextComponent(text: '💀 0', textRenderer: renderer, position: Vector2(8, 48));

    final pauseBtn = _PauseButton(position: Vector2(_camWidth - 40, 8));

    addAll([_scoreText, _levelText, _deathText, pauseBtn]);
    return super.onLoad();
  }

  @override
  void update(double dt) {
    _scoreText.text = 'Score: ${ScoreManager.instance.currentScore}';
    _deathText.text = '💀 ${ScoreManager.instance.deathCount}';
    _levelText.text = 'Level: ${game.currentLevelIndex + 1}';
    super.update(dt);
  }
}

class _PauseButton extends PositionComponent
    with HasGameRef<PixelAdventure>, TapCallbacks {
  _PauseButton({super.position}) : super(size: Vector2(32, 32));

  @override
  Future<void> onLoad() async {
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0x885B4EC8),
    ));
    add(TextComponent(
      text: '⏸',
      textRenderer: TextPaint(style: const TextStyle(fontSize: 18)),
      position: Vector2(4, 4),
    ));
    return super.onLoad();
  }

  @override
  void onTapDown(TapDownEvent event) {
    game.overlays.add('PauseMenu');
  }
}
