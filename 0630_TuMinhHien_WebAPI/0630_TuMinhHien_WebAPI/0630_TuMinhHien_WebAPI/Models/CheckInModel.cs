using System.ComponentModel.DataAnnotations;

namespace _0630_TuMinhHien_WebAPI.Models
{
    public class CheckInModel
    {
        [Required(ErrorMessage = "ClassroomId không được để trống")]
        public int ClassroomId { get; set; }

        // Tọa độ GPS sinh viên gửi lên từ điện thoại
        [Required(ErrorMessage = "Vĩ độ Latitude không được để trống")]
        public double Latitude { get; set; }

        [Required(ErrorMessage = "Kinh độ Longitude không được để trống")]
        public double Longitude { get; set; }

        // Ảnh khuôn mặt chụp từ camera lúc điểm danh
        public string? FaceImage { get; set; }

        public string? StudentCode { get; set; }

        public string? Note { get; set; }
    }
}
