import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/classroom_model.dart';
import '../../services/classroom_service.dart';
import '../settings_sheet.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<ClassroomModel> _classrooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClassrooms();
  }

  Future<void> _loadClassrooms() async {
    setState(() => _isLoading = true);
    final list = await ClassroomService.getClassrooms();
    setState(() {
      _classrooms = list;
      _isLoading = false;
    });
  }

  // Dialog Thêm / Sửa Lớp học (Cấu hình vị trí GPS linh hoạt bất kỳ đâu)
  Future<void> _showClassroomDialog([ClassroomModel? classroom]) async {
    final isEditing = classroom != null;
    final codeCtrl = TextEditingController(text: classroom?.code ?? '');
    final nameCtrl = TextEditingController(text: classroom?.name ?? '');
    final roomCtrl = TextEditingController(text: classroom?.room ?? '');
    final lecturerCtrl = TextEditingController(text: classroom?.lecturerName ?? '');
    final latCtrl = TextEditingController(text: classroom?.latitude.toString() ?? '10.762622');
    final lonCtrl = TextEditingController(text: classroom?.longitude.toString() ?? '106.660172');
    final radiusCtrl = TextEditingController(text: classroom?.radiusMeters.toString() ?? '100.0');
    final timeCtrl = TextEditingController(text: classroom?.scheduleTime ?? '');
    bool isFetchingGps = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEditing ? 'Cập nhật Lớp học & Vị trí' : 'Thêm Lớp học & Vị trí mới',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: codeCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Mã lớp (VD: LTDD_01)', labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                ),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Tên môn học (VD: Lập trình di động)', labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                ),
                TextField(
                  controller: roomCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Phòng học / Địa điểm (VD: A3-402, Nhà E1)', labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                ),
                TextField(
                  controller: lecturerCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Giảng viên phụ trách', labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                ),
                const SizedBox(height: 14),

                // KHỐI CẤU HÌNH TỌA ĐỘ GPS
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TỌA ĐỘ GPS PHÒNG HỌC',
                            style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            onPressed: isFetchingGps
                                ? null
                                : () async {
                                    setDialogState(() => isFetchingGps = true);
                                    try {
                                      var perm = await Geolocator.checkPermission();
                                      if (perm == LocationPermission.denied) {
                                        perm = await Geolocator.requestPermission();
                                      }
                                      final pos = await Geolocator.getCurrentPosition(
                                        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
                                      );
                                      setDialogState(() {
                                        latCtrl.text = pos.latitude.toStringAsFixed(6);
                                        lonCtrl.text = pos.longitude.toStringAsFixed(6);
                                        isFetchingGps = false;
                                      });
                                    } catch (_) {
                                      setDialogState(() => isFetchingGps = false);
                                    }
                                  },
                            icon: isFetchingGps
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.my_location, size: 16, color: Color(0xFF38BDF8)),
                            label: const Text('Lấy GPS hiện tại', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: latCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: const InputDecoration(labelText: 'Vĩ độ (Lat)', labelStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: lonCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: const InputDecoration(labelText: 'Kinh độ (Lon)', labelStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Địa điểm gợi ý
                      const Text('Chọn vị trí mẫu:', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          ActionChip(
                            label: const Text('Khu E Q.9', style: TextStyle(fontSize: 10)),
                            onPressed: () {
                              setDialogState(() {
                                latCtrl.text = '10.855210';
                                lonCtrl.text = '106.785310';
                              });
                            },
                          ),
                          ActionChip(
                            label: const Text('Ung Văn Khiêm', style: TextStyle(fontSize: 10)),
                            onPressed: () {
                              setDialogState(() {
                                latCtrl.text = '10.801820';
                                lonCtrl.text = '106.711510';
                              });
                            },
                          ),
                          ActionChip(
                            label: const Text('Điện Biên Phủ', style: TextStyle(fontSize: 10)),
                            onPressed: () {
                              setDialogState(() {
                                latCtrl.text = '10.800020';
                                lonCtrl.text = '106.714020';
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Bán kính cho phép điểm danh
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: radiusCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Bán kính check-in (mét)', labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Wrap(
                      spacing: 4,
                      children: [
                        ActionChip(
                          label: const Text('50m', style: TextStyle(fontSize: 10)),
                          onPressed: () => setDialogState(() => radiusCtrl.text = '50'),
                        ),
                        ActionChip(
                          label: const Text('200m', style: TextStyle(fontSize: 10)),
                          onPressed: () => setDialogState(() => radiusCtrl.text = '200'),
                        ),
                        ActionChip(
                          label: const Text('500m', style: TextStyle(fontSize: 10)),
                          onPressed: () => setDialogState(() => radiusCtrl.text = '500'),
                        ),
                      ],
                    ),
                  ],
                ),
                TextField(
                  controller: timeCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Lịch học (VD: Thứ 4, Tiết 1-4)', labelStyle: TextStyle(color: Color(0xFF94A3B8))),
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
              onPressed: () async {
                if (codeCtrl.text.isEmpty || nameCtrl.text.isEmpty) return;

                final item = ClassroomModel(
                  id: isEditing ? classroom.id : 0,
                  code: codeCtrl.text.trim(),
                  name: nameCtrl.text.trim(),
                  room: roomCtrl.text.trim(),
                  lecturerName: lecturerCtrl.text.trim(),
                  latitude: double.tryParse(latCtrl.text) ?? 10.762622,
                  longitude: double.tryParse(lonCtrl.text) ?? 106.660172,
                  radiusMeters: double.tryParse(radiusCtrl.text) ?? 100.0,
                  scheduleTime: timeCtrl.text.trim(),
                );

                Navigator.pop(ctx);
                bool ok;
                if (isEditing) {
                  ok = await ClassroomService.updateClassroom(item);
                } else {
                  ok = await ClassroomService.addClassroom(item);
                }

                if (ok) {
                  _loadClassrooms();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEditing ? 'Cập nhật thành công!' : 'Thêm lớp học thành công!'), backgroundColor: Colors.green),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
              child: Text(isEditing ? 'Lưu' : 'Thêm', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // Xóa lớp học
  Future<void> _handleDelete(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
        content: Text('Bạn có chắc chắn muốn xóa lớp học "$name" không?', style: const TextStyle(color: Color(0xFF94A3B8))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await ClassroomService.deleteClassroom(id);
      if (ok) {
        _loadClassrooms();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa lớp học thành công!'), backgroundColor: Colors.green),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text('Admin Dashboard', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadClassrooms,
            tooltip: 'Làm mới',
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF818CF8)),
            onPressed: () => SettingsSheet.show(context),
            tooltip: 'Cài đặt & Face ID',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showClassroomDialog(),
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm Lớp học', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : _classrooms.isEmpty
              ? const Center(
                  child: Text('Chưa có lớp học nào. Hãy thêm lớp học mới!', style: TextStyle(color: Color(0xFF94A3B8))),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _classrooms.length,
                  itemBuilder: (context, index) {
                    final item = _classrooms[index];
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
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item.code,
                                    style: const TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.amberAccent, size: 20),
                                      onPressed: () => _showClassroomDialog(item),
                                      tooltip: 'Sửa',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                      onPressed: () => _handleDelete(item.id, item.name),
                                      tooltip: 'Xóa',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.name,
                              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.meeting_room, size: 16, color: Color(0xFF94A3B8)),
                                const SizedBox(width: 4),
                                Text(item.room, style: const TextStyle(color: Color(0xFF94A3B8))),
                                const SizedBox(width: 16),
                                const Icon(Icons.person, size: 16, color: Color(0xFF94A3B8)),
                                const SizedBox(width: 4),
                                Text(item.lecturerName, style: const TextStyle(color: Color(0xFF94A3B8))),
                              ],
                            ),
                            const Divider(color: Color(0xFF334155), height: 20),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Colors.greenAccent),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'GPS: (${item.latitude.toStringAsFixed(4)}, ${item.longitude.toStringAsFixed(4)}) | Bán kính: ${item.radiusMeters}m',
                                    style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
