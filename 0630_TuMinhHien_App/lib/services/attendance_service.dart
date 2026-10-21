import 'dart:convert';
import '../config/config_url.dart';
import '../models/attendance_model.dart';
import 'api_client.dart';

class AttendanceService {
  // Sinh viên bấm Điểm danh (Gửi GPS + Ảnh khuôn mặt)
  static Future<Map<String, dynamic>> checkIn({
    required int classroomId,
    required double latitude,
    required double longitude,
    String? faceImage,
    String? studentCode,
    String? note,
  }) async {
    try {
      final response = await ApiClient.post(
        ConfigUrl.checkInUrl,
        {
          'classroomId': classroomId,
          'latitude': latitude,
          'longitude': longitude,
          'faceImage': faceImage,
          'studentCode': studentCode,
          'note': note,
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Điểm danh hoàn tất',
          'status': data['status'] ?? 'Có mặt',
          'distance': data['distanceMeters'] ?? 0.0,
          'allowedRadius': data['allowedRadiusMeters'] ?? 100.0,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Lỗi khi điểm danh',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối điểm danh: $e'};
    }
  }

  // Sinh viên xem lịch sử điểm danh của mình
  static Future<List<AttendanceModel>> getMyHistory() async {
    try {
      final response = await ApiClient.get(ConfigUrl.myAttendanceUrl);
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((item) => AttendanceModel.fromJson(item)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // Giảng viên / Admin xem danh sách điểm danh của lớp
  static Future<List<AttendanceModel>> getClassroomAttendance(int classroomId) async {
    try {
      final response = await ApiClient.get(ConfigUrl.classroomAttendanceUrl(classroomId));
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((item) => AttendanceModel.fromJson(item)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // Giảng viên cập nhật trạng thái điểm danh
  static Future<bool> updateStatus(int recordId, String status, [String? note]) async {
    try {
      final response = await ApiClient.put(
        '${ConfigUrl.baseUrl}AttendanceApi/$recordId/status',
        {'status': status, 'note': note},
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Xóa bản ghi điểm danh
  static Future<bool> deleteRecord(int recordId) async {
    try {
      final response = await ApiClient.delete('${ConfigUrl.baseUrl}AttendanceApi/$recordId');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
