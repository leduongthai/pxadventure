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
              style: TextStyle(color: Color(0xFFFFD700), fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text('Điểm: $score', style: const TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 4),
            Text('Trái cây: $fruits 🍎', style: const TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 24),
            _Btn(
              label: 'LEVEL TIẾP',
              color: const Color(0xFF5B4EC8),
              onTap: () {
                game.overlays.remove('LevelComplete');
                game.loadNextLevel();
              },
            ),
            const SizedBox(height: 12),
            _Btn(
              label: 'VỀ MENU',
              color: Colors.grey.shade700,
              onTap: () {
                game.overlays.remove('LevelComplete');
                Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
              },
            ),
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
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
