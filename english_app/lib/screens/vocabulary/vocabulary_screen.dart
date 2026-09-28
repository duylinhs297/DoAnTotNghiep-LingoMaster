import 'package:flutter/material.dart';
import 'package:english_app/services/api_service.dart';
import 'vocabulary_detail_screen.dart';

class VocabularyScreen extends StatefulWidget {
  final bool isDarkMode;
  final String initialLevel;
  final bool isTrungCapUnlocked;
  final bool isCaoCapUnlocked;
  final List<bool> initialTopicStates;
  final Set<int> completedCategoryIds;
  final Function(int categoryId) onTopicCompleted;
  final VoidCallback? onAllVocabularyCompleted; // Callback báo về Home khi hoàn thành toàn bộ kho từ vựng
  final String? userSubscription; // Nhận thông tin gói cước từ màn hình cha (Home)

  const VocabularyScreen({
    super.key,
    required this.isDarkMode,
    required this.initialLevel,
    required this.isTrungCapUnlocked,
    required this.isCaoCapUnlocked,
    required this.initialTopicStates,
    required this.completedCategoryIds,
    required this.onTopicCompleted,
    this.onAllVocabularyCompleted,
    this.userSubscription,
  });

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  List<dynamic> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => isLoading = true);
    final data = await UserApiService.getCategoriesByLevelAndSkill(widget.initialLevel, 'VOCAB');
    if (mounted) {
      setState(() {
        categories = data;
        isLoading = false;
      });
    }
  }

  void _checkCompletionStatus() {
    if (categories.isEmpty) return;
    int completedCount = categories.where((item) {
      final dynamic rawCatId = item['categoryId'] ?? item['CategoryId'] ?? item['id'] ?? item['Id'];
      final int categoryId = int.tryParse(rawCatId?.toString() ?? '0') ?? 0;
      return widget.completedCategoryIds.contains(categoryId);
    }).length;

    if (completedCount == categories.length) {
      widget.onAllVocabularyCompleted?.call();
    }
  }

  // Hàm kiểm tra tài khoản PRO dựa vào chuỗi subscription được truyền vào
  bool _isUserPro() {
    final String subscription = (widget.userSubscription ?? '').toString().toLowerCase().trim();

    // Nếu chuỗi rỗng hoặc chứa từ tiêu chuẩn/free thì chắc chắn là Free
    if (subscription.isEmpty || subscription.contains('tiêu chuẩn') || subscription.contains('free')) {
      return false;
    }

    // Ngược lại, nếu có chứa các gói nâng cấp thì là Pro
    return subscription.contains('pro') ||
        subscription.contains('trọn đời') ||
        subscription.contains('1 tháng');
  }

  // Xử lý logic bấm vào chủ đề (Miễn phí chủ đề 1, từ chủ đề 2 bắt xem quảng cáo hoặc check PRO)
  Future<void> _handleTopicTap({
    required int itemIndex,
    required Future<void> Function() onNavigateToDetail,
  }) async {
    // 1. Chủ đề đầu tiên (index == 0): Miễn phí hoàn toàn
    if (itemIndex == 0) {
      await onNavigateToDetail();
      return;
    }

    // 2. Nếu tài khoản là PRO: Cho phép vào luôn không cần xem quảng cáo
    if (_isUserPro()) {
      await onNavigateToDetail();
      return;
    }

    // 3. Nếu là tài khoản thường và từ chủ đề thứ 2 trở đi: Bắt xem quảng cáo demo 30 giây
    final bool? watchedAd = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _AdDemoDialog(isDarkMode: widget.isDarkMode);
      },
    );

    if (watchedAd == true) {
      if (mounted) {
        await onNavigateToDetail();
      }
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
      final dynamic rawCatId = item['categoryId'] ?? item['CategoryId'] ?? item['id'] ?? item['Id'];
      final int categoryId = int.tryParse(rawCatId?.toString() ?? '0') ?? 0;
      return widget.completedCategoryIds.contains(categoryId);
    }).length;

    final double progressPercent = totalCategories > 0 ? completedCount / totalCategories : 0.0;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Kho Từ Vựng (${widget.initialLevel})',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : categories.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_rounded, size: 64, color: subtitleColor.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('Chưa có chủ đề từ vựng nào!', style: TextStyle(color: subtitleColor, fontSize: 15)),
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
                        'Tiến độ học tập',
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        '$completedCount/$totalCategories chủ đề',
                        style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 14),
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
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.indigo),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    progressPercent == 1.0
                        ? '🎉 Chúc mừng bạn đã hoàn thành tất cả chủ đề!'
                        : 'Cố gắng hoàn thành các chủ đề còn lại nhé!',
                    style: TextStyle(color: subtitleColor, fontSize: 12),
                  ),
                ],
              ),
            );
          }

          final itemIndex = index - 1;
          final item = categories[itemIndex];
          final dynamic rawId = item['id'] ?? item['Id'];
          final int topicId = int.tryParse(rawId?.toString() ?? '1') ?? 1;
          final dynamic rawCatId = item['categoryId'] ?? item['CategoryId'] ?? rawId;
          final int categoryId = int.tryParse(rawCatId?.toString() ?? '1') ?? 1;
          final bool isDone = widget.completedCategoryIds.contains(categoryId);

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDone ? Colors.green.withValues(alpha: 0.5) : borderColor,
                width: isDone ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () async {
                  await _handleTopicTap(
                    itemIndex: itemIndex,
                    onNavigateToDetail: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VocabularyDetailScreen(
                            isDarkMode: widget.isDarkMode,
                            categoryTitle: item['name'] ?? 'Từ vựng',
                            topicId: topicId,
                          ),
                        ),
                      );

                      if (result == true && mounted) {
                        widget.onTopicCompleted(categoryId);
                        setState(() {});
                        _checkCompletionStatus();
                      }
                    },
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isDone ? Colors.green.withValues(alpha: 0.12) : Colors.indigo.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          isDone ? Icons.check_circle_rounded : Icons.auto_stories_rounded,
                          color: isDone ? Colors.green : Colors.indigo,
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
                                    item['name'] ?? '',
                                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isDone)
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
                                        Text('Đã xong', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  )
                                else if (itemIndex > 0 && !_isUserPro())
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.lock_clock, size: 12, color: Colors.orange),
                                        SizedBox(width: 2),
                                        Text('Xem QC', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item['description'] ?? 'Ôn tập và học từ vựng theo chủ đề này',
                              style: TextStyle(color: subtitleColor, fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right_rounded, color: subtitleColor.withValues(alpha: 0.6), size: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Widget Dialog hiển thị bộ đếm ngược quảng cáo 30 giây demo
class _AdDemoDialog extends StatefulWidget {
  final bool isDarkMode;
  const _AdDemoDialog({required this.isDarkMode});

  @override
  State<_AdDemoDialog> createState() => _AdDemoDialogState();
}

class _AdDemoDialogState extends State<_AdDemoDialog> {
  int _remainingSeconds = 30;
  bool _canClose = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 1) {
          _remainingSeconds--;
          _startCountdown();
        } else {
          _remainingSeconds = 0;
          _canClose = true;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);

    return AlertDialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Xem Quảng Cáo Mở Khóa',
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.slow_motion_video_rounded, size: 56, color: Colors.indigo),
          const SizedBox(height: 16),
          Text(
            _canClose
                ? '🎉 Bạn đã xem xong quảng cáo!'
                : 'Vui lòng xem hết quảng cáo để mở khóa chủ đề này\nCòn lại: $_remainingSeconds giây',
            style: TextStyle(color: textColor, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (!_canClose)
            const LinearProgressIndicator(color: Colors.indigo),
        ],
      ),
      actions: [
        Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _canClose ? Colors.indigo : Colors.grey.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: _canClose ? () => Navigator.pop(context, true) : null,
            child: Text(
              _canClose ? 'Đóng & Vào Học Ngay' : 'Đang xem quảng cáo...',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}