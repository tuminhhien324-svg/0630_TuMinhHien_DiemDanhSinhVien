import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ConfigUrl {
  static String? _overrideUrl;

  static Future<void> loadSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    _overrideUrl = prefs.getString('custom_base_url');
  }

  static Future<void> setCustomUrl(String url) async {
    var clean = url.trim();
    if (!clean.endsWith('/')) clean = '$clean/';
    if (!clean.endsWith('/api/')) clean = '${clean}api/';
    _overrideUrl = clean;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_base_url', clean);
  }

  static String get baseUrl {
    if (_overrideUrl != null && _overrideUrl!.isNotEmpty) {
      return _overrideUrl!;
    }

    final envUrl = dotenv.env['BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:5276/api/';
    } else if (Platform.isAndroid) {
      return 'http://192.168.1.4:5276/api/';
    } else {
      return 'http://localhost:5276/api/';
    }
  }

  // Endpoints
  static String get loginUrl => '${baseUrl}Authenticate/login';
  static String get loginOtpUrl => '${baseUrl}Authenticate/login-otp';
  static String get sendOtpUrl => '${baseUrl}Authenticate/send-otp';
  static String get faceLoginUrl => '${baseUrl}Authenticate/face-login';
  static String get registerUrl => '${baseUrl}Authenticate/register';
  static String get sendRegisterOtpUrl => '${baseUrl}Authenticate/send-register-otp';
  static String get sendForgotOtpUrl => '${baseUrl}Authenticate/send-forgot-otp';
  static String get resetPasswordOtpUrl => '${baseUrl}Authenticate/reset-password-otp';
  static String get registerFaceUrl => '${baseUrl}Authenticate/register-face';

  static String get classroomsUrl => '${baseUrl}ClassroomApi';
  static String get checkInUrl => '${baseUrl}AttendanceApi/check-in';
  static String get myAttendanceUrl => '${baseUrl}AttendanceApi/history';
  static String classroomAttendanceUrl(int id) => '${baseUrl}AttendanceApi/classroom/$id';

  // Kiểm tra kết nối tới Server
  static Future<bool> testConnection() async {
    try {
      final res = await http.get(Uri.parse(classroomsUrl)).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
