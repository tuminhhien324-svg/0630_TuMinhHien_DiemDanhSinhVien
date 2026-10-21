using System.ComponentModel.DataAnnotations;

namespace _0630_TuMinhHien_WebAPI.Models
{
    public class FaceLoginModel
    {
        // Có thể đăng nhập bằng Username hoặc Mã số sinh viên (StudentCode)
        public string? Username { get; set; }

        public string? StudentCode { get; set; }

        // Ảnh khuôn mặt hoặc Face Vector chụp từ camera
        [Required(ErrorMessage = "Dữ liệu khuôn mặt không được để trống")]
        public string FaceImage { get; set; } = string.Empty;
    }
}
