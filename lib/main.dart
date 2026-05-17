import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/managers/achievement_manager.dart';
import 'package:pixel_adventure/managers/save_manager.dart';
import 'package:pixel_adventure/screens/achievements_screen.dart';
import 'package:pixel_adventure/screens/character_select_screen.dart';
import 'package:pixel_adventure/screens/game_screen.dart';
import 'package:pixel_adventure/screens/leaderboard_screen.dart';
import 'package:pixel_adventure/screens/level_select_screen.dart';
import 'package:pixel_adventure/screens/main_menu_screen.dart';
import 'package:pixel_adventure/screens/player_name_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.fullScreen();
  await Flame.device.setLandscape();

  await SaveManager.instance.init();
  await AchievementManager.instance.init();
  await AchievementManager.instance.loadLifetimeStats();

  runApp(const PixelAdventureApp());
}

class PixelAdventureApp extends StatelessWidget {
  const PixelAdventureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixel Adventure',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: const Color(0xFF211F30)),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const MainMenuScreen());
          case '/character':
            return MaterialPageRoute(
                builder: (_) => const CharacterSelectScreen());
          case '/levels':
            return MaterialPageRoute(builder: (_) => const LevelSelectScreen());
          case '/game':
            final args = settings.arguments as Map<String, dynamic>?;
            final levelIndex = args?['levelIndex'] as int? ?? 0;
            return MaterialPageRoute(
              builder: (_) => GameScreen(initialLevelIndex: levelIndex),
            );
          case '/leaderboard':
            return MaterialPageRoute(builder: (_) => const LeaderboardScreen());
          case '/achievements':
            return MaterialPageRoute(
                builder: (_) => const AchievementsScreen());
          case '/name':
            return MaterialPageRoute(builder: (_) => const PlayerNameScreen());
          default:
            return MaterialPageRoute(builder: (_) => const MainMenuScreen());
        }
      },
    );
  }
}
