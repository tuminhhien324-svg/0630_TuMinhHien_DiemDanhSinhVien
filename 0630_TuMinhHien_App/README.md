# ỨNG DỤNG ĐIỂM DANH SINH VIÊN - FLUTTER MOBILE APP

* **Sinh viên:** Từ Minh Hiển (MSSV: 20260630)
* **Môn học:** Lập trình di động (LTDD) - Thầy Hùng
* **Dự án App:** `0630_TuMinhHien_App`
* **Dự án Web API:** `0630_TuMinhHien_WebAPI` (Cổng `5276`)

> File tài liệu và báo cáo tính năng đầy đủ: xem tại [HUONG_DAN_VA_TINH_NANG_HE_THONG.md](../HUONG_DAN_VA_TINH_NANG_HE_THONG.md)

---

## 1. TÀI KHOẢN ĐĂNG NHẬP KIỂM THỬ

| Vai trò | Tài khoản | Mật khẩu |
| :--- | :--- | :--- |
| **Admin (Quản trị viên)** | `admin01` | `AdminPassword123!` |
| **Staff (Giảng viên)** | `staff01` | `StaffPassword123!` |
| **Sinh viên (Student)** | `sinhvien01` (hoặc MSSV `20260630`) | `StudentPass123!` |

---

## 2. CÁC TÍNH NĂNG CHÍNH ĐÃ HOÀN THIỆN

1. **Xác thực bảo mật OTP qua Email:**
   - Đăng ký tài khoản bắt buộc mã OTP 6 số gửi về email xác nhận.
   - Quên mật khẩu xác thực bằng mã OTP theo Email/MSSV.
2. **Đăng nhập khuôn mặt (Face ID):**
   - Đăng ký Face ID trong Cài đặt (⚙️).
   - Đăng nhập 1 chạm bằng nhận diện khuôn mặt qua Camera.
3. **Phân quyền người dùng & Auto-login chuẩn:**
   - Phân biệt 3 quyền: Admin, Giảng viên, Sinh viên.
   - Tự động đăng nhập lại khi mở app và điều hướng chính xác vào đúng màn hình theo Role.
   - Đăng xuất an toàn trong nút Cài đặt.
4. **Điểm danh GPS thông minh (Geofencing Haversine):**
   - Tự động tính khoảng cách giữa sinh viên và phòng học theo mét thực tế.
   - Tự động phân loại: Có mặt (trong bán kính) hoặc Ngoài phạm vi.
   - Admin có thể tùy biến vị trí phòng học (Lấy GPS hiện tại hoặc chọn các cơ sở trường HUTECH).
5. **Giảng viên Dashboard:**
   - Xem thống kê điểm danh của từng lớp học.
   - Chỉnh sửa trạng thái (Có mặt / Đi trễ / Vắng mặt) và thêm ghi chú.
6. **Công cụ AI Fast Translator:**
   - Dịch thuật Realtime song ngữ siêu tốc (Cache Model RAM).
   - Quét chữ qua Camera (OCR) và phát âm/giọng nói.
7. **Quản lý Danh mục & Sản phẩm (Bài tập tuần 7):**
   - CRUD Sản phẩm và Danh mục cho Admin.
   - Xóa danh mục thì sản phẩm tự động về `null` (OnDelete: SetNull), không bị mất dữ liệu.
8. **Cấu hình IP máy chủ đa mạng:**
   - Nút đổi nhanh IP (Wi-Fi LAN `192.168.1.4`, Cáp USB ADB `127.0.0.1`, Emulator `10.0.2.2`).

---

## 3. CÁCH CHẠY ỨNG DỤNG
```powershell
# Chạy trên thiết bị điện thoại Android cắm cáp USB
flutter run -d R5GL3527MLF
```
