import 'package:flutter/material.dart';
import 'package:pixel_adventure/managers/save_manager.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class PauseMenuWidget extends StatefulWidget {
  final PixelAdventure game;

  const PauseMenuWidget({super.key, required this.game});

  @override
  State<PauseMenuWidget> createState() => _PauseMenuWidgetState();
}

class _PauseMenuWidgetState extends State<PauseMenuWidget> {
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _soundEnabled = SaveManager.instance.isSoundEnabled();
  }

  void _toggleSound() async {
    final newValue = !_soundEnabled;
    await SaveManager.instance.setSoundEnabled(newValue);
    widget.game.playSounds = newValue;
    setState(() => _soundEnabled = newValue);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF211F30),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF5B4EC8), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'TẠM DỪNG',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 3),
            ),
            const SizedBox(height: 24),
            _OverlayButton(
              label: 'TIẾP TỤC',
              onTap: () => widget.game.overlays.remove('PauseMenu'),
            ),
            const SizedBox(height: 12),
            _OverlayButton(
              label: 'CHƠI LẠI',
              onTap: () {
                widget.game.overlays.remove('PauseMenu');
                widget.game.resetCurrentLevel();
              },
            ),
            const SizedBox(height: 12),
            _OverlayButton(
              label: _soundEnabled ? '🔊 ÂM THANH' : '🔇 ÂM THANH',
              onTap: _toggleSound,
            ),
            const SizedBox(height: 12),
            _OverlayButton(
              label: 'VỀ MENU',
              onTap: () {
                widget.game.overlays.remove('PauseMenu');
                Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OverlayButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF5B4EC8),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
