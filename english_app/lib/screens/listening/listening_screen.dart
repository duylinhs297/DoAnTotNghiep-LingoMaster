import 'package:flutter/material.dart';
import 'package:english_app/services/api_service.dart';
import 'listening_player_screen.dart';

class ListeningScreen extends StatefulWidget {
  final bool isDarkMode;
  final String initialLevel;
  final Set<int> completedCategoryIds;
  final Function(int categoryId) onTopicCompleted;
  final String userSubscription;

  const ListeningScreen({
    super.key,
    required this.isDarkMode,
    this.initialLevel = 'Sơ cấp',
    required this.completedCategoryIds,
    required this.onTopicCompleted,
    this.userSubscription = 'Free',
  });

  @override
  State<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen> {
  List<dynamic> categories = [];
  bool isLoading = true;
  bool hasDataChanged = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => isLoading = true);
    final data = await UserApiService.getCategoriesByLevelAndSkill(widget.initialLevel, 'LISTENING');
    if (mounted) {
      setState(() {
        categories = data;
        isLoading = false;
      });
    }
  }

  // Hàm kiểm tra tài khoản PRO thông minh
  bool _isUserPro() {
    final String subscription = (widget.userSubscription).toString().toLowerCase().trim();

    if (subscription.isEmpty || subscription.contains('tiêu chuẩn') || subscription.contains('free')) {
      return false;
    }

    return subscription.contains('pro') ||
        subscription.contains('trọn đời') ||
        subscription.contains('1 tháng');
  }

  Future<void> _handleTopicTap(dynamic item, int categoryId, int topicId, int itemIndex, String title, bool isCompleted) async {
    bool isPro = _isUserPro();

    if (itemIndex == 0 || isPro) {
      _openListeningPlayer(item, categoryId, topicId, isCompleted);
      return;
    }

    bool? watchedAd = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AdWatchDialog(isDarkMode: widget.isDarkMode, title: title),
    );

    if (watchedAd == true && mounted) {
      _openListeningPlayer(item, categoryId, topicId, isCompleted);
    }
  }

  Future<void> _openListeningPlayer(dynamic item, int categoryId, int topicId, bool isCompleted) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListeningPlayerScreen(
          isDarkMode: widget.isDarkMode,
          topicTitle: item['name'] ?? 'Luyện nghe',
          topicId: topicId,
          initialCompleted: isCompleted,
        ),
      ),
    );

    if (result == true && mounted) {
      widget.onTopicCompleted(categoryId);
      hasDataChanged = true;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = widget.isDarkMode ? Colors.grey.shade400 : const Color(0xFF64748B);
    final cardBgColor = widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final int totalCategories = categories.length;
    final int completedCount = categories.where((item) {
      final categoryId = item['id'] as int? ?? 0;
      return widget.completedCategoryIds.contains(categoryId);
    }).length;

    final double progressPercent = totalCategories > 0 ? completedCount / totalCategories : 0.0;
    bool isProUser = _isUserPro();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        Navigator.pop(context, hasDataChanged);
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text(
            'Luyện Nghe (${widget.initialLevel})',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: textColor),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pop(context, hasDataChanged),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : categories.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.headphones_rounded, size: 64, color: subtitleColor.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text('Không có chủ đề nghe nào ở cấp độ này!', style: TextStyle(color: subtitleColor, fontSize: 15)),
            ],
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          itemCount: categories.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tiến độ luyện nghe',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '$completedCount/$totalCategories chủ đề',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progressPercent,
                        minHeight: 8,
                        backgroundColor: widget.isDarkMode ? const Color(0xFF334155) : Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      progressPercent == 1.0
                          ? '🎉 Chúc mừng bạn đã hoàn thành tất cả bài luyện nghe!'
                          : 'Cố gắng hoàn thành các bài nghe còn lại nhé!',
                      style: TextStyle(color: subtitleColor, fontSize: 12),
                    ),
                  ],
                ),
              );
            }

            final itemIndex = index - 1;
            final item = categories[itemIndex];
            final categoryId = item['id'] as int? ?? itemIndex;
            final topics = item['topics'] as List<dynamic>? ?? [];
            final topicId = topics.isNotEmpty ? topics[0]['id'] : categoryId;
            final isCompleted = widget.completedCategoryIds.contains(categoryId);

            final bool isLockedForFree = itemIndex > 0 && !isProUser;
            final String title = item['name'] ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isCompleted ? Colors.green.withValues(alpha: 0.5) : borderColor,
                  width: isCompleted ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _handleTopicTap(item, categoryId, topicId, itemIndex, title, isCompleted),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.green.withValues(alpha: 0.12)
                                : isLockedForFree
                                ? Colors.amber.withValues(alpha: 0.1)
                                : Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            isCompleted
                                ? Icons.check_circle_rounded
                                : isLockedForFree
                                ? Icons.lock_rounded
                                : Icons.headphones_rounded,
                            color: isCompleted
                                ? Colors.green
                                : isLockedForFree
                                ? Colors.amber.shade700
                                : Colors.blue,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isCompleted)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.check, size: 12, color: Colors.green),
                                          SizedBox(width: 2),
                                          Text(
                                            'Đã xong',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else if (isLockedForFree)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.play_circle_fill, size: 12, color: Colors.amber.shade700),
                                          const SizedBox(width: 3),
                                          Text(
                                            'Xem QC 30s',
                                            style: TextStyle(
                                              color: Colors.amber.shade800,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isLockedForFree
                                    ? 'Xem quảng cáo để mở khóa chủ đề này'
                                    : (item['description'] ?? 'Luyện nghe audio và đọc transcript'),
                                style: TextStyle(
                                  color: isLockedForFree ? Colors.amber.shade700 : subtitleColor,
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: subtitleColor.withValues(alpha: 0.6),
                          size: 24,
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

class _AdWatchDialog extends StatefulWidget {
  final bool isDarkMode;
  final String title;

  const _AdWatchDialog({required this.isDarkMode, required this.title});

  @override
  State<_AdWatchDialog> createState() => _AdWatchDialogState();
}

class _AdWatchDialogState extends State<_AdWatchDialog> with SingleTickerProviderStateMixin {
  int _secondsRemaining = 30;
  bool _canClose = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..forward();

    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 1) {
          _secondsRemaining--;
          _startTimer();
        } else {
          _secondsRemaining = 0;
          _canClose = true;
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);

    return AlertDialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          const Icon(Icons.slow_motion_video_rounded, size: 48, color: Colors.amber),
          const SizedBox(height: 8),
          Text(
            'Mở Khóa Bài Luyện Nghe',
            style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Xem quảng cáo 30 giây để học bài:\n"${widget.title}"',
            style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: 1.0 - _controller.value,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                  strokeWidth: 6,
                ),
              ),
              Text(
                '$_secondsRemaining',
                style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _canClose ? 'Quảng cáo đã kết thúc!' : 'Đang phát quảng cáo...',
            style: TextStyle(
              color: _canClose ? Colors.green : Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _canClose ? Colors.blue : Colors.grey,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _canClose ? () => Navigator.pop(context, true) : null,
            child: Text(
              _canClose ? 'Tiếp tục học 🚀' : 'Vui lòng đợi ($_secondsRemaining s)',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}