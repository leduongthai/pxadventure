import 'package:flutter/material.dart';
import 'package:pixel_adventure/managers/save_manager.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await SaveManager.instance.getLeaderboard();
    setState(() => _entries = entries);
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
          'BẢNG XẾP HẠNG',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        centerTitle: true,
      ),
      body: _entries.isEmpty
          ? const Center(
              child: Text(
                'Chưa có điểm nào.\nHãy chơi và lập kỷ lục!',
                style: TextStyle(color: Colors.white54, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final entry = _entries[index];
                final rank = index + 1;
                Color rankColor = Colors.white70;
                if (rank == 1) rankColor = const Color(0xFFFFD700);
                if (rank == 2) rankColor = const Color(0xFFC0C0C0);
                if (rank == 3) rankColor = const Color(0xFFCD7F32);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E2C45),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF5B4EC8), width: 1),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        child: Text(
                          '#$rank',
                          style: TextStyle(
                            color: rankColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry['name'] as String,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                        ),
                      ),
                      Text(
                        'Level ${entry['level']}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${entry['score']}',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
