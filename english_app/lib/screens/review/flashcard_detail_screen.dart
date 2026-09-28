import 'package:flutter/material.dart';
import 'package:english_app/services/api_service.dart'; // Sử dụng đúng UserApiService đã có

class FlashcardScreen extends StatefulWidget {
  final bool isDarkMode;
  final String level;
  final String topicTitle;
  final int? topicId; // Nhận thêm topicId để query C# API chuẩn xác

  const FlashcardScreen({
    super.key,
    required this.isDarkMode,
    required this.level,
    required this.topicTitle,
    this.topicId,
  });

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  int currentIndex = 0;
  bool isFlipped = false;
  bool isLoading = true;
  List<Map<String, String>> currentList = [];

  // Dữ liệu mẫu fallback theo tên chủ đề nếu không gọi được API
  final Map<String, List<Map<String, String>>> fallbackData = {
    'Giao tiếp hàng ngày': [
      {'word': 'Hello', 'phonetic': '/həˈloʊ/', 'meaning': 'Xin chào'},
      {'word': 'Thank you', 'phonetic': '/ˈθæŋk juː/', 'meaning': 'Cảm ơn bạn'},
      {'word': 'Goodbye', 'phonetic': '/ɡʊdˈbaɪ/', 'meaning': 'Tạm biệt'},
    ],
    'Ngoài đời thực': [
      {'word': 'Street', 'phonetic': '/striːt/', 'meaning': 'Đường phố'},
      {'word': 'Market', 'phonetic': '/ˈmɑːr.kɪt/', 'meaning': 'Chợ'},
      {'word': 'Weather', 'phonetic': '/ˈweð.ɚ/', 'meaning': 'Thời tiết'},
    ],
    'Chào hỏi cơ bản': [
      {'word': 'Morning', 'phonetic': '/ˈmɔːr.nɪŋ/', 'meaning': 'Buổi sáng'},
      {'word': 'Nice to meet you', 'phonetic': '/naɪs tuː miːt juː/', 'meaning': 'Rất vui được gặp bạn'},
      {'word': 'How are you?', 'phonetic': '/haʊ ɑːr juː/', 'meaning': 'Bạn khỏe không?'},
    ],
    'Giao tiếp trong công sở': [
      {'word': 'Collaborate', 'phonetic': '/kəˈlæb.ə.reɪt/', 'meaning': 'Hợp tác'},
      {'word': 'Meeting', 'phonetic': '/ˈmiː.tɪŋ/', 'meaning': 'Cuộc họp'},
      {'word': 'Deadline', 'phonetic': '/ˈded.laɪn/', 'meaning': 'Hạn chót công việc'},
    ],
    'Thảo luận nhóm': [
      {'word': 'Opinion', 'phonetic': '/əˈpɪn.jən/', 'meaning': 'Ý kiến'},
      {'word': 'Feedback', 'phonetic': '/ˈfiːd.bæk/', 'meaning': 'Phản hồi'},
      {'word': 'Strategy', 'phonetic': '/ˈstræt.ə.dʒi/', 'meaning': 'Chiến lược'},
    ],
    'Thuyết trình cơ bản': [
      {'word': 'Presentation', 'phonetic': '/ˌprez.ənˈteɪ.ʃən/', 'meaning': 'Bài thuyết trình'},
      {'word': 'Slide', 'phonetic': '/slaɪd/', 'meaning': 'Trang chiếu'},
      {'word': 'Audience', 'phonetic': '/ˈɔː.di.əns/', 'meaning': 'Khán thính giả'},
    ],
    'Đàm phán thương mại': [
      {'word': 'Negotiation', 'phonetic': '/nɪˌɡoʊ.ʃiˈeɪ.ʃən/', 'meaning': 'Sự đàm phán'},
      {'word': 'Contract', 'phonetic': '/ˈkɑːn.trækt/', 'meaning': 'Hợp đồng'},
      {'word': 'Agreement', 'phonetic': '/əˈɡriː.mənt/', 'meaning': 'Thỏa thuận'},
    ],
    'Từ vựng chuyên ngành': [
      {'word': 'Meticulous', 'phonetic': '/məˈtɪk.jə.ləs/', 'meaning': 'Tỉ mỉ, kỹ càng'},
      {'word': 'Pragmatic', 'phonetic': '/præɡˈmæt.ɪk/', 'meaning': 'Thực tế'},
      {'word': 'Innovative', 'phonetic': '/ˈɪn.ə.veɪ.tɪv/', 'meaning': 'Mang tính đổi mới'},
    ],
    'Học thuật nâng cao': [
      {'word': 'Ubiquitous', 'phonetic': '/juːˈbɪk.wɪ.təs/', 'meaning': 'Có mặt khắp mọi nơi'},
      {'word': 'Comprehensive', 'phonetic': '/ˌkɑːm.prɪˈhen.sɪv/', 'meaning': 'Toàn diện'},
      {'word': 'Hypothesis', 'phonetic': '/haɪˈpɑː.θə.sɪs/', 'meaning': 'Giả thuyết'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _fetchFlashcardsFromApi();
  }

  Future<void> _fetchFlashcardsFromApi() async {
    setState(() => isLoading = true);
    try {
      final int targetId = widget.topicId ?? 1;
      // Gọi API lấy flashcards/vocabulary theo topicId
      final List<dynamic> data = await UserApiService.getFlashcardsByTopicId(targetId);

      if (data.isNotEmpty) {
        setState(() {
          currentList = data.map<Map<String, String>>((item) => {
            'word': item['word']?.toString() ?? '',
            'phonetic': item['phonetic']?.toString() ?? '/.../',
            'meaning': item['meaning']?.toString() ?? '',
          }).toList();
          isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Lỗi kết nối API Flashcard: $e');
    }

    // Dùng dữ liệu fallback nếu gọi API thất bại hoặc trống
    setState(() {
      currentList = fallbackData[widget.topicTitle] ?? [
        {'word': 'Sample 1', 'phonetic': '/ˈsæm.pəl 1/', 'meaning': 'Nghĩa mẫu 1'},
        {'word': 'Sample 2', 'phonetic': '/ˈsæm.pəl 2/', 'meaning': 'Nghĩa mẫu 2'},
      ];
      isLoading = false;
    });
  }

  void _nextCard(int totalLength) {
    if (totalLength == 0) {
      Navigator.pop(context, true);
      return;
    }
    if (currentIndex < totalLength - 1) {
      setState(() {
        currentIndex++;
        isFlipped = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Chúc mừng bạn đã hoàn thành chủ đề này! Cấp độ tiếp theo đã được mở.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  void _toggleFlip() {
    setState(() {
      isFlipped = !isFlipped;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = widget.isDarkMode ? Colors.grey.shade400 : const Color(0xFF64748B);
    final cardBgColor = widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

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
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : currentList.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sentiment_dissatisfied, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('Chưa có từ vựng nào trong chủ đề này.', style: TextStyle(color: subtitleColor)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const QuayLaiText(),
            )
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Từ ${currentIndex + 1} / ${currentList.length}', style: TextStyle(color: subtitleColor, fontWeight: FontWeight.bold)),
                Text('🔥 ${widget.level}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: currentList.isNotEmpty ? (currentIndex + 1) / currentList.length : 0.0,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const Spacer(),

            // THẺ FLASHCARD
            GestureDetector(
              onTap: _toggleFlip,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                height: 320,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isFlipped ? Colors.green.shade200 : borderColor, width: isFlipped ? 2 : 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Chủ đề: ${widget.topicTitle}', style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),

                    Text(
                      currentList.isNotEmpty && currentIndex < currentList.length
                          ? currentList[currentIndex]['word']!
                          : '',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textColor),
                      textAlign: TextAlign.center,
                    ),

                    if (isFlipped && currentList.isNotEmpty && currentIndex < currentList.length) ...[
                      const SizedBox(height: 12),
                      Text(
                        currentList[currentIndex]['phonetic']!,
                        style: TextStyle(fontSize: 16, color: subtitleColor, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 16),
                      Divider(color: borderColor),
                      const SizedBox(height: 12),
                      Text(
                        currentList[currentIndex]['meaning']!,
                        style: TextStyle(fontSize: 20, color: Colors.green.shade700, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const Spacer(),
                    Icon(
                        isFlipped ? Icons.autorenew_rounded : Icons.touch_app_rounded,
                        color: Colors.grey,
                        size: 28
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isFlipped ? 'Nhấn để ẩn nghĩa' : 'Nhấn để xem nghĩa',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    )
                  ],
                ),
              ),
            ),
            const Spacer(),

            // NÚT TƯƠNG TÁC (CHƯA NHỚ / ĐÃ NHỚ)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _nextCard(currentList.length),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Chưa nhớ',
                      style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _nextCard(currentList.length),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Đã nhớ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Widget nhỏ thay thế text nút quay lại nếu list rỗng
class QuayLaiText extends StatelessWidget {
  const QuayLaiText({super.key});
  @override
  Widget build(BuildContext context) => const Text('Quay lại');
}