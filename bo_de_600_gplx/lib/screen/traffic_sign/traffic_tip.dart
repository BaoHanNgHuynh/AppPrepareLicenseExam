import 'package:flutter/material.dart';
import 'package:bo_de_600_gplx/models/trafficSign.dart';
import 'package:bo_de_600_gplx/services/trafficSign_service.dart';

class TrafficSignTipsPage extends StatefulWidget {
  const TrafficSignTipsPage({super.key});

  @override
  State<TrafficSignTipsPage> createState() => _TrafficSignTipsPageState();
}

class _TrafficSignTipsPageState extends State<TrafficSignTipsPage> {
  late Future<List<TrafficSign>> _future;

  @override
  void initState() {
    super.initState();
    _future = TrafficSignService().fetchAll();
  }

  TrafficSign? _pickBySignId(List<TrafficSign> signs, String targetSignId) {
    try {
      return signs.firstWhere(
        (s) =>
            s.signId.trim().toUpperCase() == targetSignId.trim().toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  TrafficSign? _pickByPrefix(List<TrafficSign> signs, String prefix) {
    final p = prefix.trim().toUpperCase();
    try {
      return signs
          .firstWhere((s) => s.signId.trim().toUpperCase().startsWith(p));
    } catch (_) {
      return null;
    }
  }

  // ✅ NEW: match theo nhóm số (vd 4xx, 5xx) hỗ trợ signId là "408", "501"
  TrafficSign? _pickByNumberRange(
    List<TrafficSign> signs, {
    required int minInclusive,
    required int maxExclusive,
  }) {
    for (final s in signs) {
      final raw = s.signId.trim().toUpperCase();

      // chỉ nhận dạng số thuần
      if (RegExp(r'^\d+$').hasMatch(raw)) {
        final n = int.tryParse(raw);
        if (n != null && n >= minInclusive && n < maxExclusive) return s;
      }

      // hỗ trợ nếu bạn có dạng "I.408" / "S.501" mà muốn parse số sau dấu chấm
      final m = RegExp(r'^[A-Z]\.(\d+)$').firstMatch(raw);
      if (m != null) {
        final n = int.tryParse(m.group(1)!);
        if (n != null && n >= minInclusive && n < maxExclusive) return s;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 42, 111, 153),
        foregroundColor: Colors.white,
        title: const Text('Mẹo nhớ biển báo'),
      ),
      body: FutureBuilder<List<TrafficSign>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Lỗi: ${snap.error}'));
          }

          final signs = snap.data ?? [];

          // ✅ ưu tiên ví dụ cụ thể nếu có, không có thì lấy đại 1 biển trong nhóm
          final signP =
              _pickBySignId(signs, 'P.102') ?? _pickByPrefix(signs, 'P.');
          final signW = _pickByPrefix(signs, 'W.');
          final signR = _pickByPrefix(signs, 'R.');

          // ✅ NEW: lấy 2 biển mới thêm
          // - Chỉ dẫn: ưu tiên "408" (bạn đang lưu số), rồi đến "I.", rồi fallback 4xx
          final signI = _pickBySignId(signs, '408') ??
              _pickBySignId(signs, 'I.408') ??
              _pickByPrefix(signs, 'I.') ??
              _pickByNumberRange(signs, minInclusive: 400, maxExclusive: 500);

          // - Phụ: ưu tiên "S.501", nếu bạn có lưu "501" thì cũng bắt được
          final signS = _pickBySignId(signs, 'S.501') ??
              _pickBySignId(signs, '501') ??
              _pickByPrefix(signs, 'S.') ??
              _pickByNumberRange(signs, minInclusive: 500, maxExclusive: 600);

          final tips = <_TipItem>[
            _TipItem(
              title: 'CẤM',
              rule: 'Hình tròn viền đỏ (đa số) → KHÔNG được làm.',
              example: signP != null
                  ? '${signP.signId} — ${signP.title}'
                  : 'Ví dụ: P.xxx',
              imageUrl: signP?.imageUrl,
            ),
            _TipItem(
              title: 'NGUY HIỂM',
              rule: 'Tam giác viền đỏ nền vàng → CẢNH BÁO nguy hiểm.',
              example: signW != null
                  ? '${signW.signId} — ${signW.title}'
                  : 'Ví dụ: W.xxx',
              imageUrl: signW?.imageUrl,
            ),
            _TipItem(
              title: 'HIỆU LỆNH',
              rule: 'Hình tròn nền xanh → BẮT BUỘC phải làm.',
              example: signR != null
                  ? '${signR.signId} — ${signR.title}'
                  : 'Ví dụ: R.xxx',
              imageUrl: signR?.imageUrl,
            ),
            _TipItem(
              title: 'CHỈ DẪN',
              rule: 'Nền xanh, hình vuông/chữ nhật → CHỈ đường, nơi được phép.',
              example: signI != null
                  ? '${signI.signId} — ${signI.title}'
                  : 'Ví dụ: I.xxx / 4xx',
              imageUrl: signI?.imageUrl,
            ),
            _TipItem(
              title: 'BIỂN PHỤ',
              rule: 'Nền trắng/đen → ghi thêm phạm vi, thời gian, khoảng cách…',
              example: signS != null
                  ? '${signS.signId} — ${signS.title}'
                  : 'Ví dụ: S.xxx / 5xx',
              imageUrl: signS?.imageUrl,
            ),
          ];

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tips.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _TipCard(item: tips[i]),
          );
        },
      ),
    );
  }
}

class _TipItem {
  final String title;
  final String rule;
  final String example;
  final String? imageUrl;

  _TipItem({
    required this.title,
    required this.rule,
    required this.example,
    this.imageUrl,
  });
}

class _TipCard extends StatelessWidget {
  final _TipItem item;
  const _TipCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: item.imageUrl == null || item.imageUrl!.isEmpty
                ? Container(
                    width: 78,
                    height: 78,
                    color: const Color(0xFFF1F3F6),
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported_outlined),
                  )
                : Image.network(
                    item.imageUrl!,
                    width: 78,
                    height: 78,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 78,
                      height: 78,
                      color: const Color(0xFFF1F3F6),
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Text(
                    item.rule,
                    style: const TextStyle(
                      fontSize: 16.5,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                      color: Color.fromARGB(255, 25, 89, 142),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ví dụ: ${item.example}',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: Colors.black87,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
