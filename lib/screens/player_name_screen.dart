import 'package:flutter/material.dart';
import 'package:pixel_adventure/managers/save_manager.dart';

/// Màn hình nhập tên hiển thị lần đầu khi chưa có tên
class PlayerNameScreen extends StatefulWidget {
  const PlayerNameScreen({super.key});

  @override
  State<PlayerNameScreen> createState() => _PlayerNameScreenState();
}

class _PlayerNameScreenState extends State<PlayerNameScreen> with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _ctrl.text = SaveManager.instance.getPlayerName() == 'Player' ? '' : SaveManager.instance.getPlayerName();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut);
    _animCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) {
      setState(() => _hasError = true);
      return;
    }
    final navigator = Navigator.of(context);
    await SaveManager.instance.setPlayerName(name);
    navigator.pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF211F30),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: 340,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2C45),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF5B4EC8), width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x665B4EC8), blurRadius: 24, offset: Offset(0, 8)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🎮', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    const Text(
                      'TÊN CỦA BẠN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Nhập tên để lưu vào bảng xếp hạng',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _ctrl,
                      focusNode: _focusNode,
                      maxLength: 16,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'Nhập tên...',
                        hintStyle: const TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: const Color(0xFF1A1829),
                        errorText: _hasError ? 'Tên không được để trống!' : null,
                        errorStyle: const TextStyle(color: Color(0xFFFF6B6B)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF5B4EC8), width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF5B4EC8), width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF8B7CF8), width: 2.5),
                        ),
                      ),
                      onChanged: (_) => setState(() => _hasError = false),
                      onSubmitted: (_) => _confirm(),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _confirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B4EC8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                        child: const Text(
                          'XÁC NHẬN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        await SaveManager.instance.setPlayerName('Player');
                        navigator.pop('Player');
                      },
                      child: const Text(
                        'Bỏ qua',
                        style: TextStyle(color: Colors.white24, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
