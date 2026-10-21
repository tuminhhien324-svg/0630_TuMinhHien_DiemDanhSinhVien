import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/attendance_model.dart';
import '../../models/classroom_model.dart';
import '../../services/attendance_service.dart';
import '../../services/classroom_service.dart';
import '../settings_sheet.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  List<ClassroomModel> _classrooms = [];
  ClassroomModel? _selectedClassroom;
  List<AttendanceModel> _records = [];
  bool _isLoadingClasses = true;
  bool _isLoadingRecords = false;

  @override
  void initState() {
    super.initState();
    _loadClassrooms();
  }

  Future<void> _loadClassrooms() async {
    setState(() => _isLoadingClasses = true);
    final list = await ClassroomService.getClassrooms();
    setState(() {
      _classrooms = list;
      if (list.isNotEmpty) {
        _selectedClassroom = list.first;
      }
      _isLoadingClasses = false;
    });

    if (_selectedClassroom != null) {
      _loadRecords(_selectedClassroom!.id);
    }
  }

  Future<void> _loadRecords(int classroomId) async {
    setState(() => _isLoadingRecords = true);
    final records = await AttendanceService.getClassroomAttendance(classroomId);
    setState(() {
      _records = records;
      _isLoadingRecords = false;
    });
  }

  // Dialog Giảng viên sửa trạng thái điểm danh của sinh viên
  Future<void> _showEditStatusDialog(AttendanceModel record) async {
    String currentStatus = record.status;
    final noteCtrl = TextEditingController(text: record.note ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(
            'Sửa điểm danh: ${record.studentName}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Có mặt', style: TextStyle(color: Colors.greenAccent)),
                value: 'Có mặt',
                groupValue: currentStatus,
                activeColor: Colors.greenAccent,
                onChanged: (val) => setDialogState(() => currentStatus = val!),
              ),
              RadioListTile<String>(
                title: const Text('Đi trễ', style: TextStyle(color: Colors.amberAccent)),
                value: 'Đi trễ',
                groupValue: currentStatus,
                activeColor: Colors.amberAccent,
                onChanged: (val) => setDialogState(() => currentStatus = val!),
              ),
              RadioListTile<String>(
                title: const Text('Vắng mặt', style: TextStyle(color: Colors.redAccent)),
                value: 'Vắng mặt',
                groupValue: currentStatus,
                activeColor: Colors.redAccent,
                onChanged: (val) => setDialogState(() => currentStatus = val!),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Ghi chú của Giảng viên',
                  labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                ),
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
                Navigator.pop(ctx);
                final ok = await AttendanceService.updateStatus(record.id, currentStatus, noteCtrl.text.trim());
                if (ok && _selectedClassroom != null) {
                  _loadRecords(_selectedClassroom!.id);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
              child: const Text('Lưu', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final presentCount = _records.where((r) => r.status == 'Có mặt').length;
    final outOfRangeCount = _records.where((r) => r.status == 'Ngoài phạm vi').length;
    final lateCount = _records.where((r) => r.status == 'Đi trễ').length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text('Giảng viên Dashboard', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_selectedClassroom != null) _loadRecords(_selectedClassroom!.id);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF818CF8)),
            onPressed: () => SettingsSheet.show(context),
            tooltip: 'Cài đặt & Face ID',
          ),
        ],
      ),
      body: _isLoadingClasses
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : Column(
              children: [
                // Chọn lớp học Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: const Color(0xFF1E293B),
                  child: Row(
                    children: [
                      const Icon(Icons.school, color: Color(0xFF818CF8)),
                      const SizedBox(width: 8),
                      const Text('Lớp học: ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<ClassroomModel>(
                            value: _selectedClassroom,
                            dropdownColor: const Color(0xFF1E293B),
                            style: const TextStyle(color: Colors.white),
                            items: _classrooms.map((c) {
                              return DropdownMenuItem(
                                value: c,
                                child: Text('${c.code} - ${c.name}'),
                              );
                            }).toList(),
                            onChanged: (c) {
                              if (c != null) {
                                setState(() => _selectedClassroom = c);
                                _loadRecords(c.id);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Thống kê Cards
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildStatCard('Tổng số', '${_records.length}', Colors.blueAccent),
                      const SizedBox(width: 8),
                      _buildStatCard('Có mặt', '$presentCount', Colors.greenAccent),
                      const SizedBox(width: 8),
                      _buildStatCard('Ngoài GPS', '$outOfRangeCount', Colors.orangeAccent),
                      const SizedBox(width: 8),
                      _buildStatCard('Đi trễ', '$lateCount', Colors.amberAccent),
                    ],
                  ),
                ),

                // Danh sách sinh viên điểm danh
                Expanded(
                  child: _isLoadingRecords
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                      : _records.isEmpty
                          ? const Center(
                              child: Text('Chưa có sinh viên nào điểm danh lớp này', style: TextStyle(color: Color(0xFF94A3B8))),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _records.length,
                              itemBuilder: (context, index) {
                                final r = _records[index];
                                final isPresent = r.status == 'Có mặt';
                                final timeStr = DateFormat('HH:mm - dd/MM').format(r.checkInTime);

                                return Card(
                                  color: const Color(0xFF1E293B),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isPresent ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                                      child: Icon(
                                        isPresent ? Icons.check : Icons.warning_amber,
                                        color: isPresent ? Colors.greenAccent : Colors.orangeAccent,
                                      ),
                                    ),
                                    title: Text(
                                      r.studentName,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('MSSV: ${r.studentCode ?? "N/A"} | Lúc: $timeStr', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                                        Text('Cách phòng học: ${r.distanceMeters}m', style: TextStyle(color: isPresent ? Colors.greenAccent : Colors.orangeAccent, fontSize: 11)),
                                      ],
                                    ),
                                    trailing: TextButton.icon(
                                      onPressed: () => _showEditStatusDialog(r),
                                      icon: const Icon(Icons.edit, size: 16, color: Color(0xFF818CF8)),
                                      label: Text(
                                        r.status,
                                        style: TextStyle(
                                          color: isPresent ? Colors.greenAccent : Colors.orangeAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }
}
