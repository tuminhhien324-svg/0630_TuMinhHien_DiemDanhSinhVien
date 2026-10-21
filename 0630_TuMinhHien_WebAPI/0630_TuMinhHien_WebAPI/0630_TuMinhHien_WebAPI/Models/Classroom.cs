using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace _0630_TuMinhHien_WebAPI.Models
{
    public class Classroom
    {
        public int Id { get; set; }

        [Required(ErrorMessage = "Mã lớp học không được để trống")]
        public string Code { get; set; } = string.Empty; // Ví dụ: "LTDD_01"

        [Required(ErrorMessage = "Tên môn học không được để trống")]
        public string Name { get; set; } = string.Empty; // Ví dụ: "Lập trình di động"

        public string? Room { get; set; } // Ví dụ: "Phòng A3-402"

        public string? LecturerName { get; set; } // Ví dụ: "Thầy Hùng"

        // Tọa độ GPS phòng học để kiểm tra điểm danh vị trí
        public double Latitude { get; set; } = 10.762622; // Vĩ độ mặc định

        public double Longitude { get; set; } = 106.660172; // Kinh độ mặc định

        public double RadiusMeters { get; set; } = 100.0; // Bán kính cho phép check-in (mét)

        public string? ScheduleTime { get; set; } // Ví dụ: "Thứ 4, Tiết 1-4"

        [JsonIgnore]
        public ICollection<AttendanceRecord> AttendanceRecords { get; set; } = new List<AttendanceRecord>();
    }
}
