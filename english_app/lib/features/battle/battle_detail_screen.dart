import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class BattleDetailScreen extends StatefulWidget {
  final bool isDarkMode;
  final int userId;
  final dynamic stageId;
  final String stageTitle;
  final int questionsCount;
  final String timeLimit;
  final Color themeColor;

  const BattleDetailScreen({
    super.key,
    required this.isDarkMode,
    required this.userId,
    required this.stageId,
    required this.stageTitle,
    required this.questionsCount,
    required this.timeLimit,
    required this.themeColor,
  });

  @override
  State<BattleDetailScreen> createState() => _BattleDetailScreenState();
}

class _BattleDetailScreenState extends State<BattleDetailScreen> {
  int currentQuestionIndex = 0;
  bool isFinished = false;
  bool isLoading = true;

  Timer? _timer;
  int _secondsRemaining = 20;
  int _totalElapsedSeconds = 0;

  List<dynamic> questions = [];
  late List<int> userAnswers;

  @override
  void initState() {
    super.initState();
    _parseTimeLimit();
    _loadQuestions();
  }

  void _parseTimeLimit() {
    final parsed = int.tryParse(widget.timeLimit.replaceAll(RegExp(r'[^0-9]'), ''));
    _secondsRemaining = (parsed != null && parsed > 0) ? parsed : 20;
  }

  Future<void> _loadQuestions() async {
    setState(() => isLoading = true);
    final data = await UserApiService.getBattleQuestions(widget.stageId);
    if (mounted) {
      data.shuffle();

      setState(() {
        questions = data;
        userAnswers = List<int>.filled(questions.length, -1);
        isLoading = false;
      });
      if (questions.isNotEmpty) {
        _startTimer();
      }
    }
  }

  int get totalQuestions => questions.length;

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
          _totalElapsedSeconds++;
        });
      } else {
        _nextOrFinish();
      }
    });
  }

  void _nextOrFinish() {
    _parseTimeLimit();
    if (currentQuestionIndex < totalQuestions - 1) {
      setState(() {
        currentQuestionIndex++;
      });
      _startTimer();
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    _timer?.cancel();
    setState(() {
      isFinished = true;
    });

    _submitResultToServer();
  }

  Future<void> _submitResultToServer() async {
    int finalScore = totalQuestions > 0 ? ((correctCount * 10) / totalQuestions).round() : 0;

    await UserApiService.submitBattleResult(
      widget.stageId.toString(),
      widget.userId,
      finalScore,
      _totalElapsedSeconds,
    );
  }

  void _answerQuestion(int selectedIndex) {
    userAnswers[currentQuestionIndex] = selectedIndex;
    _nextOrFinish();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get correctCount {
    int count = 0;
    for (int i = 0; i < totalQuestions; i++) {
      if (i < userAnswers.length && i < questions.length) {
        final correctAnswer = questions[i]['correctAnswerIndex'] ?? 0;
        if (userAnswers[i] == correctAnswer) {
          count++;
        }
      }
    }
    return count;
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
        leading: IconButton(
          icon: Icon(Icons.close, color: textColor),
          onPressed: () => Navigator.pop(context, null),
        ),
        title: Text(
          widget.stageTitle,
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: widget.themeColor))
          : questions.isEmpty
          ? Center(
        child: Text(
          'Không có câu hỏi nào cho màn chơi này.',
          style: TextStyle(color: subtitleColor, fontSize: 14),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: isFinished
            ? SingleChildScrollView(
          child: Column(
            children: [
              const Icon(Icons.emoji_events_rounded, size: 72, color: Colors.amber),
              const SizedBox(height: 12),
              Text(
                'Kết Quả Thi Đấu',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Đúng $correctCount/$totalQuestions câu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: correctCount == totalQuestions ? Colors.green : widget.themeColor,
                ),
              ),
              const SizedBox(height: 20),
              if (correctCount < totalQuestions) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Các câu hỏi cần xem lại:',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ),
                const SizedBox(height: 10),
                ...List.generate(totalQuestions, (index) {
                  final q = questions[index];
                  final int userAnswer = userAnswers[index];
                  final int correctAnswer = q['correctAnswerIndex'] ?? 0;
                  final List options = q['options'] ?? [];

                  if (userAnswer == correctAnswer) return const SizedBox.shrink();

                  final String userText = (userAnswer != -1 && userAnswer < options.length)
                      ? options[userAnswer].toString()
                      : 'Chưa chọn (Hết giờ)';
                  final String correctText = (correctAnswer < options.length)
                      ? options[correctAnswer].toString()
                      : '';

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Câu ${index + 1}: ${q['questionText'] ?? q['question'] ?? ''}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '❌ Bạn chọn: $userText',
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '✅ Đáp án đúng: $correctText',
                          style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }),
              ] else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Tuyệt vời! Bạn đã trả lời chính xác tất cả câu hỏi.',
                    style: TextStyle(color: subtitleColor),
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.themeColor,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context, widget.stageId),
                child: const Text(
                  'Nhận thưởng & Trở về',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Câu hỏi ${currentQuestionIndex + 1}/$totalQuestions',
                  style: TextStyle(fontWeight: FontWeight.bold, color: widget.themeColor),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _secondsRemaining <= 5
                        ? Colors.red.withValues(alpha: 0.1)
                        : widget.themeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: _secondsRemaining <= 5 ? Colors.red : widget.themeColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_secondsRemaining s',
                        style: TextStyle(
                          color: _secondsRemaining <= 5 ? Colors.red : widget.themeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: totalQuestions > 0 ? (currentQuestionIndex + 1) / totalQuestions : 0,
              color: widget.themeColor,
              backgroundColor: widget.themeColor.withValues(alpha: 0.1),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                questions[currentQuestionIndex]['questionText'] ?? questions[currentQuestionIndex]['question'] ?? '',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              ),
            ),
            const SizedBox(height: 20),
            ...List.generate(
              ((questions[currentQuestionIndex]['options'] ?? []) as List).length,
                  (index) {
                final optionText = questions[currentQuestionIndex]['options'][index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _answerQuestion(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: widget.themeColor.withValues(alpha: 0.1),
                            child: Text(
                              String.fromCharCode(65 + index),
                              style: TextStyle(
                                fontSize: 12,
                                color: widget.themeColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              optionText.toString(),
                              style: TextStyle(color: textColor, fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}