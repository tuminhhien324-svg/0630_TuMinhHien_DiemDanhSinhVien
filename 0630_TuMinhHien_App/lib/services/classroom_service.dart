import 'dart:convert';
import '../config/config_url.dart';
import '../models/classroom_model.dart';
import 'api_client.dart';

class ClassroomService {
  // Lấy danh sách lớp học
  static Future<List<ClassroomModel>> getClassrooms() async {
    try {
      final response = await ApiClient.get(ConfigUrl.classroomsUrl);
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((item) => ClassroomModel.fromJson(item)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // Lấy chi tiết 1 lớp học
  static Future<ClassroomModel?> getClassroomById(int id) async {
    try {
      final response = await ApiClient.get('${ConfigUrl.classroomsUrl}/$id');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ClassroomModel.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Thêm lớp học mới (Admin / Staff)
  static Future<bool> addClassroom(ClassroomModel classroom) async {
    try {
      final response = await ApiClient.post(
        ConfigUrl.classroomsUrl,
        classroom.toJson(),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // Cập nhật lớp học (Admin / Staff)
  static Future<bool> updateClassroom(ClassroomModel classroom) async {
    try {
      final response = await ApiClient.put(
        '${ConfigUrl.classroomsUrl}/${classroom.id}',
        classroom.toJson(),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Xóa lớp học (Admin)
  static Future<bool> deleteClassroom(int id) async {
    try {
      final response = await ApiClient.delete('${ConfigUrl.classroomsUrl}/$id');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
