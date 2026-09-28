import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:english_app/services/api_service.dart';

class ListeningPlayerScreen extends StatefulWidget {
  final bool isDarkMode;
  final String topicTitle;
  final int topicId;
  final bool initialCompleted;

  const ListeningPlayerScreen({
    super.key,
    required this.isDarkMode,
    required this.topicTitle,
    required this.topicId,
    this.initialCompleted = false,
  });

  @override
  State<ListeningPlayerScreen> createState() => _ListeningPlayerScreenState();
}

class _ListeningPlayerScreenState extends State<ListeningPlayerScreen> {
  final FlutterTts flutterTts = FlutterTts();
  List<dynamic> items = [];
  bool isLoading = true;
  bool isSpeaking = false;
  late bool isCompleted;
  bool _markCompletedCalled = false;

  @override
  void initState() {
    super.initState();
    isCompleted = widget.initialCompleted;
    _initTts();
    _fetchListeningItems();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() => isSpeaking = false);
        // Tự động đánh dấu hoàn thành khi TTS đọc xong toàn bộ bài
        if (!_markCompletedCalled) {
          _markCompleted();
        }
      }
    });
  }

  Future<void> _markCompleted() async {
    if (_markCompletedCalled) return;
    _markCompletedCalled = true;

    setState(() => isCompleted = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('comp_${widget.topicTitle}', true);
  }

  Future<void> _fetchListeningItems() async {
    setState(() => isLoading = true);
    final data = await UserApiService.getListeningItemsByTopic(widget.topicId);
    if (mounted) {
      setState(() {
        items = data;
        isLoading = false;
      });
    }
  }

  Future<void> _speakText(String text) async {
    if (isSpeaking) {
      await flutterTts.stop();
      setState(() => isSpeaking = false);
    } else {
      setState(() => isSpeaking = true);
      await flutterTts.speak(text);
    }
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = widget.isDarkMode ? Colors.grey.shade400 : const Color(0xFF64748B);
    final cardBgColor = widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    // Gộp toàn bộ transcript để dùng cho nút phát tổng
    final combinedTranscript = items.map((x) => x['transcript'] ?? '').join(' ');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        Navigator.of(context).pop(isCompleted);
      },
      child: Scaffold(
        backgroundColor: widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: textColor),
            onPressed: () => Navigator.of(context).pop(isCompleted),
          ),
          title: Text(
            widget.topicTitle,
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 18),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Controller đọc tổng toàn bài bằng TTS
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    IconButton(
                      iconSize: 56,
                      icon: Icon(
                        isSpeaking ? Icons.volume_up_rounded : Icons.headphones_rounded,
                        color: Colors.blue,
                      ),
                      onPressed: combinedTranscript.isEmpty
                          ? null
                          : () => _speakText(combinedTranscript),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isSpeaking ? 'Đang đọc toàn bài...' : 'Nhấn để nghe toàn bộ bài',
                      style: TextStyle(color: subtitleColor, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () async {
                            await _markCompleted();

                            // Kiểm tra mounted sau khoảng chờ bất đồng bộ của _markCompleted()
                            if (!mounted) return;
                            Navigator.of(context).pop(isCompleted);
                          },
                          child: const Text('Đánh dấu hoàn thành bài nghe', style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Danh sách câu nội Transcript kèm nút phát từng dòng
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.text_snippet_rounded, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Nội dung hội thoại (Transcript)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    items.isEmpty
                        ? Text('Chưa có câu hội thoại nào trong chủ đề này.', style: TextStyle(color: subtitleColor))
                        : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 24),
                      itemBuilder: (context, index) {
                        final text = items[index]['transcript'] ?? '';
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.volume_up_outlined, color: Colors.blue, size: 20),
                              onPressed: () => _speakText(text),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                text,
                                style: TextStyle(fontSize: 15, color: textColor, height: 1.5),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (!isCompleted)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _markCompleted,
                  child: const Text('Đánh dấu hoàn thành bài nghe', style: TextStyle(fontWeight: FontWeight.bold)),
                )
              else
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.green),
                    SizedBox(width: 6),
                    Text('Đã hoàn thành bài nghe!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}