using System.ComponentModel.DataAnnotations;

namespace _0630_TuMinhHien_WebAPI.Models
{
    public class LoginOtpModel
    {
        [Required(ErrorMessage = "Tên đăng nhập không được để trống")]
        public string Username { get; set; } = string.Empty;

        [Required(ErrorMessage = "Mật khẩu không được để trống")]
        public string Password { get; set; } = string.Empty;

        [Required(ErrorMessage = "Mã OTP không được để trống")]
        public string Otp { get; set; } = string.Empty;
    }
}
