import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:english_app/services/api_service.dart';

class PracticeSessionScreen extends StatefulWidget {
  final bool isDarkMode;
  final String topicTitle;
  final int topicId;

  const PracticeSessionScreen({
    super.key,
    required this.isDarkMode,
    required this.topicTitle,
    required this.topicId,
  });

  @override
  State<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends State<PracticeSessionScreen> {
  List<dynamic> speakingList = [];
  bool isLoading = true;
  int currentIndex = 0;
  bool isCompleted = false; // Biến trạng thái kiểm tra đã hoàn thành chủ đề chưa

  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  bool _isSpeechAvailable = false;
  bool _isListening = false;
  String _userSpokenText = '';
  int _calculatedScore = 0;
  String _feedbackMessage = '';
  bool _hasResult = false;

  @override
  void initState() {
    super.initState();
    _initAudioServices();
    _fetchSpeakingData();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _speechToText.stop();
    super.dispose();
  }

  // Khởi tạo Audio Services
  Future<void> _initAudioServices() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.45);

    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      debugPrint('Chưa cấp quyền Microphone!');
      return;
    }

    try {
      _isSpeechAvailable = await _speechToText.initialize(
        onError: (val) {
          debugPrint('STT Error: ${val.errorMsg}');
          if (mounted && _isListening) {
            setState(() => _isListening = false);
            _evaluateSpeaking();
          }
        },
        onStatus: (status) {
          debugPrint('STT Status: $status');
        },
      );
    } catch (e) {
      debugPrint('Khởi tạo STT thất bại: $e');
    }

    if (mounted) setState(() {});
  }

  Future<void> _fetchSpeakingData() async {
    final data = await UserApiService.getSpeakingItemsByTopic(widget.topicId);
    if (mounted) {
      setState(() {
        speakingList = data;
        isLoading = false;
      });
      if (speakingList.isNotEmpty) {
        _playSampleAudio();
      }
    }
  }

  Future<void> _playSampleAudio() async {
    if (speakingList.isEmpty || isCompleted) return;
    final String currentSentence = speakingList[currentIndex]['sentence'] ?? '';
    if (currentSentence.isNotEmpty) {
      await _flutterTts.stop();
      await _flutterTts.speak(currentSentence);
    }
  }

  // Bật / Tắt thu âm giọng nói người dùng
  Future<void> _toggleListening() async {
    if (!_isSpeechAvailable) {
      await _initAudioServices();
      if (!_isSpeechAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chưa cấp quyền Micro hoặc thiết bị không hỗ trợ nhận diện giọng nói!'),
            ),
          );
        }
        return;
      }
    }

    if (_isListening) {
      await _speechToText.stop();
      if (mounted) setState(() => _isListening = false);
      _evaluateSpeaking();
    } else {
      await _flutterTts.stop();
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      setState(() {
        _isListening = true;
        _userSpokenText = '';
        _hasResult = false;
      });

      List<stt.LocaleName> locales = await _speechToText.locales();
      String targetLocaleId = 'en_US';
      var hasEnUs = locales.any((element) => element.localeId == 'en_US');

      if (!hasEnUs) {
        var anyEn = locales.firstWhere(
              (element) => element.localeId.startsWith('en'),
          orElse: () => locales.isNotEmpty ? locales.first : stt.LocaleName('en_US', 'English'),
        );
        targetLocaleId = anyEn.localeId;
      }

      try {
        await _speechToText.listen(
          onResult: (result) {
            if (mounted) {
              setState(() {
                _userSpokenText = result.recognizedWords;
              });
              if (result.finalResult) {
                setState(() => _isListening = false);
                _evaluateSpeaking();
              }
            }
          },
          listenOptions: stt.SpeechListenOptions(
            localeId: targetLocaleId,
            listenFor: const Duration(seconds: 15),
            pauseFor: const Duration(seconds: 4),
            partialResults: true,
            cancelOnError: false,
            listenMode: stt.ListenMode.deviceDefault,
          ),
        );
      } catch (e) {
        debugPrint("Lỗi khi listen: $e");
        if (mounted) setState(() => _isListening = false);
      }
    }
  }

  void _evaluateSpeaking() {
    if (_userSpokenText.trim().isEmpty) {
      setState(() {
        _calculatedScore = 0;
        _feedbackMessage = 'Chưa ghi nhận được giọng nói. Bấm micro và thử lại nhé!';
        _hasResult = true;
      });
      return;
    }

    final String targetText = speakingList[currentIndex]['sentence'] ?? '';

    String cleanTarget = targetText.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    String cleanUser = _userSpokenText.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');

    List<String> targetWords = cleanTarget.split(RegExp(r'\s+'));
    List<String> userWords = cleanUser.split(RegExp(r'\s+'));

    int matchCount = 0;
    for (var word in userWords) {
      if (targetWords.contains(word)) {
        matchCount++;
      }
    }

    double ratio = matchCount / targetWords.length;
    int score = (ratio * 100).round();
    if (score > 100) score = 100;

    String feedback = '';
    if (score >= 90) {
      feedback = 'Xuất sắc! Phát âm rất chuẩn xác và rõ ràng 🎉';
    } else if (score >= 70) {
      feedback = 'Khá tốt! Bạn phát âm đúng hầu hết các từ 👍';
    } else if (score >= 40) {
      feedback = 'Tạm ổn! Cần chú ý phát âm rõ chữ hơn nữa 😃';
    } else {
      feedback = 'Chưa chính xác lắm. Bấm loa nghe lại mẫu và thử lại nhé 💪';
    }

    setState(() {
      _calculatedScore = score;
      _feedbackMessage = feedback;
      _hasResult = true;
    });
  }

  void _nextSentence() {
    if (currentIndex < speakingList.length - 1) {
      setState(() {
        currentIndex++;
        _userSpokenText = '';
        _hasResult = false;
        _isListening = false;
        if (currentIndex == speakingList.length - 1) {
          // Có thể bật cờ trạng thái nếu cần
        }
      });
      _playSampleAudio();
    } else {
      setState(() {
        isCompleted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = widget.isDarkMode ? Colors.grey.shade400 : const Color(0xFF64748B);
    final cardBgColor = widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    if (isLoading) {
      return Scaffold(
        backgroundColor: widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(widget.topicTitle, style: TextStyle(color: textColor)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (speakingList.isEmpty) {
      return Scaffold(
        backgroundColor: widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(widget.topicTitle, style: TextStyle(color: textColor)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Text('Chưa có câu mẫu luyện nói nào.', style: TextStyle(color: textColor)),
        ),
      );
    }

    // Giao diện khi hoàn thành toàn bộ chủ đề (Đồng bộ với VocabularyDetailScreen)
    if (isCompleted) {
      return Scaffold(
        backgroundColor: widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(widget.topicTitle, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          iconTheme: IconThemeData(color: textColor),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.verified_rounded, color: Colors.green, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Tuyệt vời!',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bạn đã hoàn thành xuất sắc chủ đề luyện nói "${widget.topicTitle}".',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: subtitleColor),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Hoàn thành Chủ đề ✅',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    }

    final currentData = speakingList[currentIndex];

    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          widget.topicTitle,
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 18),
        ),
        actions: [
          IconButton(
            onPressed: _playSampleAudio,
            icon: const Icon(Icons.volume_up_rounded, color: Colors.indigo, size: 28),
            tooltip: 'Nghe lại mẫu AI',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Thanh tiến trình đồng bộ giao diện
            LinearProgressIndicator(
              value: (currentIndex + 1) / speakingList.length,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.indigo),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Câu ${currentIndex + 1} / ${speakingList.length}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),

            // Card chi tiết câu luyện nói
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Mẫu câu chuẩn',
                          style: TextStyle(fontSize: 11, color: Colors.indigo, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '"${currentData['sentence']}"',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor, height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        currentData['translation'] ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: subtitleColor, fontStyle: FontStyle.italic),
                      ),
                      if ((currentData['phonetic'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          currentData['phonetic'],
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.purple.shade400, fontFamily: 'monospace'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Phần hiển thị kết quả đọc của user
            if (_userSpokenText.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  'Bạn vừa đọc: "$_userSpokenText"',
                  style: TextStyle(fontSize: 13, color: textColor, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),

            if (_hasResult) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _calculatedScore >= 70 ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _calculatedScore >= 70 ? Colors.green.shade200 : Colors.orange.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _calculatedScore >= 70 ? Icons.verified_rounded : Icons.warning_amber_rounded,
                          color: _calculatedScore >= 70 ? Colors.green : Colors.orange.shade800,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Độ khớp AI: $_calculatedScore/100 điểm',
                          style: TextStyle(
                            color: _calculatedScore >= 70 ? Colors.green : Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _feedbackMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: _calculatedScore >= 70 ? Colors.green.shade800 : Colors.orange.shade900,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Nút Micro thu âm chính giữa
            Center(
              child: GestureDetector(
                onTap: _toggleListening,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _isListening ? 80 : 70,
                  height: _isListening ? 80 : 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isListening
                          ? [Colors.red.shade400, Colors.red.shade700]
                          : [const Color(0xFF4F46E5), const Color(0xFF7C3AED)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening ? Colors.red : Colors.purple).withValues(alpha: 0.4),
                        blurRadius: _isListening ? 20 : 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isListening ? 'Đang lắng nghe... Chạm để dừng' : 'Nhấn vào micro để đọc theo AI',
              style: TextStyle(
                fontSize: 13,
                color: _isListening ? Colors.redAccent : subtitleColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Nút Câu tiếp theo / Hoàn thành giống hệt VocabularyDetailScreen
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextSentence,
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentIndex == speakingList.length - 1 ? Colors.green : Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  currentIndex == speakingList.length - 1 ? 'Hoàn thành Chủ đề ✅' : 'Câu tiếp theo 👉',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}