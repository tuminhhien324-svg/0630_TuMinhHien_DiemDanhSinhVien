import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import 'admin/admin_dashboard_screen.dart';
import 'staff/staff_dashboard_screen.dart';
import 'student/student_home_screen.dart';

class FaceLoginScreen extends StatefulWidget {
  final String? studentCode;
  const FaceLoginScreen({super.key, this.studentCode});

  @override
  State<FaceLoginScreen> createState() => _FaceLoginScreenState();
}

class _FaceLoginScreenState extends State<FaceLoginScreen> {
  final _studentCodeController = TextEditingController();
  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.studentCode != null && widget.studentCode!.isNotEmpty) {
      _studentCodeController.text = widget.studentCode!;
    }
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      // Ưu tiên camera trước (front camera) để quét khuôn mặt
      final frontCam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCam,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() => _isCameraReady = true);
    } catch (_) {
      // Nếu camera không khả dụng (máy ảo không có webcam), chuyển sang chế độ chọn ảnh
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _studentCodeController.dispose();
    super.dispose();
  }

  // Chụp ảnh từ Camera và đăng nhập
  Future<void> _captureAndLogin() async {
    final studentCode = _studentCodeController.text.trim();
    if (studentCode.isEmpty) {
      _showMsg('Vui lòng nhập MSSV hoặc Tên đăng nhập trước khi quét mặt', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      String base64Image;

      if (_isCameraReady && _cameraController != null) {
        final xFile = await _cameraController!.takePicture();
        final bytes = await xFile.readAsBytes();
        base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      } else {
        // Fallback: Nếu camera không khởi động được (máy ảo), mở chọn ảnh
        final picked = await _picker.pickImage(source: ImageSource.gallery);
        if (picked == null) {
          setState(() => _isLoading = false);
          return;
        }
        final bytes = await picked.readAsBytes();
        base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }

      final result = await AuthService.faceLogin(
        studentCode: studentCode,
        faceImageBase64: base64Image,
      );

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        final role = result['role'] ?? 'User';
        _showMsg('Nhận diện khuôn mặt thành công! Xin chào ${result['user']?.fullName ?? studentCode}', isError: false);
        _navigateByRole(role);
      } else {
        _showMsg(result['message'] ?? 'Xác thực khuôn mặt thất bại', isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showMsg('Lỗi khi chụp ảnh: $e', isError: true);
    }
  }

  void _navigateByRole(String role) {
    Widget destination;
    if (role == 'Admin') {
      destination = const AdminDashboardScreen();
    } else if (role == 'Staff') {
      destination = const StaffDashboardScreen();
    } else {
      destination = const StudentHomeScreen();
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  void _showMsg(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text('Đăng nhập bằng khuôn mặt', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ô nhập MSSV
              TextField(
                controller: _studentCodeController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Nhập MSSV hoặc Tên đăng nhập',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.school, color: Color(0xFF38BDF8)),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),

              // Camera Preview Frame
              Center(
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF38BDF8), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF38BDF8).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _isCameraReady && _cameraController != null
                        ? AspectRatio(
                            aspectRatio: _cameraController!.value.aspectRatio,
                            child: CameraPreview(_cameraController!),
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.face, size: 80, color: Color(0xFF94A3B8)),
                                SizedBox(height: 8),
                                Text(
                                  'Hướng khuôn mặt vào đây',
                                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Giữ khuôn mặt rõ ràng, đủ ánh sáng trong khung tròn',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              const SizedBox(height: 32),

              // Nút Quét & Đăng nhập
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _captureAndLogin,
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'QUÉT & ĐĂNG NHẬP NGAY',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
