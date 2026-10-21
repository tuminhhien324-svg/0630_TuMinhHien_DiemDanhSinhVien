import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/classroom_model.dart';
import '../../services/classroom_service.dart';
import '../tools/translation_screen.dart';
import '../tools/realtime_translate_screen.dart';
import '../settings_sheet.dart';
import 'attendance_checkin_screen.dart';
import 'attendance_history_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _currentIndex = 0;
  String _studentName = 'Sinh viên';
  String _studentCode = '';

  @override
  void initState() {
    super.initState();
    _loadStudentInfo();
  }

  Future<void> _loadStudentInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _studentName = prefs.getString('full_name') ?? prefs.getString('user_name') ?? 'Sinh viên';
      _studentCode = prefs.getString('student_code') ?? '';
    });
  }


  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildClassroomListTab(),
      const AttendanceHistoryScreen(),
      const TranslationScreen(),
      const RealtimeTranslateScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Xin chào, $_studentName', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
            if (_studentCode.isNotEmpty)
              Text('MSSV: $_studentCode', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF818CF8)),
            onPressed: () => SettingsSheet.show(context, onFaceIdUpdated: _loadStudentInfo),
            tooltip: 'Cài đặt tài khoản & Face ID',
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: const Color(0xFF818CF8),
        unselectedItemColor: const Color(0xFF64748B),
        selectedFontSize: 12,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.class_outlined),
            activeIcon: Icon(Icons.class_),
            label: 'Lớp học',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            activeIcon: Icon(Icons.history_toggle_off),
            label: 'Lịch sử',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.translate),
            activeIcon: Icon(Icons.g_translate),
            label: 'Dịch thuật',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            activeIcon: Icon(Icons.camera_alt),
            label: 'Dịch Camera',
          ),
        ],
      ),
    );
  }

  Widget _buildClassroomListTab() {
    return FutureBuilder<List<ClassroomModel>>(
      future: ClassroomService.getClassrooms(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
        }

        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return const Center(
            child: Text('Hiện không có lớp học nào.', style: TextStyle(color: Color(0xFF94A3B8))),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final c = list[index];

            return Card(
              color: const Color(0xFF1E293B),
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            c.code,
                            style: const TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(c.scheduleTime, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      c.name,
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.room, size: 16, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text('Phòng: ${c.room}', style: const TextStyle(color: Color(0xFF94A3B8))),
                        const SizedBox(width: 16),
                        const Icon(Icons.person, size: 16, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text('GV: ${c.lecturerName}', style: const TextStyle(color: Color(0xFF94A3B8))),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AttendanceCheckInScreen(classroom: c),
                            ),
                          );
                        },
                        icon: const Icon(Icons.location_on, color: Colors.white),
                        label: const Text(
                          'ĐIỂM DANH GPS & KHUÔN MẶT',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
