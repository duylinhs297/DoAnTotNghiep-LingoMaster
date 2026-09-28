import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class UpgradeProScreen extends StatefulWidget {
  final bool isDarkMode;
  final int userId; // Nhận vào userId hiện tại của người dùng

  const UpgradeProScreen({super.key, required this.isDarkMode, required this.userId});

  @override
  State<UpgradeProScreen> createState() => _UpgradeProScreenState();
}

class _UpgradeProScreenState extends State<UpgradeProScreen> {
  int selectedPlanIndex = 1;
  bool isLoading = false;

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

  // Hàm mở thanh toán MoMo Sandbox thật qua URL API
  // Hàm mở trang thanh toán PayOS
  Future<void> _openPayOSPayment(BuildContext context) async {
    setState(() => isLoading = true);

    final plan = plans[selectedPlanIndex];
    // Vẫn gọi hàm createMomoPayment (hoặc bạn có thể đổi tên hàm trong api_service thành createPayOSPayment cho chuẩn)
    final responseData = await UserApiService.createMomoPayment(widget.userId, plan['title']);

    setState(() => isLoading = false);

    if (responseData != null && responseData.containsKey('data')) {
      // PayOS trả về đường dẫn thanh toán nằm trong data -> checkoutUrl
      final checkoutData = responseData['data'];
      final String checkoutUrl = checkoutData['checkoutUrl'] ?? '';

      final Uri uri = Uri.parse(checkoutUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        if (context.mounted) {
          _showWaitingForPaymentDialog(context);
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể mở cổng thanh toán PayOS!')),
          );
        }
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tạo giao dịch PayOS từ server!')),
        );
      }
    }
  }

  // Hộp thoại chờ xác nhận thanh toán sau khi bật trang MoMo Sandbox
  // Hộp thoại chờ xác nhận thanh toán sau khi bật trang PayOS
  void _showWaitingForPaymentDialog(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Đang chờ thanh toán'),
          content: const Text('Vui lòng hoàn tất giao dịch quét mã QR trên ứng dụng ngân hàng. Sau khi xong, hãy bấm nút bên dưới để hệ thống cập nhật tài khoản.'),
          actions: [
            TextButton(
              onPressed: () async {
                // 1. Đóng hộp thoại chờ an toàn
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }

                // 2. Kiểm tra xem màn hình chính còn tồn tại không trước khi kích hoạt nâng cấp
                if (!mounted) return;

                // 3. Tiến hành gọi API nâng cấp PRO ngay lập tức cho user
                await _processUpgradeSuccess(plans[selectedPlanIndex]['title']);
              },
              child: const Text('Tôi đã thanh toán xong', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // Gửi request lên C# Backend hoặc hiển thị thông báo thành công
  Future<void> _processUpgradeSuccess(String planTitle) async {
    setState(() => isLoading = true);

    bool success = await UserApiService.upgradePro(widget.userId, planTitle);

    setState(() => isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Chúc mừng! Tài khoản của bạn đã được nâng cấp lên PRO thành công!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true); // Trả về true để profile load lại dữ liệu mới
    } else if (mounted) {
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
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
                  SizedBox(height: 8),
                  Text(
                    'Nâng cấp ngay hôm nay để trải nghiệm học ngoại ngữ không giới hạn và bứt phá kỹ năng giao tiếp.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Danh sách các quyền lợi PRO
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
                  _buildBenefitRow(Icons.mic_rounded, 'Chấm điểm phát âm AI không giới hạn số lần'),
                  const Divider(height: 24),
                  _buildBenefitRow(Icons.all_inclusive_rounded, 'Truy cập toàn bộ kho bài nghe & từ vựng cao cấp'),
                  const Divider(height: 24),
                  _buildBenefitRow(Icons.psychology_rounded, 'Ôn tập thông minh tối ưu hóa theo thuật toán trí nhớ'),
                  const Divider(height: 24),
                  _buildBenefitRow(Icons.block_rounded, 'Trải nghiệm học tập hoàn toàn không có quảng cáo'),
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
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.indigo : Colors.grey,
                              width: isSelected ? 6 : 2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
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

            // Nút Thanh Toán MoMo Thật (Gọi API Sandbox)
            // Nút Thanh Toán PayOS
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : () => _openPayOSPayment(context), // Gọi hàm PayOS mới
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1), // Đổi màu sang tông màu phù hợp với PayOS (Indigo/Purple)
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
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

  Widget _buildBenefitRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.indigo, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}