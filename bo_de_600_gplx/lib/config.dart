class AppConfig {
  static const String baseUrl = "http://10.0.2.2:5002"; // Android emulator
  // static const String baseUrl = "http://127.0.0.1:5002"; // iOS simulator
  // static const String baseUrl = "http://192.168.1.10:5002";      // điện thoại thật

  static String get ttsUrl => "$baseUrl/tts";
  static String get healthUrl => "$baseUrl/health";
}
