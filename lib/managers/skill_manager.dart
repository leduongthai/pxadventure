import 'package:pixel_adventure/managers/save_manager.dart';
import 'package:pixel_adventure/managers/score_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SkillUpgrade { runSpeed, dashCooldown, extraJump }

class SkillManager {
  SkillManager._internal();
  static final SkillManager instance = SkillManager._internal();

  static const _keyRunSpeedLevel = 'skill_run_speed_level';
  static const _keyDashCooldownLevel = 'skill_dash_cooldown_level';
  static const _keyExtraJumpLevel = 'skill_extra_jump_level';

  static const Map<SkillUpgrade, List<int>> _costs = {
    SkillUpgrade.runSpeed: [1, 2, 3],
    SkillUpgrade.dashCooldown: [1, 2, 3],
    SkillUpgrade.extraJump: [4],
  };

  int _runSpeedLevel = 0;
  int _dashCooldownLevel = 0;
  int _extraJumpLevel = 0;

  int get runSpeedLevel => _runSpeedLevel;
  int get dashCooldownLevel => _dashCooldownLevel;
  int get extraJumpLevel => _extraJumpLevel;

  double get runSpeedMultiplier => 1 + (_runSpeedLevel * 0.10);
  double get dashCooldownSeconds => 0.6 - (_dashCooldownLevel * 0.08);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _runSpeedLevel = _clampLevel(
      SkillUpgrade.runSpeed,
      prefs.getInt(_keyRunSpeedLevel) ?? 0,
    );
    _dashCooldownLevel = _clampLevel(
      SkillUpgrade.dashCooldown,
      prefs.getInt(_keyDashCooldownLevel) ?? 0,
    );
    _extraJumpLevel = _clampLevel(
      SkillUpgrade.extraJump,
      prefs.getInt(_keyExtraJumpLevel) ?? 0,
    );
  }

  int levelFor(SkillUpgrade upgrade) {
    switch (upgrade) {
      case SkillUpgrade.runSpeed:
        return _runSpeedLevel;
      case SkillUpgrade.dashCooldown:
        return _dashCooldownLevel;
      case SkillUpgrade.extraJump:
        return _extraJumpLevel;
    }
  }

  int maxLevelFor(SkillUpgrade upgrade) => _costs[upgrade]!.length;

  bool isMaxed(SkillUpgrade upgrade) {
    return levelFor(upgrade) >= maxLevelFor(upgrade);
  }

  int costForNextLevel(SkillUpgrade upgrade) {
    if (isMaxed(upgrade)) return 0;
    return _costs[upgrade]![levelFor(upgrade)];
  }

  int spentPoints() {
    var spent = 0;
    for (final upgrade in SkillUpgrade.values) {
      final costs = _costs[upgrade]!;
      final level = levelFor(upgrade);
      for (var i = 0; i < level; i++) {
        spent += costs[i];
      }
    }
    return spent;
  }

  Future<int> totalEarnedPoints() async {
    var total = 0;
    for (var level = 1; level <= SaveManager.maxLevels; level++) {
      total += await ScoreManager.instance.getBestStars(level);
    }
    return total;
  }

  Future<int> availablePoints() async {
    final earned = await totalEarnedPoints();
    final available = earned - spentPoints();
    return available < 0 ? 0 : available;
  }

  Future<bool> buyUpgrade(SkillUpgrade upgrade) async {
    if (isMaxed(upgrade)) return false;

    final cost = costForNextLevel(upgrade);
    final available = await availablePoints();
    if (available < cost) return false;

    switch (upgrade) {
      case SkillUpgrade.runSpeed:
        _runSpeedLevel++;
        break;
      case SkillUpgrade.dashCooldown:
        _dashCooldownLevel++;
        break;
      case SkillUpgrade.extraJump:
        _extraJumpLevel++;
        break;
    }

    await _save();
    return true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyRunSpeedLevel, _runSpeedLevel);
    await prefs.setInt(_keyDashCooldownLevel, _dashCooldownLevel);
    await prefs.setInt(_keyExtraJumpLevel, _extraJumpLevel);
  }

  int _clampLevel(SkillUpgrade upgrade, int level) {
    return level.clamp(0, maxLevelFor(upgrade)).toInt();
  }
}
