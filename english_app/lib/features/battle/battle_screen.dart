import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';
import 'battle_detail_screen.dart';

class BattleScreen extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, bool> battleModeStates;
  final ValueChanged<Map<String, bool>> onModeCompleted;

  const BattleScreen({
    super.key,
    required this.isDarkMode,
    required this.battleModeStates,
    required this.onModeCompleted,
  });

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  List<Map<String, dynamic>> battleModes = [];
  bool isLoadingStages = true;
  String? apiErrorMessage;

  late Map<String, bool> modeCompletedMap;

  // Trạng thái cho bảng xếp hạng động theo màn
  String? selectedLeaderboardStageId;
  List<dynamic> dynamicLeaderboardData = [];
  bool isLoadingLeaderboard = false;
  bool _hasFetchedInitial = false; // Biến kiểm soát việc làm mới dữ liệu khi mở dialog

  @override
  void initState() {
    super.initState();
    modeCompletedMap = {};
    _fetchBattleStages();
  }

  Future<void> _fetchBattleStages() async {
    setState(() {
      isLoadingStages = true;
      apiErrorMessage = null;
    });

    try {
      final response = await http.get(Uri.parse('${UserApiService.baseUrl}/battle/stages'));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List rawList = [];
        if (decoded is Map<String, dynamic> && decoded['data'] is List) {
          rawList = decoded['data'];
        } else if (decoded is List) {
          rawList = decoded;
        }

        final parsedList = rawList.map<Map<String, dynamic>>((item) {
          return {
            'id': item['id']?.toString() ?? '',
            'title': item['title']?.toString() ?? 'Màn thi đấu',
            'subtitle': item['subtitle']?.toString() ?? 'Thử thách trắc nghiệm',
            'questions': int.tryParse(item['questionsCount']?.toString() ?? '') ?? 40,
            'time': item['timeLimit']?.toString() ?? '15 giây',
            'icon': Icons.bolt_rounded,
            'color': _parseHexColor(item['colorHex']?.toString()),
          };
        }).toList();

        setState(() {
          battleModes = parsedList;
          isLoadingStages = false;
        });
        _initMap();
      } else {
        setState(() {
          isLoadingStages = false;
          apiErrorMessage = 'API chưa phản hồi (Mã lỗi: ${response.statusCode})';
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải màn chơi battle: $e');
      setState(() {
        isLoadingStages = false;
        apiErrorMessage = 'API chưa phản hồi hoặc không kết nối được server.';
      });
    }
  }

  Future<void> _fetchLeaderboard(String stageId, StateSetter setDialogState) async {
    setDialogState(() {
      isLoadingLeaderboard = true;
      selectedLeaderboardStageId = stageId;
    });

    try {
      final data = await UserApiService.getLeaderboard(stageId);
      setDialogState(() {
        dynamicLeaderboardData = data;
        isLoadingLeaderboard = false;
      });
    } catch (e) {
      debugPrint('Lỗi tải bảng xếp hạng stage $stageId: $e');
      setDialogState(() {
        dynamicLeaderboardData = [];
        isLoadingLeaderboard = false;
      });
    }
  }

  Color _parseHexColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return Colors.indigo;
    final buffer = StringBuffer();
    if (hexString.length == 7 || hexString.length == 9) buffer.write('FF');
    buffer.write(hexString.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.indigo;
    }
  }

  void _initMap() {
    modeCompletedMap = {};
    for (var mode in battleModes) {
      final id = mode['id'] as String;
      modeCompletedMap[id] = widget.battleModeStates[id] ?? false;
    }
  }

  @override
  void didUpdateWidget(covariant BattleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.battleModeStates != widget.battleModeStates) {
      _initMap();
    }
  }

  void _showLeaderboardDialog(BuildContext context, bool isDarkMode) {
    if (battleModes.isNotEmpty) {
      final bool exists = battleModes.any((m) => m['id'] == selectedLeaderboardStageId);
      if (!exists) {
        selectedLeaderboardStageId = battleModes[0]['id'];
      }
    }

    _hasFetchedInitial = false;

    final textColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final cardBgColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final dialogBg = isDarkMode ? const Color(0xFF0F172A) : Colors.white;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (selectedLeaderboardStageId != null && !_hasFetchedInitial && !isLoadingLeaderboard) {
            _hasFetchedInitial = true;
            Future.microtask(() => _fetchLeaderboard(selectedLeaderboardStageId!, setDialogState));
          }

          return Dialog(
            backgroundColor: dialogBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.leaderboard_rounded, color: Colors.amber, size: 28),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Bảng Xếp Hạng Màn Chơi',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: textColor),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: selectedLeaderboardStageId,
                    dropdownColor: dialogBg,
                    style: TextStyle(color: textColor, fontSize: 13),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: battleModes.map<DropdownMenuItem<String>>((mode) {
                      return DropdownMenuItem<String>(
                        value: mode['id'].toString(),
                        child: Text(mode['title'], style: TextStyle(color: textColor)),
                      );
                    }).toList(),
                    onChanged: (newStageId) {
                      if (newStageId != null && newStageId != selectedLeaderboardStageId) {
                        setState(() {
                          selectedLeaderboardStageId = newStageId;
                        });
                        _fetchLeaderboard(newStageId, setDialogState);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  isLoadingLeaderboard
                      ? const SizedBox(
                    height: 150,
                    child: Center(child: CircularProgressIndicator()),
                  )
                      : dynamicLeaderboardData.isEmpty
                      ? SizedBox(
                    height: 100,
                    child: Center(
                      child: Text(
                        'Chưa có dữ liệu xếp hạng màn này.',
                        style: TextStyle(color: subtitleColor(isDarkMode), fontSize: 13),
                      ),
                    ),
                  )
                      : ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: dynamicLeaderboardData.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final item = dynamicLeaderboardData[index];
                        final bool isMe = item['isMe'] == true;
                        final int rank = item['rank'] ?? (index + 1);

                        Color rankBadgeColor = Colors.grey.shade300;
                        if (rank == 1) rankBadgeColor = Colors.amber;
                        if (rank == 2) rankBadgeColor = Colors.blueGrey.shade200;
                        if (rank == 3) rankBadgeColor = Colors.brown.shade300;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.indigo.withValues(alpha: 0.12) : cardBgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isMe ? Colors.indigo : (isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: rankBadgeColor.withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$rank',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: rank <= 3 ? (isDarkMode ? Colors.white : Colors.black87) : textColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name']?.toString() ?? 'Người chơi',
                                      style: TextStyle(
                                        fontWeight: isMe ? FontWeight.bold : FontWeight.w500,
                                        color: textColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Thời gian: ${item['formattedTime'] ?? '${item['timeSpentSeconds']}s'}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${item['score']} điểm',
                                style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Đóng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color subtitleColor(bool isDarkMode) => isDarkMode ? Colors.grey.shade400 : const Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subColor = subtitleColor(widget.isDarkMode);
    final cardBgColor = widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    int completedCount = modeCompletedMap.values.where((e) => e).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.sports_esports_rounded, size: 28, color: Colors.indigo),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phòng Thi Đấu',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hoàn thành $completedCount/${battleModes.length} màn chơi',
                        style: TextStyle(fontSize: 13, color: subColor),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showLeaderboardDialog(context, widget.isDarkMode),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.amber),
                    backgroundColor: Colors.amber.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  icon: const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 18),
                  label: const Text(
                    'Xếp hạng',
                    style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade600, Colors.indigo.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Hệ thống thi đấu tuần tự',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Hoàn thành màn trước để mở khóa màn tiếp theo.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoadingStages
                ? const Center(child: CircularProgressIndicator())
                : apiErrorMessage != null
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.orangeAccent),
                    const SizedBox(height: 12),
                    Text(
                      apiErrorMessage!,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _fetchBattleStages,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Thử lại kết nối API'),
                    ),
                  ],
                ),
              ),
            )
                : battleModes.isEmpty
                ? Center(
              child: Text(
                'Không có màn chơi nào từ server.',
                style: TextStyle(color: subColor, fontSize: 14),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              itemCount: battleModes.length,
              itemBuilder: (context, index) {
                final mode = battleModes[index];
                final String modeId = mode['id'];
                final Color themeColor = mode['color'];
                final bool isDone = modeCompletedMap[modeId] ?? false;

                // LOGIC KHÓA/MỞ MÀN CHƠI:
                // - Màn đầu tiên (index == 0) luôn mở khóa.
                // - Các màn sau (index > 0) chỉ mở khóa khi màn đứng ngay trước đó (index - 1) đã hoàn thành.
                bool isUnlocked = true;
                if (index > 0) {
                  final prevModeId = battleModes[index - 1]['id'];
                  isUnlocked = modeCompletedMap[prevModeId] == true;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: InkWell(
                    onTap: !isUnlocked
                        ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bạn cần hoàn thành màn chơi trước đó để mở khóa màn này!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                        : () async {
                      final dynamic result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BattleDetailScreen(
                            isDarkMode: widget.isDarkMode,
                            userId: 1,
                            stageId: mode['id']?.toString() ?? modeId.toString(),
                            stageTitle: mode['title'],
                            questionsCount: mode['questions'],
                            timeLimit: mode['time'],
                            themeColor: themeColor,
                          ),
                        ),
                      );

                      if (result != null) {
                        setState(() {
                          modeCompletedMap[modeId] = true;
                          selectedLeaderboardStageId = modeId.toString();
                          dynamicLeaderboardData = [];
                        });
                        widget.onModeCompleted(Map<String, bool>.from(modeCompletedMap));
                      }
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Opacity(
                      opacity: isUnlocked ? 1.0 : 0.55, // Làm mờ các màn chưa mở khóa
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDone
                                ? Colors.green.withValues(alpha: 0.6)
                                : (!isUnlocked ? Colors.grey.withValues(alpha: 0.3) : borderColor),
                            width: isDone ? 1.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            containerIcon(mode, themeColor, isUnlocked),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          mode['title'],
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                      if (isDone)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'Hoàn thành',
                                            style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    mode['subtitle'],
                                    style: TextStyle(fontSize: 12.5, color: subColor),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(Icons.quiz_outlined, size: 14, color: themeColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${mode['questions']} câu',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: themeColor),
                                      ),
                                      const SizedBox(width: 14),
                                      Icon(Icons.timer_outlined, size: 14, color: subColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        mode['time'],
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: subColor),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isDone
                                  ? Icons.check_circle_rounded
                                  : (!isUnlocked
                                  ? Icons.lock_rounded
                                  : Icons.arrow_forward_ios_rounded),
                              size: isDone ? 22 : 18,
                              color: isDone
                                  ? Colors.green
                                  : (!isUnlocked ? Colors.grey : Colors.grey.shade400),
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
        ],
      ),
    );
  }

  Widget containerIcon(Map<String, dynamic> mode, Color themeColor, bool isUnlocked) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: isUnlocked ? themeColor.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        isUnlocked ? mode['icon'] : Icons.lock_outline_rounded,
        color: isUnlocked ? themeColor : Colors.grey,
        size: 26,
      ),
    );
  }
}