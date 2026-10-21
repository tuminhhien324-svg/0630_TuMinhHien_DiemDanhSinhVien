using System.ComponentModel.DataAnnotations;

namespace _0630_TuMinhHien_WebAPI.Models
{
    public class AttendanceRecord
    {
        public int Id { get; set; }

        public string StudentId { get; set; } = string.Empty; // Id của User

        public string? StudentName { get; set; } // Tên sinh viên

        public string? StudentCode { get; set; } // MSSV sinh viên

        public int ClassroomId { get; set; } // Id lớp học

        public Classroom? Classroom { get; set; }

        public DateTime CheckInTime { get; set; } = DateTime.Now;

        // Vị trí GPS lúc sinh viên bấm điểm danh
        public double Latitude { get; set; }

        public double Longitude { get; set; }

        // Khoảng cách thực tế từ sinh viên đến phòng học (mét)
        public double DistanceMeters { get; set; }

        // Ảnh chụp khuôn mặt lúc điểm danh (chuỗi Base64 hoặc URL ảnh)
        public string? FaceImage { get; set; }

        // Trạng thái: "Có mặt", "Đi trễ", "Vắng mặt", "Chờ duyệt"
        public string Status { get; set; } = "Có mặt";

        // Ghi chú (ví dụ: "Check-in GPS hợp lệ", "Ngoài bán kính cho phép")
        public string? Note { get; set; }
    }
}
