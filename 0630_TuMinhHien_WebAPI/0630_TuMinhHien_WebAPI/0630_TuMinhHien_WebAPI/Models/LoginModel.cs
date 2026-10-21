using System.ComponentModel.DataAnnotations;

namespace _0630_TuMinhHien_WebAPI.Models
{
    public class LoginModel
    {
        [Required(ErrorMessage = "Tên đăng nhập không được để trống")]
        public string Username { get; set; } = string.Empty;

        [Required(ErrorMessage = "Mật khẩu không được để trống")]
        public string Password { get; set; } = string.Empty;

        // Mã OTP xác thực (tùy chọn trong login thường, bắt buộc trong login-otp)
        public string? Otp { get; set; }
    }
}
