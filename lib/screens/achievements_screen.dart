import 'package:flutter/material.dart';
import 'package:pixel_adventure/managers/achievement_manager.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = AchievementManager.instance;
    final unlocked = manager.unlockedCount;
    final total = manager.totalCount;

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
          'THÀNH TÍCH',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$unlocked/$total',
                style: const TextStyle(color: Color(0xFFFFD700), fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: unlocked / total,
                    backgroundColor: const Color(0xFF2E2C45),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$unlocked trên $total thành tích đã đạt được',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: manager.achievements.length,
              itemBuilder: (context, index) {
                final a = manager.achievements[index];
                return _AchievementTile(achievement: a);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  const _AchievementTile({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.unlocked;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: unlocked ? const Color(0xFF2E2C45) : const Color(0xFF1A1829),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked ? const Color(0xFFFFD700) : const Color(0xFF333345),
          width: 1.5,
        ),
        boxShadow: unlocked
            ? [const BoxShadow(color: Color(0x33FFD700), blurRadius: 8, offset: Offset(0, 2))]
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: unlocked ? const Color(0xFF3D3A5C) : const Color(0xFF222035),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              unlocked ? achievement.emoji : '🔒',
              style: TextStyle(fontSize: unlocked ? 24 : 20),
            ),
          ),
        ),
        title: Text(
          unlocked ? achievement.title : '???',
          style: TextStyle(
            color: unlocked ? const Color(0xFFFFD700) : Colors.white24,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          unlocked ? achievement.description : 'Chưa đạt được',
          style: TextStyle(
            color: unlocked ? Colors.white60 : Colors.white12,
            fontSize: 12,
          ),
        ),
        trailing: unlocked
            ? const Icon(Icons.check_circle, color: Color(0xFFFFD700), size: 24)
            : const Icon(Icons.radio_button_unchecked, color: Colors.white12, size: 24),
      ),
    );
  }
}

/// Toast popup khi unlock achievement mới (dùng trong game overlay)
class AchievementToast extends StatefulWidget {
  final Achievement achievement;
  const AchievementToast({super.key, required this.achievement});

  @override
  State<AchievementToast> createState() => _AchievementToastState();
}

class _AchievementToastState extends State<AchievementToast> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = Tween<double>(begin: 0, end: 1).animate(_ctrl);
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _ctrl.reverse();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2E2C45),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 12)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.achievement.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '🏆 Thành Tích Mới!',
                        style: TextStyle(color: Color(0xFFFFD700), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.achievement.title,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
