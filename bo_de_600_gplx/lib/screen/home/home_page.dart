import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bo_de_600_gplx/router/app_router.dart';
import 'package:bo_de_600_gplx/data/data.dart';

import 'package:bo_de_600_gplx/screen/progress/progress.dart';
import 'package:bo_de_600_gplx/screen/result/history_page.dart';
import 'package:bo_de_600_gplx/screen/settings/setting_page.dart';
import 'package:bo_de_600_gplx/screen/review_question/chapter_picker.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class FeatureTile extends StatelessWidget {
  final String asset;
  final String title;
  final VoidCallback onTap;

  const FeatureTile({
    super.key,
    required this.asset,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEAEAEA)), // viền mảnh
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 10,
                offset: Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          child: LayoutBuilder(
            builder: (context, c) {
              // Icon scale theo kích thước tile
              final side = c.maxWidth;
              final iconSize = side * 0.50;

              return Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Container(
                        width: iconSize * 1.15,
                        height: iconSize * 1.15,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F7FF), // nền nhạt sau icon
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Image.asset(
                          asset,
                          width: iconSize,
                          height: iconSize,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  String username = "Người dùng";
  String email = "email@example.com";
  int _selectedIndex = 0; // Tab hiện tại

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString("username") ?? "Người dùng";
      email = prefs.getString("email") ?? "email@example.com";
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    await prefs.remove("username");
    await prefs.remove("email");
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRouter.login);
  }

  // ====== KHUNG CHÀO ======
  Widget _buildGreetingCard() {
    final primary = const Color(0xFF3A7AFE);
    final secondary = const Color(0xFF5AA7FF);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                "Hi, ",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                username,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          // Icon chuông thông báo bên phải
          Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: Colors.white.withOpacity(0.15),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _showAccountDialog,
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.notifications_none,
                        color: Colors.white, size: 28),
                  ),
                ),
              ),
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft, // 🔹 ép căn trái
        child: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            "Danh mục học tập",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeWithGreeting() {
    return Column(
      children: [
        _buildGreetingCard(),
        _buildSectionHeader(),
        Expanded(
          child: _buildHomeGrid(),
        ),
      ],
    );
  }

  // ====== CHỨC NĂNG HOME ======
  void _handleFeatureTap(String title) async {
    switch (title) {
      case 'Học lý thuyết':
        Navigator.pushNamed(context, AppRouter.theory);
        break;
      case 'Đề ngẫu nhiên':
        Navigator.pushNamed(context, AppRouter.randomQuestions);
        break;
      case 'Thi theo bộ đề':
        Navigator.pushNamed(context, AppRouter.examList);
        break;
      case 'Xem câu sai':
        Navigator.pushNamed(context, AppRouter.wrongQuestions);
        break;
      case 'Ôn tập câu hỏi':
        await openChapterPicker(context);
        break;
      case 'Câu hỏi điểm liệt':
        Navigator.pushNamed(context, AppRouter.diemLiet);
        break;
      case 'Biển báo':
        Navigator.pushNamed(context, AppRouter.trafficSigns);
        break;
      case 'Mẹo học tập':
        Navigator.pushNamed(context, AppRouter.tips);
        break;
      // case 'Top 50 câu sai':
      //   Navigator.pushNamed(context, AppRouter.top50Wrong);
      //   break;
    }
  }

  void _showAccountDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Tài khoản"),
        content: Text("Xin chào, $username\nEmail: $email"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đóng"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text("Đăng xuất"),
          ),
        ],
      ),
    );
  }

  // Grid tính năng
  Widget _buildHomeGrid() {
    final height = MediaQuery.of(context).size.height;
    final aspect = height < 700 ? 1.6 : 1.8;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 6, 2),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200, // 🔹 khung màu xám nhạt
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
        child: GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: features
              .map((item) => FeatureTile(
                    asset: item['asset']!,
                    title: item['title'] as String,
                    onTap: () => _handleFeatureTap(item['title'] as String),
                  ))
              .toList(),
        ),
      ),
    );
  }

  // Tiêu đề các tab
  final List<String> _tabTitles = [
    'DrivePrep',
    'Tiến trình học',
    'Lịch sử thi',
    'Cài đặt',
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      SafeArea(child: _buildHomeWithGreeting()), // <— Trang chủ có khung chào
      const ProgressPage(),
      const HistoryPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 133, 196, 235),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          _tabTitles[_selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: _showAccountDialog,
            tooltip: 'Tài khoản',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, AppRouter.settings),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(username),
              accountEmail: Text(email),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40),
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2C5C7C), Color(0xFF345F80)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Cài đặt"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRouter.settings);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Đăng xuất"),
              onTap: _logout,
            ),
          ],
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 63, 127, 170),
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: ClipRRect(
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (i) => setState(() => _selectedIndex = i),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color.fromARGB(255, 10, 102, 189),
            unselectedItemColor: const Color.fromARGB(255, 69, 67, 67),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart), label: 'Tiến trình'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.history), label: 'Lịch sử'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.settings), label: 'Cài đặt'),
            ],
          ),
        ),
      ),
    );
  }
}
