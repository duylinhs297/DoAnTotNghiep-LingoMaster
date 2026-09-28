import 'package:flutter/material.dart';
import 'personal_detail_screen.dart';
import 'terms_and_policy_screen.dart';
import 'security_screen.dart';
import 'upgrade_pro_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final Map<String, dynamic>? currentUser;
  final VoidCallback? onLogout;
  final Function(Map<String, dynamic>)? onUserUpdated; // Thêm callback báo cho màn hình gốc

  const ProfileScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
    this.currentUser,
    this.onLogout,
    this.onUserUpdated,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Map<String, dynamic>? userLocal;

  @override
  void initState() {
    super.initState();
    userLocal = widget.currentUser;
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentUser != oldWidget.currentUser) {
      userLocal = widget.currentUser;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = widget.isDarkMode ? Colors.grey.shade400 : const Color(0xFF64748B);
    final cardBgColor = widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final String name = userLocal?['name'] ?? userLocal?['Name'] ?? 'Người dùng';
    final String email = userLocal?['email'] ?? userLocal?['Email'] ?? 'Chưa cập nhật email';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            CircleAvatar(
              radius: 42,
              backgroundColor: Colors.indigo.shade100,
              child: const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.indigo,
                child: Icon(Icons.person_rounded, size: 45, color: Colors.white),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              name,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: TextStyle(fontSize: 13, color: subtitleColor),
            ),
            const SizedBox(height: 24),

            // Banner PRO
            // Banner PRO
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium_rounded, size: 40, color: Colors.amberAccent),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Nâng cấp lên LingoMaster PRO',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Mở khóa toàn bộ bài học, AI chấm điểm không giới hạn.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final int userId = userLocal?['id'] ?? userLocal?['Id'] ?? 0;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UpgradeProScreen(
                            isDarkMode: widget.isDarkMode,
                            userId: userId,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Mua ngay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Menu cài đặt
            Container(
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  _buildMenuTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Thông tin chi tiết cá nhân',
                    textColor: textColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PersonalDetailScreen(
                            isDarkMode: widget.isDarkMode,
                            currentUser: userLocal,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildDivider(borderColor),
                  ListTile(
                    leading: const Icon(Icons.dark_mode_outlined, color: Colors.indigo),
                    title: Text(
                      'Giao diện tối (Dark Mode)',
                      style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                    trailing: Switch.adaptive(
                      value: widget.isDarkMode,
                      onChanged: (value) => widget.onToggleTheme(),
                    ),
                  ),
                  _buildDivider(borderColor),
                  _buildMenuTile(
                    icon: Icons.security_rounded,
                    title: 'Bảo mật cấp 2',
                    textColor: textColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SecurityScreen(
                            isDarkMode: widget.isDarkMode,
                            currentUser: userLocal,
                            onUserUpdated: (updatedUser) {
                              // Cập nhật lại State ở ProfileScreen và báo lên Parent nếu có
                              setState(() {
                                userLocal = updatedUser;
                              });
                              if (widget.onUserUpdated != null) {
                                widget.onUserUpdated!(updatedUser);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Phần Giới thiệu & Đăng xuất
            Container(
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  _buildMenuTile(
                    icon: Icons.info_outline_rounded,
                    title: 'Giới thiệu về LingoMaster',
                    textColor: textColor,
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'LingoMaster',
                        applicationVersion: '1.0.0',
                        applicationIcon: const Icon(Icons.school, color: Colors.indigo, size: 40),
                        children: const [
                          SizedBox(height: 10),
                          Text('LingoMaster là ứng dụng học ngoại ngữ thông minh kết hợp trí tuệ nhân tạo (AI) giúp luyện phát âm và giao tiếp hiệu quả.'),
                        ],
                      );
                    },
                  ),
                  _buildDivider(borderColor),
                  _buildMenuTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Điều khoản và Chính sách',
                    textColor: textColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TermsAndPolicyScreen(isDarkMode: widget.isDarkMode),
                        ),
                      );
                    },
                  ),
                  _buildDivider(borderColor),
                  _buildMenuTile(
                    icon: Icons.logout_rounded,
                    title: 'Đăng xuất',
                    textColor: Colors.redAccent,
                    onTap: () {
                      if (widget.onLogout != null) {
                        widget.onLogout!();
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor == Colors.redAccent ? Colors.redAccent : Colors.indigo),
      title: Text(
        title,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 14),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildDivider(Color borderColor) {
    return Divider(height: 1, thickness: 1, color: borderColor, indent: 16, endIndent: 16);
  }
}