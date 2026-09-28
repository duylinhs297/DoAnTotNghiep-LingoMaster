import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'features/battle/battle_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/auth/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LingoMasterApp());
}

class LingoMasterApp extends StatefulWidget {
  const LingoMasterApp({super.key});

  @override
  State<LingoMasterApp> createState() => _LingoMasterAppState();
}

class _LingoMasterAppState extends State<LingoMasterApp> {
  bool isDarkMode = false;

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LingoMaster',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: AuthWrapper(
        isDarkMode: isDarkMode,
        onToggleTheme: toggleTheme,
      ),
    );
  }
}

// ==========================================
// BỘ ĐIỀU HƯỚNG TRẠNG THÁI XÁC THỰC
// ==========================================
class AuthWrapper extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const AuthWrapper({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoggedIn = false;
  Map<String, dynamic>? _currentUser;

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return LoginScreen(
        onLoginSuccess: (userData) {
          setState(() {
            _currentUser = userData;
            _isLoggedIn = true;
          });
        },
      );
    } else {
      return MainNavigationContainer(
        isDarkMode: widget.isDarkMode,
        onToggleTheme: widget.onToggleTheme,
        currentUser: _currentUser,
        onLogout: () {
          setState(() {
            _currentUser = null;
            _isLoggedIn = false;
          });
        },
      );
    }
  }
}

// ==========================================
// CONTAINER ĐIỀU HƯỚNG CHÍNH
// ==========================================
class MainNavigationContainer extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onLogout;
  final Map<String, dynamic>? currentUser;

  const MainNavigationContainer({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onLogout,
    this.currentUser,
  });

  @override
  State<MainNavigationContainer> createState() => _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> {
  int _currentIndex = 0;
  bool _isLoading = true;

  String currentLevel = 'Sơ cấp';
  bool isTrungCapUnlocked = true;
  bool isCaoCapUnlocked = false;

  // Biến lưu trạng thái user hiện tại có thể được cập nhật khi mua PRO
  Map<String, dynamic>? _currentNavUser;

  // Trạng thái hoàn thành chế độ thi đấu mới (bỏ phân cấp)
  Map<String, bool> battleModeStatesMap = {
    'vocab_basic': false,
    'office_english': false,
    'idioms_slang': false,
    'academic_ted': false,
  };

  @override
  void initState() {
    super.initState();
    _currentNavUser = widget.currentUser;
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentLevel = _currentNavUser?['level'] ?? prefs.getString('user_current_level') ?? 'Sơ cấp';
      isTrungCapUnlocked = prefs.getBool('is_trung_cap_unlocked') ?? true;
      isCaoCapUnlocked = prefs.getBool('is_cao_cap_unlocked') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _updateLevel(String newLevel) async {
    setState(() {
      currentLevel = newLevel;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_current_level', newLevel);
  }

  Future<void> _unlockLevel(String level) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (level == 'Trung cấp') {
        isTrungCapUnlocked = true;
        prefs.setBool('is_trung_cap_unlocked', true);
      }
      if (level == 'Cao cấp') {
        isCaoCapUnlocked = true;
        prefs.setBool('is_cao_cap_unlocked', true);
      }
    });
  }

  void _updateBattleModeStates(Map<String, bool> newStates) {
    setState(() {
      battleModeStatesMap = newStates;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            isDarkMode: widget.isDarkMode,
            onToggleTheme: widget.onToggleTheme,
            currentLevel: currentLevel,
            onLevelChanged: _updateLevel,
            isTrungCapUnlocked: isTrungCapUnlocked,
            isCaoCapUnlocked: isCaoCapUnlocked,
            onUnlockLevel: _unlockLevel,
            currentUserData: _currentNavUser, // Truyền thông tin user mới nhất vào HomeScreen
          ),
          BattleScreen(
            isDarkMode: widget.isDarkMode,
            battleModeStates: battleModeStatesMap,
            onModeCompleted: _updateBattleModeStates,
          ),
          ProfileScreen(
            isDarkMode: widget.isDarkMode,
            onToggleTheme: widget.onToggleTheme,
            currentUser: _currentNavUser,
            onLogout: widget.onLogout,
            onUserUpdated: (updatedUser) {
              // Lắng nghe khi user mua PRO hoặc cập nhật thông tin thành công từ ProfileScreen
              setState(() {
                _currentNavUser = updatedUser;
              });
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_esports_outlined),
            selectedIcon: Icon(Icons.sports_esports_rounded),
            label: 'Thi đấu',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}