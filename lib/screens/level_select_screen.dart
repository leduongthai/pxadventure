import 'package:flutter/material.dart';
import 'package:pixel_adventure/managers/save_manager.dart';
import 'package:pixel_adventure/managers/score_manager.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  static const int _totalLevels = 5;
  int _unlockedLevels = 1;
  final Map<int, int> _highScores = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _unlockedLevels = SaveManager.instance.getUnlockedLevels();
    for (int i = 1; i <= _totalLevels; i++) {
      _highScores[i] = await ScoreManager.instance.getHighScore(i);
    }
    if (mounted) setState(() {});
  }

  void _startLevel(int level) {
    Navigator.pushNamed(
      context,
      '/game',
      arguments: {'levelIndex': level - 1},
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF211F30),
      appBar: AppBar(
        backgroundColor: const Color(0xFF211F30),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'CHỌN LEVEL',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: _totalLevels,
          itemBuilder: (context, index) {
            final level = index + 1;
            final unlocked = level <= _unlockedLevels;
            final highScore = _highScores[level] ?? 0;

            return GestureDetector(
              onTap: unlocked ? () => _startLevel(level) : null,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2C45),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: unlocked ? const Color(0xFF5B4EC8) : const Color(0xFF444444),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!unlocked)
                      const Icon(Icons.lock, color: Colors.white38, size: 32)
                    else
                      Text(
                        '$level',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Level $level',
                      style: TextStyle(
                        color: unlocked ? Colors.white70 : Colors.white24,
                        fontSize: 12,
                      ),
                    ),
                    if (unlocked && highScore > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '★ $highScore',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
