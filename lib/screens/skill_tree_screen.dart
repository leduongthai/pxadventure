import 'package:flutter/material.dart';
import 'package:pixel_adventure/managers/skill_manager.dart';

class SkillTreeScreen extends StatefulWidget {
  const SkillTreeScreen({super.key});

  @override
  State<SkillTreeScreen> createState() => _SkillTreeScreenState();
}

class _SkillTreeScreenState extends State<SkillTreeScreen> {
  int _earnedPoints = 0;
  int _availablePoints = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final skills = SkillManager.instance;
    final earned = await skills.totalEarnedPoints();
    final available = await skills.availablePoints();

    if (!mounted) return;
    setState(() {
      _earnedPoints = earned;
      _availablePoints = available;
      _loading = false;
    });
  }

  Future<void> _buy(SkillUpgrade upgrade) async {
    final bought = await SkillManager.instance.buyUpgrade(upgrade);
    if (!mounted) return;

    await _loadData();
    if (!mounted) return;

    final message = bought ? 'Đã nâng cấp kỹ năng' : 'Không đủ điểm kỹ năng';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            bought ? const Color(0xFF1D8A5A) : const Color(0xFF8A2D3A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF211F30),
      appBar: AppBar(
        backgroundColor: const Color(0xFF211F30),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'CÂY KỸ NĂNG',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                children: [
                  _PointSummary(
                    earnedPoints: _earnedPoints,
                    availablePoints: _availablePoints,
                    spentPoints: SkillManager.instance.spentPoints(),
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 760;
                      final cardWidth = wide
                          ? (constraints.maxWidth - 24) / 3
                          : constraints.maxWidth;

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: SkillUpgrade.values
                            .map(
                              (upgrade) => SizedBox(
                                width: cardWidth,
                                child: _SkillCard(
                                  upgrade: upgrade,
                                  availablePoints: _availablePoints,
                                  onBuy: () => _buy(upgrade),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Điểm kỹ năng lấy từ số sao tốt nhất của từng màn. Khi chơi lại và tăng kỷ lục sao, bạn sẽ có thêm điểm để mua nâng cấp vĩnh viễn.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }
}

class _PointSummary extends StatelessWidget {
  final int earnedPoints;
  final int availablePoints;
  final int spentPoints;

  const _PointSummary({
    required this.earnedPoints,
    required this.availablePoints,
    required this.spentPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2C45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD166), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFFFFD166), size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Điểm kỹ năng',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Đã kiếm: $earnedPoints  •  Đã dùng: $spentPoints',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1D8A5A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$availablePoints còn',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  final SkillUpgrade upgrade;
  final int availablePoints;
  final VoidCallback onBuy;

  const _SkillCard({
    required this.upgrade,
    required this.availablePoints,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final skills = SkillManager.instance;
    final level = skills.levelFor(upgrade);
    final maxLevel = skills.maxLevelFor(upgrade);
    final cost = skills.costForNextLevel(upgrade);
    final maxed = skills.isMaxed(upgrade);
    final canBuy = !maxed && availablePoints >= cost;
    final definition = _SkillDefinition.forUpgrade(upgrade, level);

    return Container(
      constraints: const BoxConstraints(minHeight: 230),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2745),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: maxed ? const Color(0xFF1D8A5A) : const Color(0xFF5B4EC8),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: definition.color.withAlpha(45),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(definition.icon, color: definition.color, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  definition.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: maxLevel == 0 ? 0 : level / maxLevel,
            backgroundColor: const Color(0xFF1A1829),
            valueColor: AlwaysStoppedAnimation<Color>(definition.color),
            minHeight: 7,
          ),
          const SizedBox(height: 8),
          Text(
            'Cấp $level/$maxLevel',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Text(
            definition.description,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Text(
            definition.effect,
            style: TextStyle(
              color: definition.color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canBuy ? onBuy : null,
              icon: Icon(maxed ? Icons.check_circle : Icons.add_circle),
              label: Text(maxed ? 'Đã tối đa' : 'Mua - $cost điểm'),
              style: ElevatedButton.styleFrom(
                backgroundColor: definition.color,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF3A374F),
                disabledForegroundColor: Colors.white38,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillDefinition {
  final String title;
  final String description;
  final String effect;
  final IconData icon;
  final Color color;

  const _SkillDefinition({
    required this.title,
    required this.description,
    required this.effect,
    required this.icon,
    required this.color,
  });

  factory _SkillDefinition.forUpgrade(SkillUpgrade upgrade, int level) {
    switch (upgrade) {
      case SkillUpgrade.runSpeed:
        return _SkillDefinition(
          title: 'Tốc độ chạy',
          description: 'Tăng tốc độ di chuyển cơ bản của nhân vật.',
          effect: '+${level * 10}% tốc độ hiện tại',
          icon: Icons.directions_run,
          color: const Color(0xFF4ECDC4),
        );
      case SkillUpgrade.dashCooldown:
        final cooldown = (0.6 - level * 0.08).toStringAsFixed(2);
        return _SkillDefinition(
          title: 'Hồi Dash',
          description: 'Giảm thời gian hồi chiêu Dash sau mỗi lần lướt.',
          effect: 'Cooldown hiện tại: ${cooldown}s',
          icon: Icons.flash_on,
          color: const Color(0xFFFFD166),
        );
      case SkillUpgrade.extraJump:
        return _SkillDefinition(
          title: 'Nhảy bổ sung',
          description: 'Mở thêm một lần nhảy trên không.',
          effect: level > 0 ? '+1 lần nhảy đã mở' : 'Chưa mở khóa',
          icon: Icons.keyboard_double_arrow_up,
          color: const Color(0xFFFF6B6B),
        );
    }
  }
}
