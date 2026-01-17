import 'dart:convert';
import 'package:http/http.dart' as http;

class LearnService {
  static const String baseUrl =
      "http://10.0.2.2:8080/api"; // đổi thành IP emulator

  /// Lấy danh sách tất cả chương
  static Future<List<dynamic>> getChapters() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/chapters"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data["items"] ??
            data; // Nếu backend trả {"items": [...]} thì lấy items
      } else {
        throw Exception("Không lấy được danh sách chương");
      }
    } catch (e) {
      throw Exception("Lỗi kết nối: $e");
    }
  }


  /// ✅ Lấy danh sách chương đầy đủ (có id, title, chapter_tag)
  static Future<List<Map<String, dynamic>>> getChaptersFull() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/chapters"));
      if (response.statusCode != 200) {
        throw Exception("Không lấy được danh sách chương");
      }

      final data = json.decode(response.body);
      final List items = data["items"] ?? data;

      return items.map<Map<String, dynamic>>((e) {
        return {
          'id': e['id'], // record id của chương
          'title': e['title'] ?? 'Chương chưa đặt tên',
          'chapter_tag': e['chapter_tag'] ?? e['tag'] ?? e['id'],
        };
      }).toList();
    } catch (e) {
      throw Exception("Lỗi kết nối: $e");
    }
  }

  /// Lấy chi tiết 1 chương
  static Future<Map<String, dynamic>> getChapterById(String id) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/chapters/$id"));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception("Không tìm thấy chương");
      }
    } catch (e) {
      throw Exception("Lỗi kết nối: $e");
    }
  }

  /// Lấy danh sách tất cả bài học
  static Future<List<dynamic>> getLessons() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/lessons"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data["items"] ?? data;
      } else {
        throw Exception("Không lấy được danh sách bài học");
      }
    } catch (e) {
      throw Exception("Lỗi kết nối: $e");
    }
  }

  /// Lấy chi tiết 1 bài học
  static Future<Map<String, dynamic>> getLessonById(String id) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/lessons/$id"));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception("Không tìm thấy bài học");
      }
    } catch (e) {
      throw Exception("Lỗi kết nối: $e");
    }
  }

  /// Lấy danh sách bài học theo chapter_id
  static Future<List<dynamic>> getLessonsByChapter(String chapterId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/lessons/by-chapter/$chapterId"),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data["items"] ?? data;
      } else {
        throw Exception("Không lấy được bài học của chương này");
      }
    } catch (e) {
      throw Exception("Lỗi kết nối: $e");
    }
  }

  // Lấy danh sách nội dung bài học theo lesson_id
  static Future<List<dynamic>> getLessonContentsByLessonId(
      String lessonId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/lesson-contents/by-lesson/$lessonId"),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // data là List chứ không phải Map
        if (data is List) {
          return data;
        } else {
          throw Exception("Không lấy được nội dung của bài học");
        }
      } else {
        throw Exception("Không lấy được nội dung của bài học");
      }
    } catch (e) {
      throw Exception("Lỗi kết nối: $e");
    }
  }
}
