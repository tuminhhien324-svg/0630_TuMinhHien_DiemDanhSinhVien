import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/attendance_model.dart';
import '../../services/attendance_service.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  List<AttendanceModel> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final list = await AttendanceService.getMyHistory();
    setState(() {
      _history = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text('Lịch sử điểm danh', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadHistory),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : _history.isEmpty
              ? const Center(
                  child: Text('Bạn chưa có lượt điểm danh nào.', style: TextStyle(color: Color(0xFF94A3B8))),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    final isPresent = item.status == 'Có mặt';
                    final timeStr = DateFormat('HH:mm - dd/MM/yyyy').format(item.checkInTime);

                    return Card(
                      color: const Color(0xFF1E293B),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.classroomName ?? 'Lớp học #${item.classroomId}',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isPresent ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item.status,
                                    style: TextStyle(
                                      color: isPresent ? Colors.greenAccent : Colors.orangeAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Thời gian: $timeStr', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                            const SizedBox(height: 4),
                            Text('Khoảng cách GPS đến lớp: ${item.distanceMeters}m',
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                            if (item.note != null && item.note!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('Ghi chú: ${item.note}',
                                  style: const TextStyle(color: Color(0xFF818CF8), fontSize: 12)),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
