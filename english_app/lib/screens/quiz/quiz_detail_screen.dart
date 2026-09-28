import 'dart:async';
import 'package:flutter/material.dart';

class QuizScreen extends StatefulWidget {
  final bool isDarkMode;
  final String topicTitle;
  final List<Map<String, dynamic>> quizList;
  final int timePerQuestion; // Nhận từ CourseTopic.TimeLimitSeconds

  const QuizScreen({
    super.key,
    required this.isDarkMode,
    required this.topicTitle,
    required this.quizList,
    this.timePerQuestion = 50, // Mặc định 20s nếu không truyền
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestionIndex = 0;
  int? selectedOptionIndex;
  bool isAnswerSubmitted = false;
  int score = 0;
  bool isCompletedSuccessfully = false;

  late int remainingSeconds;
  Timer? countdownTimer;

  @override
  void initState() {
    super.initState();
    remainingSeconds = widget.timePerQuestion;
    startTimer();
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  void startTimer() {
    countdownTimer?.cancel();
    setState(() {
      remainingSeconds = widget.timePerQuestion; // Reset theo cấu hình chủ đề
    });

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
        });
      } else {
        timer.cancel();
        handleTimeOut();
      }
    });
  }

  void handleTimeOut() {
    if (isAnswerSubmitted) return;
    setState(() {
      isAnswerSubmitted = true;
      selectedOptionIndex = null;
    });
  }

  void handleOptionSelected(int index) {
    if (isAnswerSubmitted) return;
    setState(() {
      selectedOptionIndex = index;
    });
  }

  void submitAnswer() {
    if (selectedOptionIndex == null && remainingSeconds > 0) return;

    countdownTimer?.cancel();

    setState(() {
      isAnswerSubmitted = true;
      if (selectedOptionIndex != null &&
          selectedOptionIndex == widget.quizList[currentQuestionIndex]['correctIndex']) {
        score += 1;
      }
    });
  }

  void nextQuestion() {
    setState(() {
      if (currentQuestionIndex < widget.quizList.length - 1) {
        currentQuestionIndex++;
        selectedOptionIndex = null;
        isAnswerSubmitted = false;
        startTimer();
      } else {
        countdownTimer?.cancel();
        isCompletedSuccessfully = true;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Hoàn thành bài tập! 🎉', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Text('Bạn đã đạt được $score/${widget.quizList.length} điểm trong chủ đề "${widget.topicTitle}".'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                child: const Text('Xong', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final cardBgColor = widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    if (widget.quizList.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.topicTitle)),
        body: const Center(child: Text('Không có câu hỏi nào trong chủ đề này.')),
      );
    }

    final currentQuestion = widget.quizList[currentQuestionIndex];
    final List<String> options = List<String>.from(currentQuestion['options'] ?? []);

    final isUrgent = remainingSeconds <= 5;
    final timerColor = isUrgent ? Colors.redAccent : Colors.indigo;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        Navigator.pop(context, isCompletedSuccessfully);
      },
      child: Scaffold(
        backgroundColor: widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pop(context, isCompletedSuccessfully),
          ),
          title: Text(
            '${widget.topicTitle} (${currentQuestionIndex + 1}/${widget.quizList.length})',
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 17),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: timerColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: timerColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined, size: 16, color: timerColor),
                      const SizedBox(width: 6),
                      Text(
                        '0:${remainingSeconds.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: timerColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (currentQuestionIndex + 1) / widget.quizList.length,
                  backgroundColor: borderColor,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.indigo),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  currentQuestion['question'] ?? '',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor, height: 1.4),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final isSelected = selectedOptionIndex == index;
                    final isCorrect = index == currentQuestion['correctIndex'];

                    Color optionBg = cardBgColor;
                    Color optionBorder = borderColor;
                    Color textOptColor = textColor;

                    if (isAnswerSubmitted) {
                      if (isCorrect) {
                        optionBg = Colors.green.shade50;
                        optionBorder = Colors.green;
                        textOptColor = Colors.green.shade900;
                      } else if (isSelected && !isCorrect) {
                        optionBg = Colors.red.shade50;
                        optionBorder = Colors.red;
                        textOptColor = Colors.red.shade900;
                      }
                    } else if (isSelected) {
                      optionBg = Colors.indigo.withValues(alpha: 0.1);
                      optionBorder = Colors.indigo;
                      textOptColor = Colors.indigo;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: isAnswerSubmitted ? null : () => handleOptionSelected(index),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: optionBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: optionBorder,
                              width: isSelected || (isAnswerSubmitted && isCorrect) ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: optionBorder.withValues(alpha: 0.2),
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(65 + index),
                                    style: TextStyle(fontWeight: FontWeight.bold, color: textOptColor),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  options[index],
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textOptColor),
                                ),
                              ),
                              if (isAnswerSubmitted && isCorrect)
                                const Icon(Icons.check_circle_rounded, color: Colors.green),
                              if (isAnswerSubmitted && isSelected && !isCorrect)
                                const Icon(Icons.cancel_rounded, color: Colors.red),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (isAnswerSubmitted) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: remainingSeconds == 0 ? Colors.orange.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: remainingSeconds == 0 ? Colors.orange.shade200 : Colors.blue.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        remainingSeconds == 0 ? Icons.timer_off_rounded : Icons.info_outline_rounded,
                        color: remainingSeconds == 0 ? Colors.orange : Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          remainingSeconds == 0
                              ? 'Hết giờ! ${currentQuestion['explanation'] ?? ''}'
                              : (currentQuestion['explanation'] ?? ''),
                          style: TextStyle(
                            fontSize: 13,
                            color: remainingSeconds == 0 ? Colors.orange.shade800 : Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (selectedOptionIndex == null && !isAnswerSubmitted)
                      ? null
                      : (isAnswerSubmitted ? nextQuestion : submitAnswer),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    disabledBackgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isAnswerSubmitted
                        ? (currentQuestionIndex == widget.quizList.length - 1 ? 'Hoàn thành' : 'Câu tiếp theo')
                        : 'Nộp đáp án',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}