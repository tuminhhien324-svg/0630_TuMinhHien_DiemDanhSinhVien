class AttendanceModel {
  final int id;
  final String studentId;
  final String studentName;
  final String? studentCode;
  final int classroomId;
  final String? classroomName;
  final String? room;
  final DateTime checkInTime;
  final double latitude;
  final double longitude;
  final double distanceMeters;
  final String? faceImage;
  final String status;
  final String? note;

  AttendanceModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.studentCode,
    required this.classroomId,
    this.classroomName,
    this.room,
    required this.checkInTime,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    this.faceImage,
    required this.status,
    this.note,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedTime = DateTime.now();
    if (json['checkInTime'] != null) {
      try {
        parsedTime = DateTime.parse(json['checkInTime']);
      } catch (_) {}
    }

    String? className;
    String? classRoom;
    if (json['classroom'] != null) {
      className = json['classroom']['name'];
      classRoom = json['classroom']['room'];
    }

    return AttendanceModel(
      id: json['id'] ?? 0,
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? 'Sinh viên',
      studentCode: json['studentCode'],
      classroomId: json['classroomId'] ?? 0,
      classroomName: className,
      room: classRoom,
      checkInTime: parsedTime,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0.0,
      faceImage: json['faceImage'],
      status: json['status'] ?? 'Có mặt',
      note: json['note'],
    );
  }
}
