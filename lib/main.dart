import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pixel_adventure/managers/achievement_manager.dart';
import 'package:pixel_adventure/managers/save_manager.dart';
import 'package:pixel_adventure/managers/skill_manager.dart';
import 'package:pixel_adventure/screens/achievements_screen.dart';
import 'package:pixel_adventure/screens/character_select_screen.dart';
import 'package:pixel_adventure/screens/game_screen.dart';
import 'package:pixel_adventure/screens/leaderboard_screen.dart';
import 'package:pixel_adventure/screens/level_select_screen.dart';
import 'package:pixel_adventure/screens/main_menu_screen.dart';
import 'package:pixel_adventure/screens/player_name_screen.dart';
import 'package:pixel_adventure/screens/skill_tree_screen.dart';
import 'package:pixel_adventure/services/firebase_bootstrap.dart';
import 'package:pixel_adventure/services/firebase_web_plugin_registrant_stub.dart'
    if (dart.library.html) 'package:pixel_adventure/services/firebase_web_plugin_registrant_web.dart';
import 'package:pixel_adventure/services/progress_unlock_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFirebaseWebPlugins();
  await dotenv.load(fileName: '.env', isOptional: true);
  await FirebaseBootstrap.initialize();

  await Flame.device.fullScreen();
  await Flame.device.setLandscape();

  await _seedDebugProgressIfRequested();
  await SaveManager.instance.init();
  await SkillManager.instance.init();
  await AchievementManager.instance.init();
  await AchievementManager.instance.loadLifetimeStats();

  runApp(const PixelAdventureApp());
}

Future<void> _seedDebugProgressIfRequested() async {
  if (Uri.base.queryParameters['debugUnlock'] != '1') return;
  await ProgressUnlockService.unlockAll();
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
            final secretRun = args?['secretRun'] as bool? ?? false;
            return MaterialPageRoute(
              builder: (_) => GameScreen(
                initialLevelIndex: levelIndex,
                secretRun: secretRun,
              ),
            );
          case '/secret':
            return MaterialPageRoute(
              builder: (_) => const GameScreen(secretRun: true),
            );
          case '/leaderboard':
            return MaterialPageRoute(builder: (_) => const LeaderboardScreen());
          case '/achievements':
            return MaterialPageRoute(
                builder: (_) => const AchievementsScreen());
          case '/skills':
            return MaterialPageRoute(builder: (_) => const SkillTreeScreen());
          case '/name':
            return MaterialPageRoute(builder: (_) => const PlayerNameScreen());
          default:
            return MaterialPageRoute(builder: (_) => const MainMenuScreen());
        }
      },
    );
  }
}
