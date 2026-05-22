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
  static const _cloudTimeout = Duration(seconds: 20);
  static const _retryDelay = Duration(milliseconds: 800);

  String? _lastCloudError;
  String? _lastCloudErrorCode;
  bool _usedLocalFallback = false;

  bool get isCloudEnabled => Firebase.apps.isNotEmpty;
  bool get isCloudHealthy => isCloudEnabled && _lastCloudError == null;
  bool get usedLocalFallback => _usedLocalFallback;
  String? get lastCloudError => _lastCloudError;

  String get cloudStatus {
    if (!isCloudEnabled) {
      final configError = FirebaseBootstrap.lastError;
      if (configError != null) {
        return 'Firebase chưa kết nối, đang dùng dữ liệu local.';
      }
      return 'Firebase chưa được cấu hình, đang dùng dữ liệu local.';
    }

    if (_lastCloudErrorCode == 'permission-denied') {
      return 'Firestore chưa cho phép đọc/ghi, đang dùng dữ liệu local.';
    }

    if (_lastCloudError != null) {
      return 'Firebase phản hồi chậm, đang hiển thị dữ liệu local.';
    }

    if (_usedLocalFallback) {
      return 'Firebase đã kết nối, hiện chưa có dữ liệu cloud.';
    }

    return 'Firebase đã kết nối.';
  }

  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    if (!await _ensureCloudReady()) {
      _usedLocalFallback = true;
      return SaveManager.instance.getLeaderboard();
    }

    try {
      final snapshot = await _runCloudRequest(
        () => FirebaseFirestore.instance
            .collection(_collectionName)
            .orderBy('score', descending: true)
            .limit(10)
            .get(),
      );

      final remoteEntries = snapshot.docs
          .map((doc) => _entryFromFirestore(doc.data()))
          .where((entry) => (entry['score'] as int) > 0)
          .toList();

      _clearCloudError();
      if (remoteEntries.isNotEmpty) {
        _usedLocalFallback = false;
        return remoteEntries;
      }

      _usedLocalFallback = true;
    } catch (error, stackTrace) {
      _rememberCloudError(error);
      _usedLocalFallback = true;
      debugPrint('Cloud leaderboard read failed: $_lastCloudError');
      if (kDebugMode) {
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    return SaveManager.instance.getLeaderboard();
  }

  Future<void> addLeaderboardEntry(String name, int score, int level) async {
    await SaveManager.instance.addLeaderboardEntry(name, score, level);

    if (!await _ensureCloudReady()) return;

    try {
      await _runCloudRequest(
        () => FirebaseFirestore.instance.collection(_collectionName).add({
          'name': _sanitizeName(name),
          'score': score,
          'level': level,
          'createdAt': FieldValue.serverTimestamp(),
        }),
        retry: false,
      );
      _clearCloudError();
    } catch (error, stackTrace) {
      _rememberCloudError(error);
      debugPrint('Cloud leaderboard write failed: $_lastCloudError');
      if (kDebugMode) {
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  Future<bool> _ensureCloudReady() async {
    if (isCloudEnabled) return true;
    return FirebaseBootstrap.initialize();
  }

  Future<T> _runCloudRequest<T>(
    Future<T> Function() request, {
    bool retry = true,
  }) async {
    try {
      return await request().timeout(_cloudTimeout);
    } catch (error) {
      if (!retry || !_isRetryableCloudError(error)) {
        rethrow;
      }

      await Future<void>.delayed(_retryDelay);
      return request().timeout(_cloudTimeout);
    }
  }

  bool _isRetryableCloudError(Object error) {
    if (error is TimeoutException) return true;
    if (error is FirebaseException) {
      return const {
        'aborted',
        'cancelled',
        'deadline-exceeded',
        'internal',
        'unavailable',
        'unknown',
      }.contains(error.code);
    }
    return false;
  }

  void _clearCloudError() {
    _lastCloudError = null;
    _lastCloudErrorCode = null;
  }

  void _rememberCloudError(Object error) {
    _lastCloudError = _formatCloudError(error);
    if (error is TimeoutException) {
      _lastCloudErrorCode = 'timeout';
    } else if (error is FirebaseException) {
      _lastCloudErrorCode = error.code;
    } else {
      _lastCloudErrorCode = null;
    }
  }

  String _formatCloudError(Object error) {
    if (error is TimeoutException) {
      return 'Firestore timeout after ${_cloudTimeout.inSeconds}s';
    }
    if (error is FirebaseException) {
      final message = error.message;
      return message == null || message.trim().isEmpty
          ? error.code
          : '${error.code}: $message';
    }
    return error.toString();
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
