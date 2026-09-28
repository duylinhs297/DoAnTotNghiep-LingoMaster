import 'package:flutter/material.dart';

class TermsAndPolicyScreen extends StatelessWidget {
  final bool isDarkMode;

  const TermsAndPolicyScreen({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDarkMode ? Colors.grey.shade400 : const Color(0xFF64748B);
    final cardBgColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          'Điều khoản và Chính sách',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1. Điều khoản sử dụng',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Khi sử dụng ứng dụng LingoMaster, bạn đồng ý tuân thủ các quy định và điều kiện dịch vụ của chúng tôi. Ứng dụng cung cấp các công cụ học ngoại ngữ và luyện nói thông qua trí tuệ nhân tạo (AI). Bạn không được phép sao chép, chỉnh sửa hoặc khai thác thương mại nội dung bài học mà không có sự đồng ý trước bằng văn bản.',
                    style: TextStyle(fontSize: 13, color: subtitleColor, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '2. Chính sách bảo mật thông tin',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chúng tôi cam kết bảo vệ tuyệt đối thông tin cá nhân của bạn (bao gồm họ tên, email, và dữ liệu giọng nói khi luyện tập). Dữ liệu này chỉ được sử dụng nhằm mục đích nâng cao chất lượng trải nghiệm học tập, cải thiện độ chính xác của hệ thống chấm điểm AI và sẽ không được chia sẻ cho bên thứ ba khi chưa có sự cho phép.',
                    style: TextStyle(fontSize: 13, color: subtitleColor, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '3. Quyền lợi và Tài khoản Pro',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Người dùng đăng ký gói nâng cấp tiêu chuẩn lên phiên bản PRO sẽ được mở khóa toàn bộ các bài học chuyên sâu, không giới hạn lượt chấm phát âm AI. Mọi giao dịch thanh toán đều được bảo mật qua các cổng thanh toán uy tín.',
                    style: TextStyle(fontSize: 13, color: subtitleColor, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '4. Thay đổi điều khoản',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'LingoMaster có quyền cập nhật, chỉnh sửa các điều khoản và chính sách này bất cứ lúc nào. Các thay đổi sẽ có hiệu lực ngay khi được đăng tải công khai trên ứng dụng.',
                    style: TextStyle(fontSize: 13, color: subtitleColor, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Cập nhật lần cuối: Tháng 9 năm 2026',
                style: TextStyle(fontSize: 12, color: subtitleColor, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}