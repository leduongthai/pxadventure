import 'package:shared_preferences/shared_preferences.dart';

class ScoreManager {
  ScoreManager._internal();
  static final ScoreManager instance = ScoreManager._internal();

  int currentScore = 0;
  int totalFruitCollected = 0;
  int deathCount = 0;

  static const Map<String, int> _fruitScores = {
    'Apple': 10,
    'Bananas': 15,
    'Cherries': 20,
    'Kiwi': 25,
    'Melon': 30,
    'Orange': 35,
    'Pineapple': 40,
    'Strawberry': 50,
  };

  void reset() {
    currentScore = 0;
    totalFruitCollected = 0;
    deathCount = 0;
  }

  void addFruitScore(String fruitType) {
    currentScore += _fruitScores[fruitType] ?? 10;
    totalFruitCollected++;
  }

  void addEnemyKillScore() {
    currentScore += 50;
  }

  void applyTimeBonusScore(int secondsRemaining) {
    currentScore += secondsRemaining * 5;
  }

  void incrementDeath() {
    deathCount++;
  }

  Future<void> saveHighScore(int level, int score) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'highscore_level_$level';
    final existing = prefs.getInt(key) ?? 0;
    if (score > existing) {
      await prefs.setInt(key, score);
    }
  }

  Future<int> getHighScore(int level) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('highscore_level_$level') ?? 0;
  }
}
