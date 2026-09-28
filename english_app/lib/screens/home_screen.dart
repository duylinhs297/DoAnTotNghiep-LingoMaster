import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'vocabulary/vocabulary_screen.dart';
import 'speaking/speaking_screen.dart';
import 'review/flashcard_screen.dart';
import 'quiz/quiz_topics_screen.dart';
import 'listening/listening_screen.dart';

class HomeScreen extends StatefulWidget {
  final int userId;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final String currentLevel;
  final ValueChanged<String> onLevelChanged;
  final bool isTrungCapUnlocked;
  final bool isCaoCapUnlocked;
  final ValueChanged<String> onUnlockLevel;
  final Map<String, dynamic>? currentUserData;
  const HomeScreen({
    super.key,
    this.userId = 1,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.currentLevel,
    required this.onLevelChanged,
    required this.isTrungCapUnlocked,
    required this.isCaoCapUnlocked,
    required this.onUnlockLevel,
    this.currentUserData,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int streakCount = 0;
  int watchedAdCount = 0;
  bool hasCheckedInToday = false;
  bool isLoadingAttendance = true;
  bool isLoadingLevels = true;

  List<dynamic> courseLevels = [];
  late String currentLevel;

  Map<String, List<bool>> vocabTopicStates = {};
  Map<String, List<bool>> speakingTopicStates = {};
  Map<String, List<bool>> reviewTopicStates = {};
  Map<String, List<bool>> quizTopicStates = {};
  Map<String, List<bool>> listeningFavoriteStates = {};
  Set<int> completedVocabCategoryIds = {};
  Set<int> completedCategoryIds = {};
  String _userSubscription = 'Tiêu chuẩn (Free)';
  Map<String, dynamic>? currentUserData;

  // Quản lý 5 học phần cho từng cấp độ: [Vocab, Speaking, Review, Quiz, Listening]
  final List<List<bool>> levelCompletedLessons = [
    [false, false, false, false, false], // Sơ cấp
    [false, false, false, false, false], // Trung cấp
    [false, false, false, false, false], // Cao cấp
  ];

  late List<Map<String, dynamic>> weekDays;

  @override
  void initState() {
    super.initState();
    currentLevel = widget.currentLevel;
    if (widget.currentUserData != null) {
      _updateUserSubscriptionFromData(widget.currentUserData!);
    }
    _initCurrentWeekDays();
    _loadAttendanceData();
    _fetchCourseLevels();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLevel != widget.currentLevel) {
      setState(() {
        currentLevel = widget.currentLevel;
      });
    }

    if (widget.currentUserData != oldWidget.currentUserData && widget.currentUserData != null) {
      setState(() {
        _updateUserSubscriptionFromData(widget.currentUserData!);
      });
    }
  }

  int get currentLevelIndex {
    if (currentLevel == 'Sơ cấp') return 0;
    if (currentLevel == 'Trung cấp') return 1;
    return 2;
  }

  List<bool> get completedLessons => levelCompletedLessons[currentLevelIndex];

  double get totalProgress {
    int completedCount = completedLessons.where((element) => element).length;
    return completedCount / completedLessons.length;
  }

  int get completedCount => completedLessons.where((element) => element).length;

  // Lấy đúng userId từ dữ liệu truyền vào thay vì dùng số 1 cố định
  int get currentUserId {
    return widget.currentUserData?['id'] ?? widget.currentUserData?['Id'] ?? widget.userId;
  }

  // Nếu là ID 1 hoặc PRO thì tự động mở khóa Trung cấp và Cao cấp để tránh lỗi khóa học
  bool get isTrungCapUnlockedFinal => currentUserId == 1 || widget.isTrungCapUnlocked;
  bool get isCaoCapUnlockedFinal => currentUserId == 1 || widget.isCaoCapUnlocked;

  // Kiểm tra hoàn thành 5/5 bài học của cấp độ hiện tại để thông báo mở khóa
  void _checkAndUnlockNextLevel() {
    if (completedLessons.every((isDone) => isDone)) {
      if (currentLevel == 'Sơ cấp' && !isTrungCapUnlockedFinal) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Chúc mừng bạn đã hoàn thành 5/5 bài học Sơ cấp! Hãy chọn xem 5 quảng cáo hoặc dùng PRO để mở khóa Trung cấp!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      } else if (currentLevel == 'Trung cấp' && !isCaoCapUnlockedFinal) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Chúc mừng bạn đã hoàn thành 5/5 bài học Trung cấp! Hãy chọn xem 5 quảng cáo hoặc dùng PRO để mở khóa Cao cấp!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _updateUserSubscriptionFromData(Map<String, dynamic> data) {
    currentUserData = data;
    streakCount = data['streakCount'] ?? 0;
    hasCheckedInToday = data['hasCheckedInToday'] ?? false;

    // Nếu ID là 1 hoặc isPro = true -> Mặc định gán là PRO Trọn Đời[cite: 16]
    if (currentUserId == 1 || data['isPro'] == true) {
      _userSubscription = 'PRO Trọn Đời';
    } else {
      _userSubscription = data['accountType'] ??
          data['AccountType'] ??
          data['account_type'] ??
          'Tiêu chuẩn (Free)';
    }
  }

  void _showRewardAdDialog(String levelName, Color levelColor) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.play_circle_fill, color: Colors.red, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Xem quảng cáo mở khóa $levelName',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tiến độ mở khóa: ${watchedAdCount + 1}/5 lần',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12)),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.video_collection, color: Colors.white54, size: 48),
                          SizedBox(height: 8),
                          Text('Đang phát quảng cáo demo...', style: TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bạn đã hủy xem quảng cáo!')),
                    );
                  },
                  child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: levelColor),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    setState(() {
                      watchedAdCount++;
                      if (watchedAdCount >= 5) {
                        widget.onUnlockLevel(levelName);
                        watchedAdCount = 0;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('🎉 Chúc mừng! Mở khóa thành công cấp độ $levelName!'), backgroundColor: Colors.green),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('👍 Đã ghi nhận! Cần xem thêm ${5 - watchedAdCount} lần nữa.'), backgroundColor: Colors.orange),
                        );
                      }
                    });
                  },
                  child: const Text('Nhận thưởng (+1 lần)', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _fetchCourseLevels() async {
    final levels = await UserApiService.getCourseLevels();
    if (mounted) {
      setState(() {
        courseLevels = levels;
        isLoadingLevels = false;
      });
    }
  }

  void _initCurrentWeekDays() {
    DateTime now = DateTime.now();
    int currentWeekday = now.weekday;
    DateTime monday = now.subtract(Duration(days: currentWeekday - 1));
    List<String> dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    weekDays = [];

    for (int i = 0; i < 7; i++) {
      DateTime day = monday.add(Duration(days: i));
      bool isToday = day.year == now.year && day.month == now.month && day.day == now.day;
      weekDays.add({
        'day': dayLabels[i],
        'date': day.day.toString().padLeft(2, '0'),
        'fullDate': "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}",
        'isChecked': false,
        'isToday': isToday,
      });
    }
  }

  Future<void> _loadAttendanceData() async {
    final data = await UserApiService.getUserProfile(currentUserId);
    if (data != null && mounted) {
      setState(() {
        _updateUserSubscriptionFromData(data);
        List<dynamic> weeklyAttendances = data['weeklyAttendances'] ?? [];
        for (var dayMap in weekDays) {
          if (weeklyAttendances.contains(dayMap['fullDate'])) {
            dayMap['isChecked'] = true;
          }
        }
        isLoadingAttendance = false;
      });
    } else {
      if (mounted) setState(() => isLoadingAttendance = false);
    }
  }

  Future<void> _handleCheckIn(StateSetter setDialogState) async {
    final result = await UserApiService.checkIn(currentUserId);
    if (result != null && mounted) {
      setState(() {
        streakCount = result['streakCount'] ?? (streakCount + 1);
        hasCheckedInToday = true;
        for (var element in weekDays) {
          if (element['isToday'] == true) element['isChecked'] = true;
        }
      });
      setDialogState(() {});
    }
  }

  void _showLevelSelectionDialog() {
    final cardBgColor = widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = widget.isDarkMode ? Colors.grey.shade400 : const Color(0xFF64748B);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: cardBgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Chọn cấp độ học tập', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Chọn cấp độ từ danh sách khóa học hệ thống:', style: TextStyle(color: subtitleColor, fontSize: 13)),
              const SizedBox(height: 16),
              if (isLoadingLevels)
                const CircularProgressIndicator()
              else
                ...courseLevels.map((lvl) {
                  String name = lvl['name'] ?? '';
                  bool isUnlocked = name == 'Sơ cấp' ||
                      (name == 'Trung cấp' && isTrungCapUnlockedFinal) ||
                      (name == 'Cao cấp' && isCaoCapUnlockedFinal);
                  Color lvlColor = name == 'Trung cấp' ? Colors.teal : (name == 'Cao cấp' ? Colors.amber.shade800 : Colors.indigo);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _buildLevelOptionItem(name, lvlColor, currentLevel == name, isUnlocked),
                  );
                }),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
          ],
        );
      },
    );
  }

  Widget _buildLevelOptionItem(String levelName, Color color, bool isSelected, bool isUnlocked) {
    bool prerequisiteMet = true;
    if (levelName == 'Trung cấp') {
      prerequisiteMet = levelCompletedLessons[0].every((isDone) => isDone);
    } else if (levelName == 'Cao cấp') {
      prerequisiteMet = levelCompletedLessons[1].every((isDone) => isDone);
    }

    return InkWell(
      onTap: () {
        if (!prerequisiteMet) {
          Navigator.pop(context);
          String requiredLevel = levelName == 'Trung cấp' ? 'Sơ cấp' : 'Trung cấp';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🔒 Bạn cần hoàn thành 5/5 bài học $requiredLevel trước khi mở khóa $levelName!'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }

        if (!isUnlocked) {
          Navigator.pop(context);
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (context) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Mở khóa cấp độ $levelName 🔓', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Đã hoàn thành điều kiện bài học! Chọn hình thức để mở khóa chính thức:', style: TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 48)),
                      icon: const Icon(Icons.slow_motion_video, color: Colors.white),
                      label: Text('Xem quảng cáo tích lũy ($watchedAdCount/5 lần)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(context);
                        _showRewardAdDialog(levelName, color);
                      },
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48), side: const BorderSide(color: Colors.indigo)),
                      icon: const Icon(Icons.workspace_premium, color: Colors.indigo),
                      label: const Text('Nâng cấp tài khoản PRO (Mở khóa ngay)', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onUnlockLevel(levelName);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('✨ Đã mở khóa $levelName với tài khoản PRO!'), backgroundColor: Colors.indigo),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
          return;
        }

        setState(() => currentLevel = levelName);
        widget.onLevelChanged(levelName);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: (prerequisiteMet && isUnlocked) ? color : Colors.grey, shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Text(levelName, style: TextStyle(fontSize: 15, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? color : Colors.grey)),
              ],
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 20)
            else if (!prerequisiteMet || !isUnlocked)
              const Icon(Icons.lock, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = widget.isDarkMode ? Colors.grey.shade400 : const Color(0xFF64748B);
    final cardBgColor = widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    int percentInt = (totalProgress * 100).toInt();

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Xin chào, Học viên! 👋', style: TextStyle(fontSize: 14, color: subtitleColor)),
                      const SizedBox(height: 4),
                      Text('LingoMaster', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                    ],
                  ),
                  InkWell(
                    onTap: _showAttendanceDialog,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Text('🔥 ', style: TextStyle(fontSize: 16)),
                          Text(isLoadingAttendance ? '...' : '$streakCount Ngày', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // THANH TIẾN ĐỘ TỔNG
              InkWell(
                onTap: _showLevelSelectionDialog,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text('TIẾN ĐỘ ${currentLevel.toUpperCase()} TỔNG', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                              const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                            child: Text('$percentInt% Hoàn thành', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('Chương trình tiếng Anh $currentLevel', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: totalProgress,
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$completedCount/5 Học phần đã hoàn thành', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          const Text('Nhấn để đổi cấp 👆', style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              Text('Bài học $currentLevel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 12),

              // 1. KHO TỪ VỰNG (Index 0)
              _buildQuickLessonCard(
                icon: Icons.book_rounded,
                iconColor: Colors.blue,
                bgColor: Colors.blue.shade50,
                title: 'Kho từ vựng ($currentLevel)',
                subtitle: completedLessons[0] ? 'Đã hoàn thành kho từ vựng ✅' : 'Danh mục chủ đề từ vựng',
                tag: 'VOCAB',
                cardBgColor: cardBgColor,
                borderColor: completedLessons[0] ? Colors.green.withValues(alpha: 0.5) : borderColor,
                textColor: textColor,
                subtitleColor: subtitleColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VocabularyScreen(
                        isDarkMode: widget.isDarkMode,
                        initialLevel: currentLevel,
                        isTrungCapUnlocked: isTrungCapUnlockedFinal,
                        isCaoCapUnlocked: isCaoCapUnlockedFinal,
                        initialTopicStates: vocabTopicStates[currentLevel] ?? [],
                        completedCategoryIds: completedVocabCategoryIds,
                        userSubscription: _userSubscription,
                        onTopicCompleted: (categoryId) {
                          setState(() {
                            completedVocabCategoryIds.add(categoryId);
                          });
                        },
                        onAllVocabularyCompleted: () {
                          setState(() {
                            levelCompletedLessons[currentLevelIndex][0] = true;
                          });
                          _checkAndUnlockNextLevel();
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // 2. LUYỆN PHÁT ÂM AI (Index 1)
              _buildQuickLessonCard(
                icon: Icons.mic_rounded,
                iconColor: Colors.purple,
                bgColor: Colors.purple.shade50,
                title: 'Luyện phát âm AI ($currentLevel)',
                subtitle: completedLessons[1] ? 'Đã hoàn thành phát âm ✅' : 'Phát âm và chấm điểm hội thoại',
                tag: 'SPEAKING',
                cardBgColor: cardBgColor,
                borderColor: completedLessons[1] ? Colors.green.withValues(alpha: 0.5) : borderColor,
                textColor: textColor,
                subtitleColor: subtitleColor,
                onTap: () async {
                  final updatedMap = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SpeakingScreen(
                        isDarkMode: widget.isDarkMode,
                        initialLevel: currentLevel,
                        initialTopicStatesMap: speakingTopicStates,
                        userSubscription: _userSubscription,
                      ),
                    ),
                  );

                  if (updatedMap != null && mounted) {
                    setState(() {
                      speakingTopicStates = updatedMap;
                      List<bool> states = speakingTopicStates[currentLevel] ?? [];
                      if (states.isNotEmpty && states.every((isDone) => isDone)) {
                        levelCompletedLessons[currentLevelIndex][1] = true;
                      }
                    });
                    _checkAndUnlockNextLevel();
                  }
                },
              ),
              const SizedBox(height: 12),

              // 3. ÔN TẬP THÔNG MINH (Index 2)
              _buildQuickLessonCard(
                icon: Icons.psychology_rounded,
                iconColor: Colors.green,
                bgColor: Colors.green.shade50,
                title: 'Ôn tập thông minh ($currentLevel)',
                subtitle: completedLessons[2] ? 'Đã hoàn thành ôn tập ✅' : 'Củng cố từ vựng & cấu trúc',
                tag: 'REVIEW',
                cardBgColor: cardBgColor,
                borderColor: completedLessons[2] ? Colors.green.withValues(alpha: 0.5) : borderColor,
                textColor: textColor,
                subtitleColor: subtitleColor,
                onTap: () async {
                  final updatedMap = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReviewScreen(
                        isDarkMode: widget.isDarkMode,
                        initialLevel: currentLevel,
                        initialTopicStatesMap: reviewTopicStates,
                        userSubscription: _userSubscription,
                      ),
                    ),
                  );

                  if (updatedMap != null && mounted) {
                    setState(() {
                      reviewTopicStates = updatedMap;
                      List<bool> states = reviewTopicStates[currentLevel] ?? [];
                      if (states.isNotEmpty && states.every((isDone) => isDone)) {
                        levelCompletedLessons[currentLevelIndex][2] = true;
                      }
                    });
                    _checkAndUnlockNextLevel();
                  }
                },
              ),
              const SizedBox(height: 12),

              // 4. TRẮC NGHIỆM TỪ VỰNG (Index 3)
              _buildQuickLessonCard(
                icon: Icons.quiz_rounded,
                iconColor: Colors.orange,
                bgColor: Colors.orange.shade50,
                title: 'Trắc nghiệm từ vựng ($currentLevel)',
                subtitle: completedLessons[3] ? 'Đã hoàn thành trắc nghiệm ✅' : 'Kiểm tra mức độ ghi nhớ',
                tag: 'QUIZ',
                cardBgColor: cardBgColor,
                borderColor: completedLessons[3] ? Colors.green.withValues(alpha: 0.5) : borderColor,
                textColor: textColor,
                subtitleColor: subtitleColor,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizTopicsScreen(
                        isDarkMode: widget.isDarkMode,
                        initialLevel: currentLevel,
                        initialTopicStatesMap: quizTopicStates,
                        completedCategoryIds: completedCategoryIds,
                        userSubscription: _userSubscription,
                        onTopicCompleted: (categoryId) {
                          setState(() {
                            completedCategoryIds.add(categoryId);
                          });
                        },
                      ),
                    ),
                  );
                  if (result == true && mounted) {
                    setState(() {
                      levelCompletedLessons[currentLevelIndex][3] = true;
                    });
                    _checkAndUnlockNextLevel();
                  }
                },
              ),
              const SizedBox(height: 12),

              // 5. LUYỆN NGHE HIỂU (Index 4)
              _buildQuickLessonCard(
                icon: Icons.headphones_rounded,
                iconColor: Colors.teal,
                bgColor: Colors.teal.shade50,
                title: 'Luyện nghe hiểu ($currentLevel)',
                subtitle: completedLessons[4] ? 'Đã hoàn thành luyện nghe ✅' : 'Luyện bài nghe theo cấp độ',
                tag: 'LISTENING',
                cardBgColor: cardBgColor,
                borderColor: completedLessons[4] ? Colors.green.withValues(alpha: 0.5) : borderColor,
                textColor: textColor,
                subtitleColor: subtitleColor,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ListeningScreen(
                        isDarkMode: widget.isDarkMode,
                        initialLevel: currentLevel,
                        completedCategoryIds: completedCategoryIds,
                        userSubscription: _userSubscription,
                        onTopicCompleted: (categoryId) {
                          setState(() {
                            completedCategoryIds.add(categoryId);
                          });
                        },
                      ),
                    ),
                  );
                  if (result == true && mounted) {
                    setState(() {
                      levelCompletedLessons[currentLevelIndex][4] = true;
                    });
                    _checkAndUnlockNextLevel();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickLessonCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required String tag,
    required Color cardBgColor,
    required Color borderColor,
    required Color textColor,
    required Color subtitleColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                        child: Text(tag, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigo)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: subtitleColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttendanceDialog() {
    final cardBgColor = widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = widget.isDarkMode ? Colors.grey.shade400 : const Color(0xFF64748B);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: cardBgColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              contentPadding: const EdgeInsets.all(24),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle), child: const Text('🔥', style: TextStyle(fontSize: 36))),
                    const SizedBox(height: 16),
                    Text('Điểm Danh Hàng Ngày', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 6),
                    Text('Duy trì chuỗi học tập $streakCount ngày liên tiếp!', style: TextStyle(fontSize: 13, color: subtitleColor)),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: weekDays.map((item) {
                        bool isChecked = item['isChecked'];
                        bool isToday = item['isToday'];
                        return Column(
                          children: [
                            Text(item['day'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isToday ? Colors.orange : subtitleColor)),
                            const SizedBox(height: 8),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isChecked ? Colors.orange : (isToday ? Colors.orange.shade100 : Colors.grey.shade200),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: isChecked
                                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                                    : Text(item['date'], style: TextStyle(fontSize: 12, color: isToday ? Colors.orange.shade800 : Colors.grey.shade600)),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: hasCheckedInToday ? null : () => _handleCheckIn(setDialogState),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasCheckedInToday ? Colors.grey.shade400 : Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(hasCheckedInToday ? 'Đã Điểm Danh Hôm Nay ✅' : 'Điểm Danh Ngay (+1 🔥)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}