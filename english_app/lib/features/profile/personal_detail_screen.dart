import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../auth/otp_dialog.dart';

class PersonalDetailScreen extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic>? currentUser;
  final Function(Map<String, dynamic> updatedUser)? onUserUpdated;

  const PersonalDetailScreen({
    super.key,
    required this.isDarkMode,
    this.currentUser,
    this.onUserUpdated,
  });

  @override
  State<PersonalDetailScreen> createState() => _PersonalDetailScreenState();
}

class _PersonalDetailScreenState extends State<PersonalDetailScreen> {
  late int userId;
  late String name;
  late String email;
  late String phone;
  late String level;
  late String accountType;
  String password = '••••••••••••';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initUserData();
  }

  void _initUserData() {
    userId = widget.currentUser?['id'] ?? widget.currentUser?['userId'] ?? widget.currentUser?['Id'] ?? 0;
    name = widget.currentUser?['name'] ?? widget.currentUser?['Name'] ?? 'Người dùng';
    email = widget.currentUser?['email'] ?? widget.currentUser?['Email'] ?? 'Chưa cập nhật email';
    phone = widget.currentUser?['phone'] ?? widget.currentUser?['Phone'] ?? '+84 987 654 321';
    level = widget.currentUser?['level'] ?? widget.currentUser?['currentLevel'] ?? widget.currentUser?['CurrentLevel'] ?? 'Sơ cấp';
    accountType = widget.currentUser?['accountType'] ?? ((widget.currentUser?['isPro'] == true || widget.currentUser?['IsPro'] == true) ? 'PRO (Premium)' : 'Tiêu chuẩn');
  }

  // Hàm xử lý xác thực 2FA an toàn trước async gap
  Future<void> _handleStartEdit(BuildContext context) async {
    final bool is2FA = widget.currentUser?['isTwoFactorEnabled'] ??
        widget.currentUser?['IsTwoFactorEnabled'] ??
        false;

    if (is2FA) {
      if (email.isEmpty || email == 'Chưa cập nhật email') {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tìm thấy Email hợp lệ để gửi mã OTP!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      final sent = await UserApiService.sendOtp(
        email: email,
        purpose: 'Xác thực chỉnh sửa thông tin',
      );

      if (!context.mounted) return;
      setState(() => _isLoading = false);

      if (!sent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể gửi mã OTP. Vui lòng kiểm tra lại kết nối!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final verified = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => OtpVerificationDialog(
          email: email,
          purpose: 'Xác thực chỉnh sửa thông tin',
          onVerify: (otp) async {
            return await UserApiService.verifyOtp(email: email, otpCode: otp);
          },
        ),
      );

      if (verified != true || !context.mounted) return;
    }

    if (!context.mounted) return;
    _showEditBottomSheet(context);
  }

  // Hàm xử lý lưu thay đổi dữ liệu
  Future<void> _handleSaveProfile({
    required BuildContext modalContext,
    required String newName,
    required String newEmail,
    required String newPhone,
    required String newPassword,
    required StateSetter setModalState,
  }) async {
    final rootMessenger = ScaffoldMessenger.of(context);
    final sheetNavigator = Navigator.of(modalContext);

    setModalState(() => _isLoading = true);

    final updatedData = Map<String, dynamic>.from(widget.currentUser ?? {});
    updatedData['id'] = userId;
    updatedData['Id'] = userId;
    updatedData['name'] = newName;
    updatedData['Name'] = newName;
    updatedData['email'] = newEmail;
    updatedData['Email'] = newEmail;
    updatedData['phone'] = newPhone;
    updatedData['Phone'] = newPhone;
    if (newPassword.isNotEmpty) {
      updatedData['password'] = newPassword;
      updatedData['Password'] = newPassword;
    }

    try {
      final result = await UserApiService.updateUserProfile(userId, updatedData);

      if (!context.mounted || !modalContext.mounted) return;

      if (result != null) {
        setState(() {
          name = newName;
          email = newEmail;
          phone = newPhone;
          if (newPassword.isNotEmpty) {
            password = '•' * newPassword.length;
          }
        });

        if (widget.onUserUpdated != null) {
          widget.onUserUpdated!(updatedData);
        }

        sheetNavigator.pop();
        rootMessenger.showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thông tin thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        rootMessenger.showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thất bại. Vui lòng kiểm tra lại thông tin!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      rootMessenger.showSnackBar(
        SnackBar(
          content: Text('Lỗi kết nối: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (modalContext.mounted) {
        setModalState(() => _isLoading = false);
      }
    }
  }

  void _showEditBottomSheet(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final sheetBgColor = widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white;

    final nameController = TextEditingController(text: name);
    final emailController = TextEditingController(text: email);
    final passwordController = TextEditingController();
    final phoneController = TextEditingController(text: phone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (builderContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(builderContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Chỉnh sửa thông tin',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: textColor),
                          onPressed: () => Navigator.pop(builderContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Họ và tên',
                        labelStyle: TextStyle(color: widget.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: Colors.indigo),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: widget.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.email_outlined, color: Colors.indigo),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu mới',
                        hintText: 'Nhập mật khẩu mới nếu muốn đổi',
                        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        labelStyle: TextStyle(color: widget.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.indigo),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Số điện thoại',
                        labelStyle: TextStyle(color: widget.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.phone_outlined, color: Colors.indigo),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () => _handleSaveProfile(
                          modalContext: builderContext,
                          newName: nameController.text.trim(),
                          newEmail: emailController.text.trim(),
                          newPhone: phoneController.text.trim(),
                          newPassword: passwordController.text.trim(),
                          setModalState: setModalState,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                            : const Text('Lưu thay đổi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
          'Thông tin cá nhân',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.indigo.shade100,
                    child: const CircleAvatar(
                      radius: 47,
                      backgroundColor: Colors.indigo,
                      child: Icon(Icons.person_rounded, size: 55, color: Colors.white),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.indigo,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  _buildInfoTile(
                    label: 'Họ và tên',
                    value: name,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                  ),
                  Divider(color: borderColor, height: 1),
                  _buildInfoTile(
                    label: 'Email',
                    value: email,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                  ),
                  Divider(color: borderColor, height: 1),
                  _buildInfoTile(
                    label: 'Mật khẩu',
                    value: password,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                  ),
                  Divider(color: borderColor, height: 1),
                  _buildInfoTile(
                    label: 'Số điện thoại',
                    value: phone,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                  ),
                  Divider(color: borderColor, height: 1),
                  _buildInfoTile(
                    label: 'Trình độ hiện tại',
                    value: level,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                  ),
                  Divider(color: borderColor, height: 1),
                  _buildInfoTile(
                    label: 'Loại tài khoản',
                    value: accountType,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    isHighlight: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _handleStartEdit(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
                    : const Text('Chỉnh sửa thông tin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required String label,
    required String value,
    required Color textColor,
    required Color subtitleColor,
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: subtitleColor)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,              fontWeight: FontWeight.bold,
              color: isHighlight ? Colors.indigo : textColor,
              letterSpacing: label == 'Mật khẩu' ? 2.0 : 0.0,
            ),
          ),
        ],
      ),
    );
  }
}