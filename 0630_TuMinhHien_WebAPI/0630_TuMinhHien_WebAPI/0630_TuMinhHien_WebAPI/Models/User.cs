using Microsoft.AspNetCore.Identity;

namespace _0630_TuMinhHien_WebAPI.Models
{
    public class User : IdentityUser
    {
        public string? Initials { get; set; }

        // Họ tên đầy đủ sinh viên / giảng viên
        public string? FullName { get; set; }

        // Mã số sinh viên (MSSV)
        public string? StudentCode { get; set; }

        // Dữ liệu nhận diện khuôn mặt (chuỗi Base64 hoặc Vector khuôn mặt)
        public string? FaceData { get; set; }
    }
}
