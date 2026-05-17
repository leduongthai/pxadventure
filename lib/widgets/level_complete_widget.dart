import 'package:flutter/material.dart';
import 'package:pixel_adventure/managers/score_manager.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class LevelCompleteWidget extends StatelessWidget {
  final PixelAdventure game;

  const LevelCompleteWidget({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final score = ScoreManager.instance.currentScore;
    final fruits = ScoreManager.instance.totalFruitCollected;
    final totalFruits = ScoreManager.instance.totalFruitsInLevel;
    final deaths = ScoreManager.instance.deathCount;
    final stars = ScoreManager.instance.calculateStars();
    final isLastLevel = game.isLastLevel;

    return Center(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF211F30),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFD700), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'LEVEL HOÀN THÀNH!',
              style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text('Điểm: $score',
                style: const TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 4),
            Text('Trái cây: $fruits/$totalFruits 🍎',
                style: const TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 4),
            Text('Số lần chết: $deaths',
                style: const TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 12),
            Text(
              '★' * stars + '☆' * (3 - stars),
              style: const TextStyle(
                  color: Color(0xFFFFD700), fontSize: 26, letterSpacing: 2),
            ),
            const SizedBox(height: 6),
            const Text(
              '1★ qua màn • 2★ thu 50% trái cây • 3★ thu đủ và không chết',
              style: TextStyle(color: Colors.white54, fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _Btn(
              label: isLastLevel ? 'VỀ MENU' : 'LEVEL TIẾP',
              color: const Color(0xFF5B4EC8),
              onTap: () {
                if (isLastLevel) {
                  game.dismissLevelComplete();
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/', (r) => false);
                } else {
                  game.continueToNextLevel();
                }
              },
            ),
            if (!isLastLevel) ...[
              const SizedBox(height: 12),
              _Btn(
                label: 'VỀ MENU',
                color: Colors.grey.shade700,
                onTap: () {
                  game.dismissLevelComplete();
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/', (r) => false);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _Btn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 44,
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        alignment: Alignment.center,
        child: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}
