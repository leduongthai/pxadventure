import 'package:pixel_adventure/managers/achievement_manager.dart';
import 'package:pixel_adventure/managers/save_manager.dart';
import 'package:pixel_adventure/managers/skill_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressUnlockService {
  const ProgressUnlockService._();

  static Future<void> unlockAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('unlocked_levels', SaveManager.maxLevels);
    await prefs.setInt('lifetime_fruits', 50);
    await prefs.setInt('lifetime_kills', 10);

    for (var level = 1; level <= SaveManager.maxLevels; level++) {
      await prefs.setInt('stars_level_$level', 3);
      await prefs.setInt('highscore_level_$level', 999);
    }

    for (final id in AchievementId.values) {
      await prefs.setBool('achievement_${id.name}', true);
    }

    await SaveManager.instance.init();
    await SkillManager.instance.init();
    await AchievementManager.instance.init();
    await AchievementManager.instance.loadLifetimeStats();
  }
}
