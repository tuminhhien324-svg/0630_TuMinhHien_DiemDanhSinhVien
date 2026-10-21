import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config_url.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class AuthService {
  // Gửi mã OTP
  static Future<Map<String, dynamic>> sendOtp(String usernameOrEmail) async {
    try {
      final response = await ApiClient.post(
        ConfigUrl.sendOtpUrl,
        {'username': usernameOrEmail},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Đã gửi mã OTP',
          'otp': data['otp'], // Mã OTP trả về từ server để hỗ trợ demo trực tiếp
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Không thể gửi mã OTP',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối máy chủ: $e'};
    }
  }

  // Đăng nhập Username + Password + OTP
  static Future<Map<String, dynamic>> loginWithOtp({
    required String username,
    required String password,
    required String otp,
  }) async {
    try {
      final response = await ApiClient.post(
        ConfigUrl.loginOtpUrl,
        {
          'username': username,
          'password': password,
          'otp': otp,
        },
      );

      return await _handleLoginResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Đăng nhập chuẩn (Username + Password)
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    String? otp,
  }) async {
    try {
      final response = await ApiClient.post(
        ConfigUrl.loginUrl,
        {
          'username': username,
          'password': password,
          if (otp != null && otp.isNotEmpty) 'otp': otp,
        },
      );

      return await _handleLoginResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // ĐĂNG NHẬP BẰNG KHUÔN MẶT (Face Login)
  static Future<Map<String, dynamic>> faceLogin({
    String? studentCode,
    String? username,
    required String faceImageBase64,
  }) async {
    try {
      final response = await ApiClient.post(
        ConfigUrl.faceLoginUrl,
        {
          if (studentCode != null) 'studentCode': studentCode,
          if (username != null) 'username': username,
          'faceImage': faceImageBase64,
        },
      );

      return await _handleLoginResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối Face Login: $e'};
    }
  }

  // ĐĂNG KÝ / CẬP NHẬT FACE ID CHO TÀI KHOẢN
  static Future<Map<String, dynamic>> registerFace({
    String? username,
    String? studentCode,
    required String faceImageBase64,
  }) async {
    try {
      final response = await ApiClient.post(
        ConfigUrl.registerFaceUrl,
        {
          if (username != null && username.isNotEmpty) 'username': username,
          if (studentCode != null && studentCode.isNotEmpty) 'studentCode': studentCode,
          'faceImage': faceImageBase64,
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && (data['status'] == true || data['Status'] == true)) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_face_id', true);
        return {
          'success': true,
          'message': data['message'] ?? data['Message'] ?? 'Đăng ký Face ID thành công',
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? data['Message'] ?? 'Không thể đăng ký Face ID',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối Face ID: $e'};
    }
  }

  // 1. Gửi mã OTP xác nhận Email khi Đăng ký
  static Future<Map<String, dynamic>> sendRegisterOtp(String email) async {
    try {
      final response = await ApiClient.post(
        ConfigUrl.sendRegisterOtpUrl,
        {'email': email},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && (data['status'] == true || data['Status'] == true)) {
        return {
          'success': true,
          'message': data['message'] ?? 'Đã gửi mã xác nhận OTP về Email',
          'otp': data['otp'] ?? data['Otp'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Không thể gửi mã OTP đăng ký',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối máy chủ: $e'};
    }
  }

  // 2. Đăng ký tài khoản qua Email (Kèm OTP)
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? fullName,
    String? studentCode,
    required String role,
    String? otp,
  }) async {
    try {
      final response = await ApiClient.post(
        ConfigUrl.registerUrl,
        {
          'username': username,
          'email': email,
          'password': password,
          'fullName': fullName,
          'studentCode': studentCode,
          'role': role,
          if (otp != null && otp.isNotEmpty) 'otp': otp,
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && (data['status'] == true || data['Status'] == true)) {
        return {
          'success': true,
          'message': data['message'] ?? 'Đăng ký thành công',
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Đăng ký thất bại',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // 3. Gửi mã OTP Quên mật khẩu
  static Future<Map<String, dynamic>> sendForgotOtp(String identifier) async {
    try {
      final response = await ApiClient.post(
        ConfigUrl.sendForgotOtpUrl,
        {'identifier': identifier},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && (data['status'] == true || data['Status'] == true)) {
        return {
          'success': true,
          'message': data['message'] ?? 'Đã tạo mã OTP đặt lại mật khẩu',
          'otp': data['otp'] ?? data['Otp'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Không tìm thấy tài khoản',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối máy chủ: $e'};
    }
  }

  // 4. Đặt lại mật khẩu bằng mã OTP
  static Future<Map<String, dynamic>> resetPasswordOtp({
    required String identifier,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await ApiClient.post(
        ConfigUrl.resetPasswordOtpUrl,
        {
          'identifier': identifier,
          'otp': otp,
          'newPassword': newPassword,
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && (data['status'] == true || data['Status'] == true)) {
        return {
          'success': true,
          'message': data['message'] ?? 'Đặt lại mật khẩu thành công',
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Đặt lại mật khẩu thất bại',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối máy chủ: $e'};
    }
  }

  // Xử lý phản hồi đăng nhập chung & lưu token vào SharedPreferences
  static Future<Map<String, dynamic>> _handleLoginResponse(dynamic response) async {
    try {
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        final token = data['token'] as String;

        // Decode token để lấy thông tin claim
        Map<String, dynamic> decoded = {};
        try {
          decoded = JwtDecoder.decode(token);
        } catch (_) {}

        final role = data['role'] ?? decoded['role'] ?? 'User';
        final username = data['username'] ?? decoded['unique_name'] ?? '';
        final fullName = data['fullName'] ?? decoded['fullName'] ?? username;
        final studentCode = data['studentCode'] ?? decoded['studentCode'] ?? '';

        // Lưu vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setString('user_role', role);
        await prefs.setString('user_name', username);
        await prefs.setString('full_name', fullName);
        await prefs.setString('student_code', studentCode);

        final user = UserModel.fromJson(data, token);

        return {
          'success': true,
          'token': token,
          'role': role,
          'user': user,
          'message': data['message'] ?? 'Đăng nhập thành công',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Tên đăng nhập hoặc mật khẩu không chính xác',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Dữ liệu phản hồi không hợp lệ: $e'};
    }
  }

  // Kiểm tra phiên đăng nhập tự động khi mở app
  static Future<UserModel?> checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) return null;

    // Kiểm tra token còn hạn không
    if (JwtDecoder.isExpired(token)) {
      await logout();
      return null;
    }

    final role = prefs.getString('user_role') ?? 'User';
    final username = prefs.getString('user_name') ?? '';
    final fullName = prefs.getString('full_name') ?? username;
    final studentCode = prefs.getString('student_code');

    return UserModel(
      username: username,
      fullName: fullName,
      studentCode: studentCode,
      role: role,
      token: token,
    );
  }

  // Đăng xuất (xóa token và thông tin)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_role');
    await prefs.remove('user_name');
    await prefs.remove('full_name');
    await prefs.remove('student_code');
  }
}
