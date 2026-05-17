import 'package:shared_preferences/shared_preferences.dart';

class SaveManager {
  SaveManager._internal();
  static final SaveManager instance = SaveManager._internal();

  static const int maxLevels = 11;
  static const _keyPlayerName = 'player_name';
  static const _keySelectedCharacter = 'selected_character';
  static const _keyUnlockedLevels = 'unlocked_levels';
  static const _keySoundEnabled = 'sound_enabled';
  static const _keyLeaderboard = 'leaderboard';

  String _playerName = 'Player';
  String _selectedCharacter = 'Mask Dude';
  int _unlockedLevels = 1;
  bool _soundEnabled = true;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _playerName = prefs.getString(_keyPlayerName) ?? 'Player';
    _selectedCharacter = prefs.getString(_keySelectedCharacter) ?? 'Mask Dude';
    _unlockedLevels =
        (prefs.getInt(_keyUnlockedLevels) ?? 1).clamp(1, maxLevels);
    _soundEnabled = prefs.getBool(_keySoundEnabled) ?? true;
  }

  String getPlayerName() => _playerName;
  Future<void> setPlayerName(String name) async {
    _playerName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPlayerName, name);
  }

  String getSelectedCharacter() => _selectedCharacter;
  Future<void> setSelectedCharacter(String character) async {
    _selectedCharacter = character;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedCharacter, character);
  }

  int getUnlockedLevels() => _unlockedLevels;
  Future<void> unlockNextLevel(int currentLevel) async {
    if (currentLevel >= _unlockedLevels) {
      _unlockedLevels = (currentLevel + 1).clamp(1, maxLevels);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyUnlockedLevels, _unlockedLevels);
    }
  }

  bool isSoundEnabled() => _soundEnabled;
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySoundEnabled, enabled);
  }

  // Leaderboard: stored as comma-separated entries "name|score|level"
  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyLeaderboard) ?? [];
    return raw.map((e) {
      final parts = e.split('|');
      return {
        'name': parts[0],
        'score': int.tryParse(parts[1]) ?? 0,
        'level': int.tryParse(parts[2]) ?? 1,
      };
    }).toList();
  }

  Future<void> addLeaderboardEntry(String name, int score, int level) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyLeaderboard) ?? [];
    raw.add('$name|$score|$level');
    // Sort descending by score
    raw.sort((a, b) {
      final scoreA = int.tryParse(a.split('|')[1]) ?? 0;
      final scoreB = int.tryParse(b.split('|')[1]) ?? 0;
      return scoreB.compareTo(scoreA);
    });
    // Keep top 10
    final top10 = raw.take(10).toList();
    await prefs.setStringList(_keyLeaderboard, top10);
  }
}
