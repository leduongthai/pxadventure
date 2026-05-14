import 'package:shared_preferences/shared_preferences.dart';

class ScoreManager {
  ScoreManager._internal();
  static final ScoreManager instance = ScoreManager._internal();

  int currentScore = 0;
  int totalFruitCollected = 0;
  int totalFruitsInLevel = 0;
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
    totalFruitsInLevel = 0;
    deathCount = 0;
  }

  void setLevelFruitTotal(int total) {
    totalFruitsInLevel = total;
  }

  void addFruitScore(String fruitType) {
    currentScore += _fruitScores[fruitType] ?? 10;
    totalFruitCollected++;

    if (totalFruitCollected % 5 == 0 && deathCount > 0) {
      deathCount--;
    }
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

  int calculateStars() {
    if (totalFruitsInLevel == 0) return 1;
    final collectedAllFruits = totalFruitCollected >= totalFruitsInLevel;
    final collectedHalfFruits = totalFruitCollected >= (totalFruitsInLevel / 2).ceil();

    if (collectedAllFruits && deathCount == 0) return 3;
    if (collectedHalfFruits) return 2;
    return 1;
  }

  Future<void> saveBestStars(int level, int stars) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'stars_level_$level';
    final existing = prefs.getInt(key) ?? 0;
    if (stars > existing) {
      await prefs.setInt(key, stars);
    }
  }

  Future<int> getBestStars(int level) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('stars_level_$level') ?? 0;
  }
}
