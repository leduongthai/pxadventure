import 'package:flutter/material.dart';
import 'package:pixel_adventure/managers/save_manager.dart';
import 'package:pixel_adventure/managers/score_manager.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  static const int _totalLevels = 11;
  int _unlockedLevels = 1;
  final Map<int, int> _highScores = {};
  final Map<int, int> _stars = {};

  static const List<String> _levelTitles = [
    'Khởi Đầu',
    'Leo Thang',
    'Rừng Tối',
    'Hang Động',
    'Bầu Trời',
    'Núi Lửa',
    'Băng Tuyết',
    'Đầm Lầy',
    'Tháp Cao',
    'Vực Thẳm',
    'Đỉnh Cao',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _unlockedLevels = SaveManager.instance.getUnlockedLevels();
    for (int i = 1; i <= _totalLevels; i++) {
      _highScores[i] = await ScoreManager.instance.getHighScore(i);
      _stars[i] = await ScoreManager.instance.getBestStars(i);
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
    final completed = _unlockedLevels - 1;
    return Scaffold(
      backgroundColor: const Color(0xFF211F30),
      appBar: AppBar(
        backgroundColor: const Color(0xFF211F30),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'CHỌN LEVEL',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$completed/$_totalLevels',
                style: const TextStyle(color: Color(0xFFFFD700), fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: completed / _totalLevels,
                backgroundColor: const Color(0xFF2E2C45),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5B4EC8)),
                minHeight: 6,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                itemCount: _totalLevels,
                itemBuilder: (context, index) {
                  final level = index + 1;
                  final unlocked = level <= _unlockedLevels;
                  final highScore = _highScores[level] ?? 0;
                  final stars = _stars[level] ?? 0;
                  final title = _levelTitles[index];

                  return GestureDetector(
                    onTap: unlocked ? () => _startLevel(level) : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: unlocked ? const Color(0xFF2E2C45) : const Color(0xFF1E1C2E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: unlocked
                              ? (stars > 0 ? const Color(0xFFFFD700) : const Color(0xFF5B4EC8))
                              : const Color(0xFF333345),
                          width: 2,
                        ),
                        boxShadow: unlocked
                            ? [BoxShadow(color: const Color(0xFF5B4EC8).withAlpha(60), blurRadius: 8, offset: const Offset(0, 4))]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!unlocked)
                            const Icon(Icons.lock_outline, color: Colors.white24, size: 28)
                          else
                            Text(
                              '$level',
                              style: TextStyle(
                                color: stars > 0 ? const Color(0xFFFFD700) : Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            style: TextStyle(
                              color: unlocked ? Colors.white60 : Colors.white12,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                          ),
                          if (unlocked && stars > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '★' * stars + '☆' * (3 - stars),
                                  style: const TextStyle(color: Color(0xFFFFD700), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$highScore',
                              style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
