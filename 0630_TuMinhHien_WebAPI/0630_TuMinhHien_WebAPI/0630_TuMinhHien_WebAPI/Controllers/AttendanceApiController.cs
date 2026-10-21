using System.Security.Claims;
using _0630_TuMinhHien_WebAPI.Models;
using _0630_TuMinhHien_WebAPI.Repositories;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;

namespace _0630_TuMinhHien_WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AttendanceApiController : ControllerBase
    {
        private readonly IAttendanceRepository _attendanceRepository;
        private readonly IClassroomRepository _classroomRepository;
        private readonly UserManager<User> _userManager;

        public AttendanceApiController(
            IAttendanceRepository attendanceRepository,
            IClassroomRepository classroomRepository,
            UserManager<User> userManager)
        {
            _attendanceRepository = attendanceRepository;
            _classroomRepository = classroomRepository;
            _userManager = userManager;
        }

        /// <summary>
        /// Sinh viên bấm Điểm danh (Gửi GPS + Ảnh khuôn mặt)
        /// </summary>
        [HttpPost("check-in")]
        [Authorize]
        public async Task<IActionResult> CheckIn([FromBody] CheckInModel model)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            // Lấy thông tin sinh viên từ JWT Claims
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? string.Empty;
            var username = User.FindFirstValue(ClaimTypes.Name) ?? string.Empty;
            var user = await _userManager.FindByIdAsync(userId);

            var classroom = await _classroomRepository.GetClassroomByIdAsync(model.ClassroomId);
            if (classroom == null)
                return NotFound(new { message = "Lớp học không tồn tại" });

            // Tính khoảng cách giữa tọa độ sinh viên và phòng học theo công thức Haversine
            double distanceMeters = CalculateDistanceMeters(
                model.Latitude, model.Longitude,
                classroom.Latitude, classroom.Longitude
            );

            bool isWithinRadius = distanceMeters <= classroom.RadiusMeters;
            string status = isWithinRadius ? "Có mặt" : "Ngoài phạm vi";
            string note = isWithinRadius
                ? $"Điểm danh thành công (Cách phòng học {distanceMeters:F1}m)"
                : $"Cảnh báo: Cách phòng học {distanceMeters:F1}m (vượt quá bán kính cho phép {classroom.RadiusMeters}m)";

            var record = new AttendanceRecord
            {
                StudentId = userId,
                StudentName = user?.FullName ?? username,
                StudentCode = model.StudentCode ?? user?.StudentCode ?? user?.Initials,
                ClassroomId = model.ClassroomId,
                CheckInTime = DateTime.Now,
                Latitude = model.Latitude,
                Longitude = model.Longitude,
                DistanceMeters = Math.Round(distanceMeters, 1),
                FaceImage = model.FaceImage,
                Status = status,
                Note = note
            };

            await _attendanceRepository.CheckInAsync(record);

            return Ok(new
            {
                success = isWithinRadius,
                message = note,
                status = status,
                distanceMeters = Math.Round(distanceMeters, 1),
                allowedRadiusMeters = classroom.RadiusMeters,
                checkInTime = record.CheckInTime,
                recordId = record.Id
            });
        }

        /// <summary>
        /// Giảng viên / Admin xem danh sách điểm danh của lớp học
        /// </summary>
        [HttpGet("classroom/{classroomId}")]
        [Authorize(Roles = "Admin,Staff")]
        public async Task<IActionResult> GetClassroomAttendance(int classroomId)
        {
            try
            {
                var records = await _attendanceRepository.GetRecordsByClassroomAsync(classroomId);
                return Ok(records);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi lấy danh sách điểm danh", error = ex.Message });
            }
        }

        /// <summary>
        /// Sinh viên xem lịch sử điểm danh của bản thân
        /// </summary>
        [HttpGet("history")]
        [Authorize]
        public async Task<IActionResult> GetMyAttendanceHistory()
        {
            try
            {
                var userId = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? string.Empty;
                var records = await _attendanceRepository.GetRecordsByStudentAsync(userId);
                return Ok(records);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi lấy lịch sử điểm danh", error = ex.Message });
            }
        }

        /// <summary>
        /// Giảng viên / Admin cập nhật trạng thái điểm danh (Có mặt, Đi trễ, Vắng mặt)
        /// </summary>
        [HttpPut("{id}/status")]
        [Authorize(Roles = "Admin,Staff")]
        public async Task<IActionResult> UpdateStatus(int id, [FromBody] UpdateStatusModel model)
        {
            try
            {
                var existing = await _attendanceRepository.GetRecordByIdAsync(id);
                if (existing == null)
                    return NotFound(new { message = "Không tìm thấy bản ghi điểm danh" });

                await _attendanceRepository.UpdateStatusAsync(id, model.Status, model.Note);
                return Ok(new { message = "Cập nhật trạng thái điểm danh thành công", id, status = model.Status });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi cập nhật trạng thái", error = ex.Message });
            }
        }

        /// <summary>
        /// Giảng viên / Admin xóa bản ghi điểm danh
        /// </summary>
        [HttpDelete("{id}")]
        [Authorize(Roles = "Admin,Staff")]
        public async Task<IActionResult> DeleteRecord(int id)
        {
            try
            {
                var existing = await _attendanceRepository.GetRecordByIdAsync(id);
                if (existing == null)
                    return NotFound(new { message = "Không tìm thấy bản ghi điểm danh" });

                await _attendanceRepository.DeleteRecordAsync(id);
                return Ok(new { message = "Xóa bản ghi điểm danh thành công" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi xóa bản ghi", error = ex.Message });
            }
        }

        /// <summary>
        /// Công thức Haversine tính khoảng cách giữa 2 tọa độ GPS (trả về mét)
        /// </summary>
        private static double CalculateDistanceMeters(double lat1, double lon1, double lat2, double lon2)
        {
            const double R = 6371000; // Bán kính trái đất tính bằng mét
            double dLat = ToRadians(lat2 - lat1);
            double dLon = ToRadians(lon2 - lon1);

            double a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                       Math.Cos(ToRadians(lat1)) * Math.Cos(ToRadians(lat2)) *
                       Math.Sin(dLon / 2) * Math.Sin(dLon / 2);

            double c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
            return R * c;
        }

        private static double ToRadians(double degrees) => degrees * Math.PI / 180.0;
    }

    public class UpdateStatusModel
    {
        public string Status { get; set; } = "Có mặt"; // "Có mặt", "Đi trễ", "Vắng mặt"
        public string? Note { get; set; }
    }
}
