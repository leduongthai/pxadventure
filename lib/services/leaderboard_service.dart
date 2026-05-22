import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:pixel_adventure/managers/save_manager.dart';
import 'package:pixel_adventure/services/firebase_bootstrap.dart';

class LeaderboardService {
  LeaderboardService._internal();
  static final LeaderboardService instance = LeaderboardService._internal();

  static const _collectionName = 'leaderboard';
  String? _lastCloudError;

  bool get isCloudEnabled => Firebase.apps.isNotEmpty;
  String? get lastCloudError => _lastCloudError;

  String get cloudStatus {
    if (!isCloudEnabled) {
      return FirebaseBootstrap.lastError ?? 'Firebase chưa được khởi tạo.';
    }
    if (_lastCloudError != null) {
      return 'Firebase đã khởi tạo nhưng Firestore lỗi: $_lastCloudError';
    }
    return 'Firebase đã kết nối.';
  }

  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    if (!isCloudEnabled) {
      return SaveManager.instance.getLeaderboard();
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_collectionName)
          .orderBy('score', descending: true)
          .limit(10)
          .get()
          .timeout(const Duration(seconds: 8));

      final remoteEntries = snapshot.docs
          .map((doc) => _entryFromFirestore(doc.data()))
          .where((entry) => (entry['score'] as int) > 0)
          .toList();

      _lastCloudError = null;
      if (remoteEntries.isNotEmpty) return remoteEntries;
    } catch (error) {
      _lastCloudError = error.toString();
      debugPrint('Cloud leaderboard read failed: $_lastCloudError');
    }

    return SaveManager.instance.getLeaderboard();
  }

  Future<void> addLeaderboardEntry(String name, int score, int level) async {
    await SaveManager.instance.addLeaderboardEntry(name, score, level);

    if (!isCloudEnabled) return;

    try {
      await FirebaseFirestore.instance.collection(_collectionName).add({
        'name': _sanitizeName(name),
        'score': score,
        'level': level,
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 8));
      _lastCloudError = null;
    } catch (error) {
      _lastCloudError = error.toString();
      debugPrint('Cloud leaderboard write failed: $_lastCloudError');
    }
  }

  Map<String, dynamic> _entryFromFirestore(Map<String, dynamic> data) {
    return {
      'name': _sanitizeName(data['name']?.toString() ?? 'Player'),
      'score': _readInt(data['score']),
      'level': _readInt(data['level'], fallback: 1),
    };
  }

  int _readInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _sanitizeName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Player';
    return trimmed.length <= 16 ? trimmed : trimmed.substring(0, 16);
  }
}
