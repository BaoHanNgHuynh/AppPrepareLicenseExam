import 'package:flutter/material.dart';
import 'package:bo_de_600_gplx/models/trafficSign.dart';
import 'package:bo_de_600_gplx/services/trafficSign_service.dart';
import 'traffic_sign_detail_page.dart';
import 'traffic_tip.dart';

class TrafficSignsScreen extends StatefulWidget {
  const TrafficSignsScreen({super.key});

  @override
  State<TrafficSignsScreen> createState() => _TrafficSignsScreenState();
}

class _TrafficSignsScreenState extends State<TrafficSignsScreen> {
  String searchText = "";
  late Future<List<TrafficSign>> _future;

  bool _tipsExpanded = false;

  // ✅ NEW: phân loại thêm I (chỉ dẫn) và S (phụ), hỗ trợ cả dạng "408", "501"
  bool _isIndicative(String signId) {
    final id = signId.trim().toUpperCase();
    if (id.startsWith('I.')) return true;

    // nếu chỉ là số thuần (vd: "408") -> coi là chỉ dẫn khi thuộc 4xx
    if (RegExp(r'^\d+$').hasMatch(id)) {
      final n = int.tryParse(id);
      return n != null && n >= 400 && n < 500;
    }
    return false;
  }

  bool _isSupplementary(String signId) {
    final id = signId.trim().toUpperCase();
    if (id.startsWith('S.')) return true;

    // nếu chỉ là số thuần (vd: "501") -> coi là biển phụ khi thuộc 5xx
    if (RegExp(r'^\d+$').hasMatch(id)) {
      final n = int.tryParse(id);
      return n != null && n >= 500 && n < 600;
    }
    return false;
  }

  void _toggleTipsFab() {
    setState(() => _tipsExpanded = !_tipsExpanded);

    // tự thu lại sau 2.5s (giống hover-out)
    if (_tipsExpanded) {
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (!mounted) return;
        setState(() => _tipsExpanded = false);
      });
    }
  }

  // ✅ Tap 2 lần: lần 1 bung chữ, lần 2 mở trang
  void _onTipsTap() {
    if (!_tipsExpanded) {
      _toggleTipsFab(); // tap 1 -> bung
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrafficSignTipsPage()),
    );

    // thu lại luôn (tuỳ chọn)
    setState(() => _tipsExpanded = false);
  }

  @override
  void initState() {
    super.initState();
    _future = TrafficSignService().fetchAll();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TrafficSign>>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Scaffold(body: Center(child: Text('Error: ${snap.error}')));
        }

        final signs = snap.data ?? [];

        List<TrafficSign> filter(List<TrafficSign> list) {
          if (searchText.isEmpty) return list;
          final lower = searchText.toLowerCase();
          return list
              .where((s) =>
                  s.title.toLowerCase().contains(lower) ||
                  s.signId.toLowerCase().contains(lower))
              .toList();
        }

        // 3 nhóm cũ
        final prohibitory = filter(
          signs
              .where((s) => s.signId.trim().toUpperCase().startsWith('P.'))
              .toList(),
        );
        final warning = filter(
          signs
              .where((s) => s.signId.trim().toUpperCase().startsWith('W.'))
              .toList(),
        );
        final mandatory = filter(
          signs
              .where((s) => s.signId.trim().toUpperCase().startsWith('R.'))
              .toList(),
        );

        // ✅ 2 nhóm mới
        final indicative =
            filter(signs.where((s) => _isIndicative(s.signId)).toList());
        final supplementary =
            filter(signs.where((s) => _isSupplementary(s.signId)).toList());

        return DefaultTabController(
          length: 5, // ✅ 3 -> 5
          child: Scaffold(
            backgroundColor: const Color(0xFFF4F6FB),

            appBar: AppBar(
              backgroundColor: const Color.fromARGB(255, 42, 111, 153),
              foregroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                'Biển báo giao thông',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              bottom: const TabBar(
                isScrollable: true, // ✅ để 5 tab không bị tràn, vẫn giữ style
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                unselectedLabelStyle:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                labelPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                indicatorColor: Color(0xFFFFD54F),
                indicatorWeight: 3,
                tabs: [
                  Tab(text: 'Cấm'),
                  Tab(text: 'Nguy hiểm'),
                  Tab(text: 'Hiệu lệnh'),
                  Tab(text: 'Chỉ dẫn'),
                  Tab(text: 'Phụ'),
                ],
              ),
            ),

            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Tìm kiếm biển báo...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.black),
                    onChanged: (value) =>
                        setState(() => searchText = value.trim()),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildList(context, prohibitory),
                      _buildList(context, warning),
                      _buildList(context, mandatory),
                      _buildList(context, indicative),
                      _buildList(context, supplementary),
                    ],
                  ),
                ),
              ],
            ),

            // ✅ FAB tap 2 lần (giữ nguyên)
            floatingActionButton: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _onTipsTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: _tipsExpanded ? 14 : 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD54F),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lightbulb_outline,
                          color: Colors.black87, size: 22),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: _tipsExpanded
                            ? const Padding(
                                padding: EdgeInsets.only(left: 8, right: 2),
                                child: Text(
                                  'Mẹo biển báo',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                    fontSize: 15,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          ),
        );
      },
    );
  }

  Widget _buildList(BuildContext ctx, List<TrafficSign> list) {
    if (list.isEmpty) {
      return const Center(child: Text("Không tìm thấy biển báo"));
    }

    return ListView.builder(
      padding:
          const EdgeInsets.only(bottom: 80), // ✅ tránh bị nút che item cuối
      itemCount: list.length,
      itemBuilder: (_, i) {
        final s = list[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isThreeLine: true,
            minVerticalPadding: 12,
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                s.imageUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              '${s.signId} — ${s.title}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Colors.black87,
                height: 1.25,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: Colors.black,
                  ),
                  children: [
                    const TextSpan(
                      text: 'Ý nghĩa: ',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    TextSpan(text: s.description),
                  ],
                ),
                softWrap: true,
              ),
            ),
            onTap: () => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => TrafficSignDetailPage(sign: s)),
            ),
          ),
        );
      },
    );
  }
}
