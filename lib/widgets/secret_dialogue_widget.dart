import 'package:flutter/material.dart';
import 'package:pixel_adventure/pixel_adventure.dart';
import 'package:pixel_adventure/services/gemini_attitude_service.dart';

class SecretDialogueWidget extends StatefulWidget {
  final PixelAdventure game;

  const SecretDialogueWidget({super.key, required this.game});

  @override
  State<SecretDialogueWidget> createState() => _SecretDialogueWidgetState();
}

class _SecretDialogueWidgetState extends State<SecretDialogueWidget> {
  static const _easterEgg = 'tvy';
  static const _easterEggReadDelay = Duration(seconds: 3);
  static const _aiResultReadDelay = Duration(seconds: 4);
  static const _openingLine =
      'chào nhà phiêu lưu, ngài đã vượt qua 11 thử thách của ta, ngài cảm thấy như thế nào?';

  final _controller = TextEditingController();
  final _gemini = GeminiAttitudeService();

  bool _thinking = false;
  bool _resolved = false;
  String _npcText = _openingLine;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _resolveAfterDelay(Duration delay, {required bool passed}) {
    Future.delayed(delay, () {
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      widget.game.resolveSecretDialogue(passed: passed);
    });
  }

  Future<void> _submit() async {
    final message = _controller.text.trim();
    if (message.isEmpty || _thinking || _resolved) return;

    if (message.toLowerCase().contains(_easterEgg)) {
      setState(() {
        _resolved = true;
        _npcText = 'mày thích var à?';
      });
      _resolveAfterDelay(_easterEggReadDelay, passed: false);
      return;
    }

    setState(() {
      _thinking = true;
      _npcText = 'Để ta xem thái độ của ngài...';
    });

    final result = await _gemini.evaluate(message);
    if (!mounted) return;

    final fallbackNote = result.usedFallback
        ? ' Ta đang dùng đánh giá offline (${result.fallbackCause}).'
        : '';
    if (result.score <= 3) {
      setState(() {
        _thinking = false;
        _resolved = true;
        _npcText =
            'Điểm thái độ: ${result.score}/5. ${result.reason}$fallbackNote Boss sẽ xuất hiện.';
      });
      _resolveAfterDelay(_aiResultReadDelay, passed: false);
    } else {
      setState(() {
        _thinking = false;
        _resolved = true;
        _npcText =
            'Điểm thái độ: ${result.score}/5. ${result.reason}$fallbackNote Ta cho ngài qua màn.';
      });
      _resolveAfterDelay(_aiResultReadDelay, passed: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withAlpha(110),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 720,
                  maxHeight: constraints.maxHeight - 20,
                ),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF211F30),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF5B4EC8),
                      width: 2,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/Secret/npc.png',
                            width: 92,
                            height: 92,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Người giữ cổng',
                                style: TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _npcText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _controller,
                                      enabled: !_thinking && !_resolved,
                                      onSubmitted: (_) => _submit(),
                                      style:
                                          const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        hintText: 'Nói với NPC...',
                                        hintStyle: const TextStyle(
                                          color: Colors.white38,
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFF2E2C45),
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    height: 44,
                                    child: ElevatedButton.icon(
                                      onPressed: (_thinking || _resolved)
                                          ? null
                                          : _submit,
                                      icon: _thinking
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.record_voice_over),
                                      label: Text(_thinking ? 'Đợi' : 'Nói'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF5B4EC8),
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor:
                                            const Color(0xFF3A374F),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
