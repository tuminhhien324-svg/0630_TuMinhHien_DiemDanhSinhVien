class ClassroomModel {
  final int id;
  final String code;
  final String name;
  final String room;
  final String lecturerName;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String scheduleTime;

  ClassroomModel({
    required this.id,
    required this.code,
    required this.name,
    required this.room,
    required this.lecturerName,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.scheduleTime,
  });

  factory ClassroomModel.fromJson(Map<String, dynamic> json) {
    return ClassroomModel(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      room: json['room'] ?? '',
      lecturerName: json['lecturerName'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 10.762622,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 106.660172,
      radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 100.0,
      scheduleTime: json['scheduleTime'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'room': room,
      'lecturerName': lecturerName,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'scheduleTime': scheduleTime,
    };
  }
}
