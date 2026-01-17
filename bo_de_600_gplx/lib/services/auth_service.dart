import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl =
      "http://10.0.2.2:8080/api"; // đổi thành IP emulator
// Bearer token
  static Future<Map<String, String>> authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  // Hàm đăng ký
  static Future<Map<String, dynamic>> register(
      String username, String email, String password) async {
    try {
      final url = Uri.parse("$baseUrl/register");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "error": jsonDecode(response.body)["message"] ?? "Đăng ký thất bại"
        };
      }
    } catch (e) {
      return {"error": "Lỗi kết nối: $e"};
    }
  }

  // Hàm đăng nhập
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      final url = Uri.parse("$baseUrl/login"); // đúng endpoint Express

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final body = jsonDecode(response.body);
        return {"error": body["message"] ?? "Đăng nhập thất bại"};
      }
    } catch (e) {
      return {"error": "Lỗi kết nối: $e"};
    }
  }
}
