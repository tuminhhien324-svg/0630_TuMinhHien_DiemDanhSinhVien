using System.ComponentModel.DataAnnotations;

namespace _0630_TuMinhHien_WebAPI.Models
{
    public class SendRegisterOtpModel
    {
        [Required(ErrorMessage = "Email không được để trống")]
        [EmailAddress(ErrorMessage = "Email không đúng định dạng")]
        public string Email { get; set; } = string.Empty;
    }

    public class ForgotPasswordOtpModel
    {
        [Required(ErrorMessage = "Email hoặc Tên đăng nhập không được để trống")]
        public string Identifier { get; set; } = string.Empty;
    }

    public class ResetPasswordOtpModel
    {
        [Required(ErrorMessage = "Email hoặc Tên đăng nhập không được để trống")]
        public string Identifier { get; set; } = string.Empty;

        [Required(ErrorMessage = "Mã OTP không được để trống")]
        public string Otp { get; set; } = string.Empty;

        [Required(ErrorMessage = "Mật khẩu mới không được để trống")]
        [MinLength(6, ErrorMessage = "Mật khẩu mới phải từ 6 ký tự")]
        public string NewPassword { get; set; } = string.Empty;
    }
}
