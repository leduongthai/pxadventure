import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/components/player.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class SecretNpc extends SpriteComponent
    with HasGameReference<PixelAdventure>, TapCallbacks {
  SecretNpc({super.position, super.size});

  static const double _interactionDistance = 82;
  late final TextComponent _prompt;

  @override
  FutureOr<void> onLoad() {
    sprite = Sprite(game.images.fromCache('Secret/npc.png'));
    _prompt = TextComponent(
      text: 'E',
      anchor: Anchor.center,
      position: Vector2(size.x / 2, -8),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    _prompt.text = '';
    add(_prompt);
    return super.onLoad();
  }

  @override
  void update(double dt) {
    _prompt.text = game.canInteractSecretNpc ? 'E' : '';
    super.update(dt);
  }

  @override
  void onTapDown(TapDownEvent event) {
    game.tryInteractSecretNpc();
    super.onTapDown(event);
  }

  bool isPlayerNear(Player player) {
    return player.absoluteCenter.distanceTo(absoluteCenter) <=
        _interactionDistance;
  }
}
