import 'package:flutter/material.dart';

class TipsScreen extends StatelessWidget {
  const TipsScreen({super.key});

  Color get primaryColor => const Color(0xFF005A9C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'Các mẹo ghi nhớ',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mẹo 600 câu hỏi ôn thi GPLX',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: 'Mẹo chọn đáp án nhanh',
                children: [
                  bulletPoint(
                    'Trong đáp án có các từ: “Bị nghiêm cấm”, “Không được” → CHỌN NGAY đáp án đó.',
                  ),
                  bulletPoint(
                    'Trong đáp án có: “UBND cấp tỉnh”, “Cơ quan, tổ chức, cá nhân” → CHỌN NGAY đáp án đó.',
                  ),
                  bulletPoint(
                    'Câu hỏi có cụm từ trong ngoặc kép (ví dụ: “Phương tiện tham gia …”) → chọn đáp án “Cả ý 1 và ý 2”.',
                  ),
                ],
              ),
              _buildSection(
                title: 'Khái niệm phương tiện',
                children: [
                  bulletPoint(
                    '“Phương tiện giao thông cơ giới đường bộ” → chọn đáp án KHÔNG có “xe cho người khuyết tật”.',
                  ),
                  bulletPoint(
                    '“Phương tiện giao thông thô sơ đường bộ” → chọn đáp án CÓ “xe cho người khuyết tật” nhưng KHÔNG có “xe gắn máy”.',
                  ),
                ],
              ),
              _buildSection(
                title: 'Người điều khiển giao thông',
                children: [
                  bulletPoint(
                    'Câu hỏi về người điều khiển giao thông → chọn đáp án có “Cảnh sát giao thông”.',
                  ),
                ],
              ),
              _buildSection(
                title: 'Dừng xe – Đỗ xe',
                children: [
                  bulletPoint(
                    'Dừng xe: đứng yên TẠM THỜI, có GIỚI HẠN thời gian.',
                  ),
                  bulletPoint(
                    'Đỗ xe: đứng yên KHÔNG GIỚI HẠN thời gian.',
                  ),
                  bulletPoint(
                    'Mẹo nhớ: “Dừng” = tạm thời, “Đỗ” = lâu dài.',
                  ),
                ],
              ),
              _buildSection(
                title: 'Tuổi lái xe',
                children: [
                  bulletPoint(
                    'Từ 16 đến dưới 18 tuổi → lái xe gắn máy dung tích xi-lanh dưới 50 cm³.',
                  ),
                  bulletPoint(
                    'Từ 18 tuổi trở lên → lái mô tô, xe máy dung tích xi-lanh từ 50 cm³ trở lên.',
                  ),
                ],
              ),
              _buildSection(
                title: 'Cấp hạng bằng mô tô',
                children: [
                  bulletPoint(
                    'A1: Lái xe mô tô 2 bánh từ 50 cm³ đến dưới 175 cm³ và xe mô tô 3 bánh cho người khuyết tật.',
                  ),
                  bulletPoint(
                    'A2: Lái xe mô tô 2 bánh có dung tích xi-lanh từ 175 cm³ trở lên.',
                  ),
                  bulletPoint(
                    'Mẹo nhớ nhanh: dưới 175 cm³ → A1, từ 175 cm³ trở lên → A2.',
                  ),
                ],
              ),
              _buildSection(
                title: 'Nhường đường',
                children: [
                  bulletPoint(
                    'Ưu tiên nhường: phương tiện đường sắt.',
                  ),
                  bulletPoint(
                    'Ưu tiên nhường: người đi bộ đang đi trên phần đường ưu tiên người đi bộ.',
                  ),
                  bulletPoint(
                    'Ưu tiên nhường: xe đang đi trên đường chính.',
                  ),
                ],
              ),
              _buildSection(
                title: 'Vòng xuyến',
                children: [
                  bulletPoint(
                    'Có báo hiệu đi theo vòng xuyến → nhường phương tiện bên TAY TRÁI.',
                  ),
                  bulletPoint(
                    'Không có báo hiệu đi theo vòng xuyến → nhường phương tiện bên TAY PHẢI.',
                  ),
                ],
              ),
              _buildSection(
                title: 'Đông dân cư',
                children: [
                  bulletPoint(
                    'Đề bài KHÔNG có số → chọn đáp án số 2.',
                  ),
                  bulletPoint(
                    'Đề bài CÓ số → chọn đáp án có cụm từ “xe gắn máy” ở cuối đáp án.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Card cho từng nhóm mẹo
  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  /// Dòng bullet
  Widget bulletPoint(String text, {double indent = 0}) {
    return Padding(
      padding: EdgeInsets.only(left: indent + 4, top: 4, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(fontSize: 16),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16, // to hơn nhưng không quá to
                height: 1.4,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
