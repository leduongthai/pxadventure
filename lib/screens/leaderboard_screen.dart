import 'package:flutter/material.dart';
import 'package:pixel_adventure/services/leaderboard_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;
  bool _cloudHealthy = false;
  String _cloudStatus = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });

    final entries = await LeaderboardService.instance.getLeaderboard();
    if (!mounted) return;

    setState(() {
      _entries = entries;
      _cloudStatus = LeaderboardService.instance.cloudStatus;
      _cloudHealthy = LeaderboardService.instance.isCloudHealthy;
      _loading = false;
    });
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
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _load,
          ),
        ],
        centerTitle: true,
      ),
      body: Column(
        children: [
          _CloudStatusBanner(status: _cloudStatus, healthy: _cloudHealthy),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFD700)),
      );
    }

    if (_entries.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có điểm nào.\nHãy chơi và lập kỷ lục!',
          style: TextStyle(color: Colors.white54, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
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
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'Màn ${entry['level']}',
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
    );
  }
}

class _CloudStatusBanner extends StatelessWidget {
  final String status;
  final bool healthy;

  const _CloudStatusBanner({
    required this.status,
    required this.healthy,
  });

  @override
  Widget build(BuildContext context) {
    if (status.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: healthy ? const Color(0xFF123E32) : const Color(0xFF3A2D18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: healthy ? const Color(0xFF4ECDC4) : const Color(0xFFFFD166),
        ),
      ),
      child: Row(
        children: [
          Icon(
            healthy ? Icons.cloud_done : Icons.cloud_off,
            color: healthy ? const Color(0xFF4ECDC4) : const Color(0xFFFFD166),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              status,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
