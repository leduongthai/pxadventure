import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AttitudeResult {
  final int score;
  final String reason;
  final bool usedFallback;
  final String? fallbackCause;

  const AttitudeResult({
    required this.score,
    required this.reason,
    this.usedFallback = false,
    this.fallbackCause,
  });
}

class GeminiAttitudeService {
  String get _apiKey =>
      dotenv.env['GEMINI_API_KEY'] ??
      const String.fromEnvironment('GEMINI_API_KEY');

  String get _model =>
      dotenv.env['GEMINI_MODEL'] ??
      const String.fromEnvironment(
        'GEMINI_MODEL',
        defaultValue: 'gemini-2.0-flash',
      );

  Future<AttitudeResult> evaluate(String message) async {
    final toxicResult = _hardToxicityCheck(message);
    if (toxicResult != null) return toxicResult;

    if (_apiKey.trim().isEmpty) {
      return _fallbackEvaluate(
        message,
        fallbackCause: 'missing GEMINI_API_KEY',
      );
    }

    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$_model:generateContent',
      {'key': _apiKey},
    );

    try {
      final response = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {
                      'text': '''
Bạn là NPC giữ cổng của một màn chơi bí mật trong game platformer.
Hãy đánh giá thái độ của người chơi dựa trên tin nhắn sau, rồi trả lời như chính NPC đang nói trực tiếp với người chơi.

Luật chấm điểm nội bộ:
1 = xúc phạm rõ ràng, chửi thề, toxic, công kích game/NPC/người khác.
2 = cộc lốc, khó chịu, thiếu tôn trọng, ra lệnh.
3 = trung tính nhưng chưa thân thiện.
4 = lịch sự, hợp tác, thái độ tốt.
5 = rất thân thiện, hài hước, tích cực.

Quy tắc bắt buộc:
- Từ chửi hoặc viết tắt tục trong tiếng Việt như "cc", "cl", "dm", "đm",
  "dmm", "vcl", "vl", "cặc", "lồn", "địt" luôn phải bị chấm 1 hoặc 2.
- Câu chê kiểu "game như cc", "map như cc", "boss như cc" phải là 1/5.
- Không được chấm 3 cho câu có từ tục, kể cả câu đó ngắn hoặc viết tắt.

Quy tắc lời thoại:
- "reason" phải là một câu NPC nói tự nhiên, không phải lời giải thích hệ thống.
- Không nhắc đến điểm số, thang điểm, AI, Gemini, API, offline, lỗi, đánh giá, hoặc JSON.
- Nếu score <= 3, lời thoại nên thể hiện NPC không hài lòng và sắp thử thách người chơi.
- Nếu score >= 4, lời thoại nên thể hiện NPC hài lòng và cho người chơi đi tiếp.

Chỉ trả về JSON hợp lệ đúng dạng:
{"score":4,"reason":"Nghe có vẻ ngài thật sự đã trưởng thành. Ta cho ngài đi tiếp."}

Tin nhắn người chơi: "$message"
''',
                    },
                  ],
                },
              ],
              'generationConfig': {
                'temperature': 0.4,
                'responseMimeType': 'application/json',
              },
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _fallbackEvaluate(
          message,
          fallbackCause: 'HTTP ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = decoded['candidates'] as List<dynamic>?;
      final firstCandidate =
          candidates == null || candidates.isEmpty ? null : candidates.first;
      final content = firstCandidate is Map<String, dynamic>
          ? firstCandidate['content'] as Map<String, dynamic>?
          : null;
      final parts = content?['parts'] as List<dynamic>?;
      final firstPart = parts == null || parts.isEmpty ? null : parts.first;
      final text = firstPart is Map<String, dynamic>
          ? firstPart['text']?.toString() ?? ''
          : '';

      return _parseGeminiText(text) ??
          _fallbackEvaluate(
            message,
            fallbackCause: 'unreadable Gemini response',
          );
    } catch (error) {
      return _fallbackEvaluate(
        message,
        fallbackCause: error.runtimeType.toString(),
      );
    }
  }

  AttitudeResult? _hardToxicityCheck(String message) {
    final normalized = _normalize(message);
    final severePatterns = [
      RegExp(r'(^|[^a-z0-9])c{2,}([^a-z0-9]|$)'),
      RegExp(r'(^|[^a-z0-9])(dm|dmm|cl|vl|vcl)([^a-z0-9]|$)'),
      RegExp(r'\b(cac|lon|dit|du|fuck|shit)\b'),
      RegExp(r'\b(game|map|boss|npc|man)\s+(nhu|la|qua)\s+(cc|cac|rac|shit)\b'),
      RegExp(r'\b(nhu|la)\s+(cc|cac|rac|shit)\b'),
    ];

    if (severePatterns.any((pattern) => pattern.hasMatch(normalized))) {
      return const AttitudeResult(
        score: 1,
        reason: 'Mày nói vậy là muốn gặp anh tao rồi đó.',
      );
    }

    final rudePatterns = [
      RegExp(r'\b(ngu|cam|im|ghet|rac|toxic|trash|hate|stupid)\b'),
      RegExp(r'\b(do|te|chan)\s+(qua|vai|vcl)\b'),
    ];

    if (rudePatterns.any((pattern) => pattern.hasMatch(normalized))) {
      return const AttitudeResult(
        score: 2,
        reason: 'Nói chuyện kiểu đó thì ta không cho qua dễ vậy đâu.',
      );
    }

    return null;
  }

  AttitudeResult? _parseGeminiText(String text) {
    try {
      final decoded = jsonDecode(text.trim()) as Map<String, dynamic>;
      final score = (decoded['score'] as num).round().clamp(1, 5);
      final reason = decoded['reason']?.toString().trim();
      if (reason == null || reason.isEmpty) return null;
      return AttitudeResult(score: score, reason: reason);
    } catch (_) {
      return null;
    }
  }

  AttitudeResult _fallbackEvaluate(
    String message, {
    required String fallbackCause,
  }) {
    final toxicResult = _hardToxicityCheck(message);
    if (toxicResult != null) return toxicResult;

    final lower = _normalize(message);
    final kindWords = [
      'xin',
      'cam on',
      'vui',
      'giup',
      'lam on',
      'please',
      'thanks',
      'hello',
      'chao',
      'hay',
    ];

    if (kindWords.any(lower.contains)) {
      return AttitudeResult(
        score: 4,
        reason: 'Nghe cũng có thành ý đấy. Ta cho ngài đi tiếp.',
        usedFallback: true,
        fallbackCause: fallbackCause,
      );
    }

    return AttitudeResult(
      score: 3,
      reason: 'Câu trả lời đó chưa đủ làm ta tin. Chứng minh bằng sức mạnh đi.',
      usedFallback: true,
      fallbackCause: fallbackCause,
    );
  }

  String _normalize(String input) {
    var value = input.toLowerCase();
    const replacements = {
      'à': 'a',
      'á': 'a',
      'ạ': 'a',
      'ả': 'a',
      'ã': 'a',
      'â': 'a',
      'ầ': 'a',
      'ấ': 'a',
      'ậ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ă': 'a',
      'ằ': 'a',
      'ắ': 'a',
      'ặ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'è': 'e',
      'é': 'e',
      'ẹ': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ê': 'e',
      'ề': 'e',
      'ế': 'e',
      'ệ': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ì': 'i',
      'í': 'i',
      'ị': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ò': 'o',
      'ó': 'o',
      'ọ': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ô': 'o',
      'ồ': 'o',
      'ố': 'o',
      'ộ': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ơ': 'o',
      'ờ': 'o',
      'ớ': 'o',
      'ợ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ù': 'u',
      'ú': 'u',
      'ụ': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ư': 'u',
      'ừ': 'u',
      'ứ': 'u',
      'ự': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ỳ': 'y',
      'ý': 'y',
      'ỵ': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'đ': 'd',
    };
    for (final entry in replacements.entries) {
      value = value.replaceAll(entry.key, entry.value);
    }
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
