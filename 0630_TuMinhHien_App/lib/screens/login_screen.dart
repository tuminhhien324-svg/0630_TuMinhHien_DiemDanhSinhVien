import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/config_url.dart';
import '../services/auth_service.dart';
import 'face_login_screen.dart';
import 'register_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'staff/staff_dashboard_screen.dart';
import 'student/student_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController(text: 'sinhvien01');
  final _passwordController = TextEditingController(text: 'StudentPass123!');
  final _otpController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isSendingOtp = false;
  bool _useOtp = false; // Mặc định tắt OTP, chỉ dùng khi người dùng chủ động bật
  bool? _isServerConnected;
  String? _serverOtpHint;

  @override
  void initState() {
    super.initState();
    _checkServer();
  }

  Future<void> _checkServer() async {
    final ok = await ConfigUrl.testConnection();
    if (mounted) {
      setState(() => _isServerConnected = ok);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // Gửi mã OTP
  Future<void> _handleSendOtp() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      _showSnackBar('Vui lòng nhập Tên đăng nhập / MSSV để nhận OTP', isError: true);
      return;
    }

    setState(() => _isSendingOtp = true);
    final result = await AuthService.sendOtp(username);
    setState(() => _isSendingOtp = false);

    if (result['success'] == true) {
      final otp = result['otp'];
      setState(() {
        _serverOtpHint = otp;
        _otpController.text = otp ?? '';
      });
      _showSnackBar('Mã OTP: $otp (Đã tự động điền)', isError: false);
    } else {
      _showSnackBar(result['message'] ?? 'Gửi OTP thất bại', isError: true);
    }
  }

  // Đăng nhập trực tiếp (KHÔNG CẦN OTP nếu không bật)
  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final otp = _otpController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar('Vui lòng nhập Tên đăng nhập và Mật khẩu', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> result;
    if (_useOtp && otp.isNotEmpty) {
      result = await AuthService.loginWithOtp(
        username: username,
        password: password,
        otp: otp,
      );
    } else {
      // Đăng nhập trực tiếp không cần mã OTP
      result = await AuthService.login(
        username: username,
        password: password,
      );
    }

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      final role = result['role'] ?? 'User';
      _navigateByRole(role);
    } else {
      _showSnackBar(result['message'] ?? 'Đăng nhập thất bại', isError: true);
      _checkServer(); // Kiểm tra lại kết nối nếu đăng nhập lỗi
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

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Hộp thoại cấu hình IP Server (khi di chuyển mạng Wi-Fi khác nhau)
  void _showServerConfigDialog() {
    final controller = TextEditingController(text: ConfigUrl.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Cấu hình IP Máy chủ API', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn nhanh IP hoặc nhập địa chỉ máy tính:',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('Wi-Fi (192.168.1.47)', style: TextStyle(fontSize: 11)),
                  onPressed: () => controller.text = 'http://192.168.1.47:5276/api/',
                ),
                ActionChip(
                  label: const Text('USB (127.0.0.1)', style: TextStyle(fontSize: 11)),
                  onPressed: () => controller.text = 'http://127.0.0.1:5276/api/',
                ),
                ActionChip(
                  label: const Text('Emulator (10.0.2.2)', style: TextStyle(fontSize: 11)),
                  onPressed: () => controller.text = 'http://10.0.2.2:5276/api/',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await ConfigUrl.setCustomUrl(controller.text);
              Navigator.pop(ctx);
              _checkServer();
              _showSnackBar('Đã cập nhật IP máy chủ: ${ConfigUrl.baseUrl}');
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            child: const Text('Lưu & Thử kết nối', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Hộp thoại Quên mật khẩu & Đặt lại bằng mã OTP
  void _showForgotPasswordDialog() {
    final identifierCtrl = TextEditingController(text: _usernameController.text.trim());
    final otpCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    bool isSendingOtp = false;
    bool isResetting = false;
    String? otpHint;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.lock_reset, color: Color(0xFF38BDF8)),
              SizedBox(width: 8),
              Text('Quên mật khẩu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Nhập Email, Tên đăng nhập hoặc MSSV để nhận mã OTP đặt lại mật khẩu:',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: identifierCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Email / MSSV / Username',
                          labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isSendingOtp
                            ? null
                            : () async {
                                final id = identifierCtrl.text.trim();
                                if (id.isEmpty) {
                                  _showSnackBar('Vui lòng nhập Email hoặc MSSV', isError: true);
                                  return;
                                }
                                setDialogState(() => isSendingOtp = true);
                                final res = await AuthService.sendForgotOtp(id);
                                setDialogState(() => isSendingOtp = false);

                                if (res['success'] == true) {
                                  final otp = res['otp']?.toString() ?? '';
                                  setDialogState(() {
                                    otpHint = otp;
                                    otpCtrl.text = otp;
                                  });
                                  _showSnackBar('Mã OTP đặt lại mật khẩu: $otp (Đã tự động điền)');
                                } else {
                                  _showSnackBar(res['message'] ?? 'Không tìm thấy tài khoản', isError: true);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4338CA),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: isSendingOtp
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Gửi OTP', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: const TextStyle(color: Colors.white, letterSpacing: 4, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    counterText: '',
                    labelText: 'Nhập mã OTP 6 số',
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8), letterSpacing: 0, fontSize: 12),
                    prefixIcon: const Icon(Icons.security, color: Color(0xFF38BDF8), size: 18),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                if (otpHint != null) ...[
                  const SizedBox(height: 4),
                  Text('Mã OTP của bạn: $otpHint', style: const TextStyle(color: Colors.greenAccent, fontSize: 11)),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu mới (ít nhất 6 ký tự)',
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF818CF8), size: 18),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: isResetting
                  ? null
                  : () async {
                      final id = identifierCtrl.text.trim();
                      final otp = otpCtrl.text.trim();
                      final newPass = newPasswordCtrl.text.trim();

                      if (id.isEmpty || otp.isEmpty || newPass.isEmpty) {
                        _showSnackBar('Vui lòng điền đầy đủ thông tin', isError: true);
                        return;
                      }

                      setDialogState(() => isResetting = true);
                      final res = await AuthService.resetPasswordOtp(
                        identifier: id,
                        otp: otp,
                        newPassword: newPass,
                      );
                      setDialogState(() => isResetting = false);

                      if (res['success'] == true) {
                        Navigator.pop(ctx);
                        setState(() {
                          _usernameController.text = id;
                          _passwordController.text = newPass;
                        });
                        _showSnackBar('🎉 Đặt lại mật khẩu thành công! Hãy bấm Đăng nhập.');
                      } else {
                        _showSnackBar(res['message'] ?? 'Đặt lại mật khẩu thất bại', isError: true);
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
              child: isResetting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('ĐẶT LẠI MẬT KHẨU', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Bar: Trạng thái Server
                GestureDetector(
                  onTap: _showServerConfigDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isServerConnected == true
                            ? Colors.greenAccent.withOpacity(0.4)
                            : (_isServerConnected == false ? Colors.redAccent.withOpacity(0.4) : Colors.grey.withOpacity(0.3)),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 10,
                          color: _isServerConnected == true
                              ? Colors.greenAccent
                              : (_isServerConnected == false ? Colors.redAccent : Colors.amber),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _isServerConnected == true
                                ? 'Máy chủ: Đang kết nối (${ConfigUrl.baseUrl})'
                                : (_isServerConnected == false
                                    ? 'Mất kết nối máy chủ! Bấm để đổi IP'
                                    : 'Đang kiểm tra kết nối máy chủ...'),
                            style: TextStyle(
                              fontSize: 11,
                              color: _isServerConnected == true
                                  ? Colors.greenAccent
                                  : (_isServerConnected == false ? Colors.redAccent : Colors.amber),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.settings, size: 14, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Header Icon & Title
                const Icon(
                  Icons.how_to_reg_rounded,
                  size: 64,
                  color: Color(0xFF6366F1),
                ),
                const SizedBox(height: 12),
                Text(
                  'ĐIỂM DANH SINH VIÊN',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Hệ thống điểm danh GPS & Nhận diện khuôn mặt',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 24),

                // Card Đăng nhập Form
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF334155)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Username / MSSV
                      TextField(
                        controller: _usernameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Tên đăng nhập, Email hoặc MSSV',
                          labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF818CF8)),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu',
                          labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF818CF8)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: const Color(0xFF94A3B8),
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Tùy chọn xác thực OTP & Quên mật khẩu
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () => setState(() => _useOtp = !_useOtp),
                            icon: Icon(
                              _useOtp ? Icons.check_box : Icons.check_box_outline_blank,
                              size: 18,
                              color: const Color(0xFF818CF8),
                            ),
                            label: const Text(
                              'Xác thực OTP',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            ),
                          ),
                          TextButton(
                            onPressed: _showForgotPasswordDialog,
                            child: const Text(
                              'Quên mật khẩu?',
                              style: TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Khung nhập OTP (chỉ hiện khi người dùng tích chọn)
                      if (_useOtp) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                style: const TextStyle(color: Colors.white, letterSpacing: 4, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  counterText: '',
                                  labelText: 'Mã OTP đăng nhập 6 số',
                                  labelStyle: const TextStyle(color: Color(0xFF94A3B8), letterSpacing: 0, fontSize: 12),
                                  prefixIcon: const Icon(Icons.security, color: Color(0xFF818CF8)),
                                  filled: true,
                                  fillColor: const Color(0xFF0F172A),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isSendingOtp ? null : _handleSendOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4338CA),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                                child: _isSendingOtp
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text('Gửi OTP', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        if (_serverOtpHint != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Mã OTP gợi ý: $_serverOtpHint',
                            style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                          ),
                        ],
                      ],
                      const SizedBox(height: 20),

                      // NÚT ĐĂNG NHẬP CHÍNH (Bấm là vào ngay không cần OTP)
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : Text(
                                  'ĐĂNG NHẬP',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // NÚT ĐĂNG NHẬP BẰNG KHUÔN MẶT (FACE LOGIN)
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FaceLoginScreen(
                          studentCode: _usernameController.text.trim(),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.face_retouching_natural, color: Color(0xFF38BDF8), size: 24),
                  label: Text(
                    'ĐĂNG NHẬP BẰNG KHUÔN MẶT',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF38BDF8),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // Link chuyển sang Đăng ký
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Chưa có tài khoản? ', style: TextStyle(color: Color(0xFF94A3B8))),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: const Text(
                        'Đăng ký ngay',
                        style: TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
