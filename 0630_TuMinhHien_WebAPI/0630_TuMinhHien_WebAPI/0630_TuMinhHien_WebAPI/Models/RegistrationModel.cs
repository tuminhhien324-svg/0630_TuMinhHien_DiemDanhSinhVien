using System.ComponentModel.DataAnnotations;

namespace _0630_TuMinhHien_WebAPI.Models
{
    public class RegistrationModel
    {
        [Required(ErrorMessage = "Tên đăng nhập không được để trống")]
        public string Username { get; set; } = string.Empty;

        [Required(ErrorMessage = "Email không được để trống"), EmailAddress(ErrorMessage = "Email không hợp lệ")]
        public string Email { get; set; } = string.Empty;

        [Required(ErrorMessage = "Mật khẩu không được để trống"), MinLength(6, ErrorMessage = "Mật khẩu phải từ 6 ký tự")]
        public string Password { get; set; } = string.Empty;

        public string? FullName { get; set; }

        public string? StudentCode { get; set; } // Mã số sinh viên (MSSV)

        public string? Initials { get; set; }

        public string? Role { get; set; } // "Admin", "Staff" (Giảng viên), "Student" hoặc "User" (Sinh viên)

        // Mã OTP xác nhận email khi đăng ký
        public string? Otp { get; set; }
    }
}
