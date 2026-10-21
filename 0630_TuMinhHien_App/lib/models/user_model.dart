class UserModel {
  final String username;
  final String? fullName;
  final String? studentCode;
  final String? email;
  final String role;
  final String token;
  final bool hasFaceData;

  UserModel({
    required this.username,
    this.fullName,
    this.studentCode,
    this.email,
    required this.role,
    required this.token,
    this.hasFaceData = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String token) {
    return UserModel(
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? json['username'],
      studentCode: json['studentCode'],
      email: json['email'],
      role: json['role'] ?? 'User',
      token: token,
      hasFaceData: json['hasFaceData'] ?? false,
    );
  }
}
