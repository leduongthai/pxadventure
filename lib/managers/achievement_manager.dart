import 'package:shared_preferences/shared_preferences.dart';

enum AchievementId {
  firstBlood,      // Chết lần đầu
  fruitCollector,  // Thu 10 trái cây
  fruitMaster,     // Thu 50 trái cây
  speedRunner,     // Hoàn thành level không chết
  explorer,        // Mở khóa 5 màn
  veteran,         // Mở khóa tất cả màn
  killer,          // Tiêu diệt 10 kẻ thù
  highScorer,      // Đạt 500 điểm 1 màn
  checkpoint,      // Dùng checkpoint lần đầu
  completeGame,    // Hoàn thành tất cả 11 màn
}

class Achievement {
  final AchievementId id;
  final String title;
  final String description;
  final String emoji;
  bool unlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    this.unlocked = false,
  });
}

class AchievementManager {
  AchievementManager._internal();
  static final AchievementManager instance = AchievementManager._internal();

  static const _prefix = 'achievement_';

  final List<Achievement> achievements = [
    Achievement(
      id: AchievementId.firstBlood,
      title: 'Lần Đầu Ngã',
      description: 'Chết lần đầu tiên',
      emoji: '💀',
    ),
    Achievement(
      id: AchievementId.fruitCollector,
      title: 'Hái Lượm',
      description: 'Thu thập 10 trái cây',
      emoji: '🍎',
    ),
    Achievement(
      id: AchievementId.fruitMaster,
      title: 'Bậc Thầy Hái Quả',
      description: 'Thu thập 50 trái cây',
      emoji: '🍑',
    ),
    Achievement(
      id: AchievementId.speedRunner,
      title: 'Tốc Biến',
      description: 'Hoàn thành một màn mà không chết',
      emoji: '⚡',
    ),
    Achievement(
      id: AchievementId.explorer,
      title: 'Nhà Thám Hiểm',
      description: 'Mở khóa 5 màn',
      emoji: '🗺️',
    ),
    Achievement(
      id: AchievementId.veteran,
      title: 'Chiến Binh',
      description: 'Mở khóa tất cả 11 màn',
      emoji: '🏆',
    ),
    Achievement(
      id: AchievementId.killer,
      title: 'Kẻ Tiêu Diệt',
      description: 'Tiêu diệt 10 kẻ thù',
      emoji: '⚔️',
    ),
    Achievement(
      id: AchievementId.highScorer,
      title: 'Điểm Cao Thủ',
      description: 'Đạt 500 điểm trong một màn',
      emoji: '🌟',
    ),
    Achievement(
      id: AchievementId.checkpoint,
      title: 'Điểm Dừng Chân',
      description: 'Kích hoạt checkpoint lần đầu',
      emoji: '🚩',
    ),
    Achievement(
      id: AchievementId.completeGame,
      title: 'Chinh Phục Tất Cả',
      description: 'Hoàn thành tất cả 11 màn',
      emoji: '👑',
    ),
  ];

  /// Callback để notify UI khi có achievement mới
  void Function(Achievement)? onUnlock;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    for (final a in achievements) {
      a.unlocked = prefs.getBool('$_prefix${a.id.name}') ?? false;
    }
  }

  Future<void> _unlock(AchievementId id) async {
    final achievement = achievements.firstWhere((a) => a.id == id);
    if (achievement.unlocked) return;
    achievement.unlocked = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix${id.name}', true);
    onUnlock?.call(achievement);
  }

  // Tracking counters (session-based)
  int _totalFruitsLifetime = 0;
  int _totalKills = 0;

  Future<void> loadLifetimeStats() async {
    final prefs = await SharedPreferences.getInstance();
    _totalFruitsLifetime = prefs.getInt('lifetime_fruits') ?? 0;
    _totalKills = prefs.getInt('lifetime_kills') ?? 0;
  }

  Future<void> recordDeath() async {
    await _unlock(AchievementId.firstBlood);
  }

  Future<void> recordFruitCollected() async {
    _totalFruitsLifetime++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lifetime_fruits', _totalFruitsLifetime);
    if (_totalFruitsLifetime >= 10) await _unlock(AchievementId.fruitCollector);
    if (_totalFruitsLifetime >= 50) await _unlock(AchievementId.fruitMaster);
  }

  Future<void> recordEnemyKill() async {
    _totalKills++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lifetime_kills', _totalKills);
    if (_totalKills >= 10) await _unlock(AchievementId.killer);
  }

  Future<void> recordLevelComplete(int deathCount, int score, int unlockedLevels) async {
    if (deathCount == 0) await _unlock(AchievementId.speedRunner);
    if (score >= 500) await _unlock(AchievementId.highScorer);
    if (unlockedLevels >= 5) await _unlock(AchievementId.explorer);
    if (unlockedLevels >= 11) await _unlock(AchievementId.veteran);
    if (unlockedLevels > 11) await _unlock(AchievementId.completeGame);
  }

  Future<void> recordCheckpoint() async {
    await _unlock(AchievementId.checkpoint);
  }

  int get unlockedCount => achievements.where((a) => a.unlocked).length;
  int get totalCount => achievements.length;
}
