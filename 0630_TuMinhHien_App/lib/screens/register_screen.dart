import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _studentCodeController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRole = 'Student'; // "Student", "Staff", "Admin"
  bool _isLoading = false;
  bool _isSendingOtp = false;
  bool _obscurePassword = true;
  String? _otpHint;

  @override
  void dispose() {
    _fullNameController.dispose();
    _studentCodeController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 1. Gửi mã OTP xác nhận Email
  Future<void> _handleSendRegisterOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnackBar('Vui lòng nhập Email hợp lệ trước khi gửi mã OTP', isError: true);
      return;
    }

    setState(() => _isSendingOtp = true);
    final result = await AuthService.sendRegisterOtp(email);
    setState(() => _isSendingOtp = false);

    if (result['success'] == true) {
      final otp = result['otp']?.toString() ?? '';
      setState(() {
        _otpHint = otp;
        _otpController.text = otp; // Hỗ trợ demo tự động điền
      });
      _showSnackBar('Mã OTP xác thực email: $otp (Đã tự động điền)', isError: false);
    } else {
      _showSnackBar(result['message'] ?? 'Không thể gửi mã OTP', isError: true);
    }
  }

  // 2. Tạo tài khoản (Bắt buộc phải có mã OTP xác nhận)
  Future<void> _handleRegister() async {
    final fullName = _fullNameController.text.trim();
    final studentCode = _studentCodeController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar('Vui lòng điền đầy đủ Tên đăng nhập, Email và Mật khẩu', isError: true);
      return;
    }

    if (otp.isEmpty) {
      _showSnackBar('Vui lòng bấm "Gửi mã OTP" và nhập mã xác thực email', isError: true);
      return;
    }

    if (password.length < 6) {
      _showSnackBar('Mật khẩu phải từ 6 ký tự trở lên', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService.register(
      username: username,
      email: email,
      password: password,
      fullName: fullName.isEmpty ? null : fullName,
      studentCode: studentCode.isEmpty ? null : studentCode,
      role: _selectedRole,
      otp: otp,
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Đăng ký tài khoản thành công! Hãy đăng nhập.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      _showSnackBar(result['message'] ?? 'Đăng ký thất bại', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
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
        title: Text('Đăng ký tài khoản', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tạo tài khoản mới',
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 6),
              const Text(
                'Nhập email, nhận mã OTP xác thực và kích hoạt tài khoản',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
              const SizedBox(height: 24),

              // Họ và tên
              TextField(
                controller: _fullNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Họ và tên (VD: Từ Minh Hiển)',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF818CF8)),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),

              // MSSV
              TextField(
                controller: _studentCodeController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Mã số sinh viên / Mã cán bộ (VD: 20260630)',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.numbers, color: Color(0xFF818CF8)),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),

              // Username
              TextField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Tên đăng nhập (VD: sinhvien01)',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF818CF8)),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),

              // Email + Nút Gửi OTP
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Email xác thực',
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF818CF8)),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _isSendingOtp ? null : _handleSendRegisterOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4338CA),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: _isSendingOtp
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Gửi OTP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Khung nhập OTP
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(color: Colors.white, letterSpacing: 4, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: '',
                  labelText: 'Nhập mã OTP 6 số đã gửi về Email',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8), letterSpacing: 0),
                  prefixIcon: const Icon(Icons.security, color: Color(0xFF38BDF8)),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              if (_otpHint != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Mã OTP của bạn: $_otpHint',
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                ),
              ],
              const SizedBox(height: 14),

              // Mật khẩu
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Mật khẩu (ít nhất 6 ký tự)',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF818CF8)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF94A3B8)),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),

              // Chọn Vai trò (Role)
              const Text('Vai trò tài khoản:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'Student', child: Text('Sinh viên (Student)')),
                      DropdownMenuItem(value: 'Staff', child: Text('Giảng viên (Staff)')),
                      DropdownMenuItem(value: 'Admin', child: Text('Quản trị viên (Admin)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRole = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // NÚT ĐĂNG KÝ
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
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
                          'XÁC NHẬN TẠO TÀI KHOẢN',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Quay lại Đăng nhập
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Đã có tài khoản? ', style: TextStyle(color: Color(0xFF94A3B8))),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đăng nhập', style: TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
