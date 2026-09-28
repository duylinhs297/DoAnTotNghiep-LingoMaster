import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:translator/translator.dart';
import 'package:english_app/services/api_service.dart';

class VocabularyDetailScreen extends StatefulWidget {
  final bool isDarkMode;
  final String categoryTitle;
  final int topicId;

  const VocabularyDetailScreen({
    super.key,
    required this.isDarkMode,
    required this.categoryTitle,
    required this.topicId,
  });

  @override
  State<VocabularyDetailScreen> createState() => _VocabularyDetailScreenState();
}

class _VocabularyDetailScreenState extends State<VocabularyDetailScreen> {
  List<dynamic> vocabularyList = [];
  bool isLoading = true;
  int currentIndex = 0;
  bool isCompleted = false;

  // Khai báo FlutterTts và GoogleTranslator
  final FlutterTts flutterTts = FlutterTts();
  final GoogleTranslator translator = GoogleTranslator();

  // Biến lưu trữ bản dịch của ví dụ hiện tại
  String translatedExample = '';
  bool isTranslating = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadVocabularyData();
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  // Cấu hình ban đầu cho Flutter TTS
  Future<void> _initTts() async {
    await flutterTts.setSpeechRate(0.45); // Tốc độ đọc vừa phải
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  // Hàm phát âm theo ngôn ngữ
  Future<void> _speak(String text, String languageCode) async {
    if (text.isEmpty) return;
    await flutterTts.stop();
    await flutterTts.setLanguage(languageCode);
    await flutterTts.speak(text);
  }

  // Fetch dữ liệu từ API và tự dịch ví dụ của từ đầu tiên
  Future<void> _loadVocabularyData() async {
    final data = await UserApiService.getVocabItemsByTopic(widget.topicId);
    if (mounted) {
      setState(() {
        vocabularyList = data;
        isLoading = false;
      });
      if (vocabularyList.isNotEmpty) {
        _translateCurrentExample();
      }
    }
  }

  // Hàm tự động dịch ví dụ sang tiếng Việt
  Future<void> _translateCurrentExample() async {
    if (vocabularyList.isEmpty) return;
    final currentItem = vocabularyList[currentIndex];
    final String rawExample = (currentItem['example'] ?? '').toString();

    if (rawExample.trim().isEmpty) {
      setState(() {
        translatedExample = '';
      });
      return;
    }

    setState(() => isTranslating = true);
    try {
      final translation = await translator.translate(rawExample, from: 'en', to: 'vi');
      if (mounted) {
        setState(() {
          translatedExample = translation.text;
          isTranslating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          translatedExample = 'Không thể tự động dịch ví dụ.';
          isTranslating = false;
        });
      }
    }
  }

  void _nextWord() {
    if (currentIndex < vocabularyList.length - 1) {
      setState(() {
        currentIndex++;
        if (currentIndex == vocabularyList.length - 1) {
          isCompleted = true;
        }
      });
      _translateCurrentExample();
    } else {
      setState(() {
        isCompleted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final cardBgColor = widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    if (isLoading) {
      return Scaffold(
        backgroundColor: widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(widget.categoryTitle, style: TextStyle(color: textColor)),
          iconTheme: IconThemeData(color: textColor),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (vocabularyList.isEmpty) {
      return Scaffold(
        backgroundColor: widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(widget.categoryTitle, style: TextStyle(color: textColor)),
          iconTheme: IconThemeData(color: textColor),
        ),
        body: Center(
          child: Text('Không có dữ liệu từ vựng cho chủ đề này.', style: TextStyle(color: textColor)),
        ),
      );
    }

    final currentItem = vocabularyList[currentIndex];
    final String word = currentItem['word'] ?? '';
    final String phonetic = currentItem['phonetic'] ?? '';
    final String meaning = currentItem['meaning'] ?? '';
    final String example = (currentItem['example'] ?? '').toString();

    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.categoryTitle,
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 18),
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Thanh tiến trình
            LinearProgressIndicator(
              value: (currentIndex + 1) / vocabularyList.length,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.indigo),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Từ ${currentIndex + 1} / ${vocabularyList.length}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),

            // Card chi tiết từ vựng
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
                      // 1. TỪ VỰNG TIẾNG ANH + LOA ĐỌC
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              word,
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.volume_up_rounded, color: Colors.indigo, size: 28),
                            onPressed: () => _speak(word, 'en-US'),
                          ),
                        ],
                      ),
                      if (phonetic.isNotEmpty)
                        Text(
                          phonetic,
                          style: const TextStyle(fontSize: 16, color: Colors.indigo, fontWeight: FontWeight.w600),
                        ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // 2. NGHĨA TIẾNG VIỆT + LOA ĐỌC
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              meaning,
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textColor),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.volume_up_outlined, color: Colors.indigo, size: 22),
                            onPressed: () => _speak(meaning, 'vi-VN'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 3. VÍ DỤ TIẾNG ANH VÀ BẢN DỊCH TỰ ĐỘNG
                      if (example.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              // Ví dụ tiếng Anh
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Ví dụ: "$example"',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.indigo,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _speak(example, 'en-US'),
                                    child: const Padding(
                                      padding: EdgeInsets.only(left: 6.0),
                                      child: Icon(Icons.volume_up_rounded, color: Colors.indigo, size: 20),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Divider(height: 1),
                              const SizedBox(height: 10),

                              // Nghĩa tiếng Việt tự động dịch của ví dụ
                              isTranslating
                                  ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                                  : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Dịch: "$translatedExample"',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: widget.isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _speak(translatedExample, 'vi-VN'),
                                    child: const Padding(
                                      padding: EdgeInsets.only(left: 6.0),
                                      child: Icon(Icons.volume_up_outlined, color: Colors.grey, size: 18),
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
            const SizedBox(height: 20),

            // Nút chuyển từ
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (!isCompleted) {
                    _nextWord();
                  } else {
                    Navigator.pop(context, true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted ? Colors.green : Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  isCompleted ? 'Hoàn thành Chủ đề ✅' : 'Từ tiếp theo 👉',
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