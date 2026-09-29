import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import '../../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class UpgradeProScreen extends StatefulWidget {
  final bool isDarkMode;
  final int userId;

  const UpgradeProScreen({super.key, required this.isDarkMode, required this.userId});

  @override
  State<UpgradeProScreen> createState() => _UpgradeProScreenState();
}

class _UpgradeProScreenState extends State<UpgradeProScreen> {
  int selectedPlanIndex = 1;
  bool isLoading = false;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  final List<Map<String, dynamic>> plans = [
    {
      'title': 'Gói 1 Tháng',
      'price': '10.000 đ',
      'subtitle': 'Thanh toán hàng tháng, hủy bất cứ lúc nào.',
      'badge': 'Tiêu chuẩn',
    },
    {
      'title': 'Gói Trọn Đời (PRO)',
      'price': '11.000 đ',
      'subtitle': 'Thanh toán một lần, sử dụng vĩnh viễn không giới hạn.',
      'badge': 'Tiết kiệm 80%',
    },
  ];

  @override
  void initState() {
    super.initState();
    initDeepLinks(); // Lắng nghe sự kiện trả về app từ trình duyệt
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  // Khởi tạo lắng nghe Deep Link từ hệ thống
  void initDeepLinks() {
    _appLinks = AppLinks();

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) async {
      if (uri.toString().contains("payment-success")) {
        // Khi trình duyệt đẩy về app với scheme thanh toán thành công
        if (!mounted) return;
        await _processUpgradeSuccess(plans[selectedPlanIndex]['title']);
      }
    });
  }

  Future<void> _openPayOSPayment(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => isLoading = true);

    final plan = plans[selectedPlanIndex];
    final responseData = await UserApiService.createMomoPayment(widget.userId, plan['title']);

    setState(() => isLoading = false);

    if (responseData != null && responseData.containsKey('data')) {
      final checkoutData = responseData['data'];
      final String checkoutUrl = checkoutData['checkoutUrl'] ?? '';

      final Uri uri = Uri.parse(checkoutUrl);

      if (await canLaunchUrl(uri)) {
        // Mở trình duyệt bên ngoài (External Application)
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Không thể mở cổng thanh toán PayOS!')),
        );
      }
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Không thể tạo giao dịch PayOS từ server!')),
      );
    }
  }

  Future<void> _processUpgradeSuccess(String planTitle) async {
    setState(() => isLoading = true);

    bool success = await UserApiService.upgradePro(widget.userId, planTitle);

    setState(() => isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Chúc mừng! Tài khoản của bạn đã được nâng cấp lên PRO thành công!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true); // Trả về true để profile load lại dữ liệu mới
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi cập nhật trạng thái tài khoản, vui lòng thử lại!'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
          'Nâng cấp LingoMaster PRO',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Tiêu đề
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                children: [
                  Icon(Icons.workspace_premium_rounded, size: 56, color: Colors.amberAccent),
                  SizedBox(height: 12),
                  Text(
                    'Mở khóa toàn bộ sức mạnh AI',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Danh sách các quyền lợi PRO (Đã bổ sung vào đây)
            Text(
              'Đặc quyền khi lên PRO',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  _buildBenefitRow(Icons.mic_rounded, 'Chấm điểm phát âm AI không giới hạn số lần', textColor),
                  const Divider(height: 24),
                  _buildBenefitRow(Icons.all_inclusive_rounded, 'Truy cập toàn bộ kho bài nghe & từ vựng cao cấp', textColor),
                  const Divider(height: 24),
                  _buildBenefitRow(Icons.psychology_rounded, 'Ôn tập thông minh tối ưu hóa theo thuật toán trí nhớ', textColor),
                  const Divider(height: 24),
                  _buildBenefitRow(Icons.block_rounded, 'Trải nghiệm học tập hoàn toàn không có quảng cáo', textColor),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Chọn gói cước
            Text(
              'Chọn gói cước phù hợp',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 12),
            Column(
              children: List.generate(plans.length, (index) {
                final plan = plans[index];
                final isSelected = selectedPlanIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedPlanIndex = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.indigo.withValues(alpha: 0.05) : cardBgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.indigo : borderColor,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    plan['title'],
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      plan['badge'],
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                plan['subtitle'],
                                style: TextStyle(fontSize: 12, color: subtitleColor),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                plan['price'],
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : () => _openPayOSPayment(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.payment_rounded, size: 22),
                label: Text(
                  isLoading ? 'Đang tạo giao dịch...' : 'Thanh toán ${plans[selectedPlanIndex]['price']} qua PayOS',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hàm hỗ trợ tạo dòng quyền lợi
  Widget _buildBenefitRow(IconData icon, String text, Color textColor) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: Colors.indigo, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
          ),
        ),
      ],
    );
  }
}