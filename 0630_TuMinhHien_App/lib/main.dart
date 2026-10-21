import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/config_url.dart';
import 'models/user_model.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/staff/staff_dashboard_screen.dart';
import 'screens/student/student_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Nạp cấu hình từ file .env nếu có
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {}

  // Tải IP máy chủ đã lưu (nếu có)
  await ConfigUrl.loadSavedUrl();

  // Kiểm tra phiên đăng nhập tự động
  final savedUser = await AuthService.checkAutoLogin();

  runApp(TuMinhHienAttendanceApp(initialUser: savedUser));
}

class TuMinhHienAttendanceApp extends StatelessWidget {
  final UserModel? initialUser;
  const TuMinhHienAttendanceApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    Widget homeScreen;
    if (initialUser != null) {
      if (initialUser!.role == 'Admin') {
        homeScreen = const AdminDashboardScreen();
      } else if (initialUser!.role == 'Staff') {
        homeScreen = const StaffDashboardScreen();
      } else {
        homeScreen = const StudentHomeScreen();
      }
    } else {
      homeScreen = const LoginScreen();
    }

    return MaterialApp(
      title: 'Điểm Danh Sinh Viên - Từ Minh Hiển',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF38BDF8),
          surface: Color(0xFF1E293B),
        ),
        textTheme: GoogleFonts.interTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          elevation: 0,
          centerTitle: true,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E293B),
          selectedItemColor: Color(0xFF818CF8),
          unselectedItemColor: Color(0xFF64748B),
        ),
      ),
      home: homeScreen,
    );
  }
}
