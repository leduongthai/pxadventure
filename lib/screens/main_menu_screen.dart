import 'package:flutter/material.dart';
import 'package:pixel_adventure/managers/achievement_manager.dart';
import 'package:pixel_adventure/managers/save_manager.dart';
import 'package:pixel_adventure/managers/score_manager.dart';
import 'package:pixel_adventure/managers/skill_manager.dart';
import 'package:pixel_adventure/services/progress_unlock_service.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with SingleTickerProviderStateMixin {
  bool _soundEnabled = true;
  bool _secretUnlocked = false;
  int _completedLevels = 0;
  String _playerName = 'Player';
  int _skillPoints = 0;
  int _titleTapCount = 0;
  DateTime? _lastTitleTapAt;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _soundEnabled = SaveManager.instance.isSoundEnabled();
    _playerName = SaveManager.instance.getPlayerName();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _loadSkillPoints();
    _loadSecretUnlock();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _toggleSound() async {
    final newValue = !_soundEnabled;
    await SaveManager.instance.setSoundEnabled(newValue);
    setState(() => _soundEnabled = newValue);
  }

  void _editName() async {
    final result = await Navigator.pushNamed(context, '/name');
    if (result != null && mounted) {
      setState(() => _playerName = result as String);
    }
  }

  Future<void> _loadSkillPoints() async {
    final points = await SkillManager.instance.availablePoints();
    if (mounted) {
      setState(() => _skillPoints = points);
    }
  }

  Future<void> _loadSecretUnlock() async {
    final fullStars = await ScoreManager.instance
        .hasThreeStarsEveryLevel(SaveManager.maxLevels);
    final completedLevels =
        await ScoreManager.instance.completedLevelCount(SaveManager.maxLevels);
    final unlocked = fullStars && AchievementManager.instance.allUnlocked;
    if (mounted) {
      setState(() {
        _completedLevels = completedLevels;
        _secretUnlocked = unlocked;
      });
    }
  }

  Future<void> _handleTitleTap() async {
    final now = DateTime.now();
    if (_lastTitleTapAt == null ||
        now.difference(_lastTitleTapAt!) > const Duration(seconds: 2)) {
      _titleTapCount = 0;
    }

    _lastTitleTapAt = now;
    _titleTapCount++;
    if (_titleTapCount < 7) return;

    _titleTapCount = 0;
    await ProgressUnlockService.unlockAll();
    await _loadSkillPoints();
    await _loadSecretUnlock();

    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã mở khóa toàn bộ tiến trình test.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final achievements = AchievementManager.instance;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A2745), Color(0xFF211F30), Color(0xFF1A1829)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Player info top-left
              Positioned(
                top: 12,
                left: 16,
                child: GestureDetector(
                  onTap: _editName,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E2C45),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF5B4EC8), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person,
                            color: Color(0xFF8B7CF8), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _playerName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit, color: Colors.white24, size: 12),
                      ],
                    ),
                  ),
                ),
              ),
              // Achievements badge top-right
              Positioned(
                top: 12,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/achievements'),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E2C45),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFFFFD700), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🏆', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(
                          '${achievements.unlockedCount}/${achievements.totalCount}',
                          style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title with pulse
                    ScaleTransition(
                      scale: _pulseAnim,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _handleTitleTap,
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Color(0xFF8B7CF8),
                              Color(0xFFB4A9FF),
                              Color(0xFF8B7CF8)
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            'PIXEL\nADVENTURE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Level progress subtitle
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E2C45).withAlpha(180),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_completedLevels/11 màn đã hoàn thành',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 52),
                    _MenuButton(
                      label: '▶  CHƠI NGAY',
                      onTap: () =>
                          Navigator.pushNamed(context, '/levels').then((_) {
                        _loadSkillPoints();
                        _loadSecretUnlock();
                      }),
                      isPrimary: true,
                    ),
                    const SizedBox(height: 14),
                    _MenuButton(
                      label: '👤  CHỌN NHÂN VẬT',
                      onTap: () => Navigator.pushNamed(context, '/character'),
                    ),
                    const SizedBox(height: 14),
                    _MenuButton(
                      label: 'KỸ NĂNG ($_skillPoints)',
                      onTap: () => Navigator.pushNamed(context, '/skills')
                          .then((_) => _loadSkillPoints()),
                    ),
                    const SizedBox(height: 14),
                    if (_secretUnlocked) ...[
                      _MenuButton(
                        label: 'EXTRA',
                        onTap: () => Navigator.pushNamed(context, '/secret'),
                      ),
                      const SizedBox(height: 14),
                    ],
                    _MenuButton(
                      label: '🏆  THÀNH TÍCH',
                      onTap: () => Navigator.pushNamed(context, '/achievements')
                          .then((_) {
                        _loadSecretUnlock();
                        if (mounted) setState(() {});
                      }),
                    ),
                    const SizedBox(height: 14),
                    _MenuButton(
                      label: '📊  BẢNG XẾP HẠNG',
                      onTap: () => Navigator.pushNamed(context, '/leaderboard'),
                    ),
                    const SizedBox(height: 14),
                    _MenuButton(
                      label: _soundEnabled
                          ? '🔊  ÂM THANH: BẬT'
                          : '🔇  ÂM THANH: TẮT',
                      onTap: _toggleSound,
                      isSmall: true,
                    ),
                    const SizedBox(height: 36),
                    // Credits small text
                    GestureDetector(
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => const _CreditsDialog(),
                      ),
                      child: const Text(
                        'Credits & Thông Tin',
                        style: TextStyle(
                            color: Colors.white24,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white24),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isSmall;

  const _MenuButton({
    required this.label,
    required this.onTap,
    this.isPrimary = false,
    this.isSmall = false,
  });

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 260,
          height: widget.isSmall ? 44 : 52,
          decoration: BoxDecoration(
            gradient: widget.isPrimary
                ? const LinearGradient(
                    colors: [Color(0xFF7B6FE8), Color(0xFF5B4EC8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: widget.isPrimary ? null : const Color(0xFF2E2C45),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isPrimary
                  ? const Color(0xFF9B8FF8)
                  : const Color(0xFF5B4EC8),
              width: widget.isPrimary ? 2 : 1.5,
            ),
            boxShadow: widget.isPrimary
                ? [
                    const BoxShadow(
                        color: Color(0x885B4EC8),
                        blurRadius: 16,
                        offset: Offset(0, 4))
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: TextStyle(
              color: Colors.white,
              fontSize: widget.isSmall ? 13 : 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _CreditsDialog extends StatelessWidget {
  const _CreditsDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2E2C45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF5B4EC8), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🎮 PIXEL ADVENTURE',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2),
            ),
            const SizedBox(height: 20),
            _creditRow('👨‍💻 Lập trình', 'Le Duong Thai'),
            _creditRow('📧 Email', 'levanben0859@gmail.com'),
            _creditRow('🎨 Assets', 'Pixel Frog (itch.io)'),
            _creditRow('🛠️ Engine', 'Flame + Flutter'),
            _creditRow('📅 Ngày tạo', '2 tháng 5, 2026'),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng',
                  style: TextStyle(color: Color(0xFF8B7CF8))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _creditRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
