import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bo_de_600_gplx/router/app_router.dart';
import 'package:bo_de_600_gplx/data/data.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String selectedLicenseType = 'HẠNG A1'; // mặc định

  @override
  void initState() {
    super.initState();
    _loadSelectedLicense();
  }

  Future<void> _loadSelectedLicense() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('selected_license') ?? 'HẠNG A1';
    if (!mounted) return;
    setState(() => selectedLicenseType = saved);
  }

  Future<void> _saveSelectedLicense(String license) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_license', license);
  }

  Future<void> _onSelectLicense(String title) async {
    if (title == selectedLicenseType) {
      // đã chọn rồi -> chỉ báo nhẹ
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn đang dùng loại bằng này rồi.')),
      );
      return;
    }

    await _saveSelectedLicense(title);
    if (!mounted) return;

    setState(() => selectedLicenseType = title);

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRouter.home, // ✅ về trang chủ
      (route) => false,
    );
  }

  void _onUpdate2025() {
    // TODO: Gắn logic cập nhật câu hỏi mới/ gọi API đồng bộ dữ liệu
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Đang chuẩn bị cập nhật bộ câu hỏi 2025...')),
    );
    // Ví dụ: Navigator.pushNamed(context, AppRouter.tips);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thiết lập'),
        // để AppBar theo theme hiện tại (không cần ép inversePrimary)
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Cập nhật 94 câu hỏi lý thuyết 2025',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Thực hiện cập nhật'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _onUpdate2025,
          ),
          const SizedBox(height: 16),
          Text(
            'Chọn bằng lái xe',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          ...licenseTypes.map((item) {
            final title = item['title']!;
            final desc = item['description']!;
            final isSelected = title == selectedLicenseType;

            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                side: isSelected
                    ? const BorderSide(color: Colors.lightBlue, width: 2)
                    : BorderSide.none,
                borderRadius: BorderRadius.circular(8),
              ),
              color: isSelected ? Colors.lightBlue.shade50 : Colors.white,
              child: ListTile(
                leading: const Icon(Icons.motorcycle, color: Colors.green),
                title: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(desc),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.lightBlue)
                    : null,
                onTap: () => _onSelectLicense(title), // ✅ dùng hàm chung
              ),
            );
          }),
          const SizedBox(height: 16),
          const Text(
            'PHIÊN BẢN ỨNG DỤNG: 4.1.0',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
