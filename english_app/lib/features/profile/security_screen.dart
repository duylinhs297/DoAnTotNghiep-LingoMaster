import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../auth/otp_dialog.dart';

class SecurityScreen extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic>? currentUser;
  final Function(Map<String, dynamic> updatedUser)? onUserUpdated;

  const SecurityScreen({
    super.key,
    required this.isDarkMode,
    this.currentUser,
    this.onUserUpdated,
  });

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  late bool isTwoFactorEnabled;
  late int userId;
  late String userEmail;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    final idRaw = widget.currentUser?['id'] ??
        widget.currentUser?['userId'] ??
        widget.currentUser?['Id'];

    if (idRaw != null) {
      userId = int.tryParse(idRaw.toString()) ?? 0;
    } else {
      userId = 0;
    }

    userEmail = widget.currentUser?['email'] ??
        widget.currentUser?['Email'] ??
        '';

    isTwoFactorEnabled = widget.currentUser?['isTwoFactorEnabled'] ??
        widget.currentUser?['IsTwoFactorEnabled'] ??
        false;
  }

  Future<void> _toggleTwoFactor(bool value) async {
    // 1. Kiểm tra thông tin tài khoản
    if (userId == 0 || userEmail.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể xác định thông tin tài khoản. Vui lòng đăng nhập lại!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. Nếu BẬT 2FA -> Gửi OTP & Hiện Dialog
    if (value) {
      setState(() => _isLoading = true);

      final sent = await UserApiService.sendOtp(
        email: userEmail,
        purpose: 'Bật bảo mật 2FA',
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (!sent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể gửi mã OTP. Vui lòng kiểm tra lại Email!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Mở Dialog nhập mã OTP
      final verified = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => OtpVerificationDialog(
          email: userEmail,
          purpose: 'Bật bảo mật 2FA',
          onVerify: (otp) async {
            return await UserApiService.verifyOtp(email: userEmail, otpCode: otp);
          },
        ),
      );

      // Nếu không nhập đúng OTP hoặc bấm Hủy thì dừng
      if (verified != true) return;
    }

    // 3. Cập nhật dữ liệu lên Server
    if (!mounted) return;
    setState(() => _isLoading = true);

    final updatedData = Map<String, dynamic>.from(widget.currentUser ?? {});
    updatedData['id'] = userId;
    updatedData['name'] = widget.currentUser?['name'] ?? widget.currentUser?['Name'] ?? 'User';
    updatedData['email'] = userEmail;
    updatedData['isTwoFactorEnabled'] = value;

    try {
      final result = await UserApiService.updateUserProfile(userId, updatedData);

      if (!mounted) return;

      if (result != null) {
        setState(() {
          isTwoFactorEnabled = value;
        });

        if (widget.onUserUpdated != null) {
          widget.onUserUpdated!(updatedData);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? 'Đã bật Bảo mật cấp 2 (2FA)' : 'Đã tắt Bảo mật cấp 2 (2FA)'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật trạng thái 2FA thất bại. Vui lòng thử lại!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
          'Bảo mật cấp 2',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security_rounded, color: Colors.indigo, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Bảo mật cấp 2 giúp bảo vệ tài khoản của bạn an toàn hơn bằng cách yêu cầu xác thực mã OTP gửi về Email khi đăng nhập.',
                      style: TextStyle(fontSize: 13, color: textColor, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: SwitchListTile(
                secondary: _isLoading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.indigo),
                )
                    : const Icon(Icons.lock_person_rounded, color: Colors.indigo),
                title: Text(
                  'Xác thực 2 bước (2FA)',
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 14),
                ),
                subtitle: Text(
                  'Nhận mã OTP qua email $userEmail',
                  style: TextStyle(color: subtitleColor, fontSize: 12),
                ),
                value: isTwoFactorEnabled,
                activeThumbColor: Colors.indigo,
                onChanged: _isLoading ? null : (value) => _toggleTwoFactor(value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}