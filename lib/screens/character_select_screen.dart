import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pixel_adventure/managers/save_manager.dart';

class CharacterSelectScreen extends StatefulWidget {
  const CharacterSelectScreen({super.key});

  @override
  State<CharacterSelectScreen> createState() => _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends State<CharacterSelectScreen> {
  static const List<String> _characters = [
    'Mask Dude',
    'Ninja Frog',
    'Pink Man',
    'Virtual Guy',
  ];

  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = SaveManager.instance.getSelectedCharacter();
  }

  void _selectCharacter(String character) async {
    await SaveManager.instance.setSelectedCharacter(character);
    setState(() => _selected = character);
  }

  // Maps character name to asset folder name (spaces to %20 not needed in AssetImage)
  String _idleAsset(String character) {
    return 'assets/images/Main Characters/$character/Idle (32x32).png';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF211F30),
      appBar: AppBar(
        backgroundColor: const Color(0xFF211F30),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'CHỌN NHÂN VẬT',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 2),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Wrap(
          spacing: 24,
          runSpacing: 24,
          alignment: WrapAlignment.center,
          children: _characters.map((char) {
            final isSelected = char == _selected;
            return GestureDetector(
              onTap: () => _selectCharacter(char),
              child: Container(
                width: 120,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2C45),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFFD700)
                        : const Color(0xFF5B4EC8),
                    width: isSelected ? 3 : 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CharacterIdlePreview(asset: _idleAsset(char)),
                    const SizedBox(height: 8),
                    Text(
                      char,
                      style: TextStyle(
                        color:
                            isSelected ? const Color(0xFFFFD700) : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle,
                          color: Color(0xFFFFD700), size: 16),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CharacterIdlePreview extends StatefulWidget {
  final String asset;

  const _CharacterIdlePreview({required this.asset});

  @override
  State<_CharacterIdlePreview> createState() => _CharacterIdlePreviewState();
}

class _CharacterIdlePreviewState extends State<_CharacterIdlePreview> {
  static const int _frameCount = 11;
  static const double _frameSize = 64;
  Timer? _timer;
  int _frame = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _CharacterIdlePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) {
      setState(() => _frame = 0);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() => _frame = (_frame + 1) % _frameCount);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox(
        width: _frameSize,
        height: _frameSize,
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: _frameSize * _frameCount,
          maxWidth: _frameSize * _frameCount,
          minHeight: _frameSize,
          maxHeight: _frameSize,
          child: Transform.translate(
            offset: Offset(-_frame * _frameSize, 0),
            child: Image.asset(
              widget.asset,
              width: _frameSize * _frameCount,
              height: _frameSize,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
              errorBuilder: (_, __, ___) => const SizedBox(
                width: _frameSize,
                height: _frameSize,
                child: Icon(Icons.person, size: 64, color: Colors.white54),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
