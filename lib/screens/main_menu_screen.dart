import 'package:flutter/material.dart';
import 'package:pixel_adventure/managers/save_manager.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _soundEnabled = SaveManager.instance.isSoundEnabled();
  }

  void _toggleSound() async {
    final newValue = !_soundEnabled;
    await SaveManager.instance.setSoundEnabled(newValue);
    setState(() => _soundEnabled = newValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF211F30),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'PIXEL ADVENTURE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 60),
                _MenuButton(
                  label: 'CHƠI',
                  onTap: () => Navigator.pushNamed(context, '/levels'),
                ),
                const SizedBox(height: 16),
                _MenuButton(
                  label: 'CHỌN NHÂN VẬT',
                  onTap: () => Navigator.pushNamed(context, '/character'),
                ),
                const SizedBox(height: 16),
                _MenuButton(
                  label: 'BẢNG XẾP HẠNG',
                  onTap: () => Navigator.pushNamed(context, '/leaderboard'),
                ),
                const SizedBox(height: 16),
                _MenuButton(
                  label: _soundEnabled ? '🔊 ÂM THANH: BẬT' : '🔇 ÂM THANH: TẮT',
                  onTap: _toggleSound,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _MenuButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF5B4EC8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF8B7CF8), width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
