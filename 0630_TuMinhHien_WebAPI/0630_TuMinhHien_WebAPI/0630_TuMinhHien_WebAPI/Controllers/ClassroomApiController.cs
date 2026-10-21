using _0630_TuMinhHien_WebAPI.Models;
using _0630_TuMinhHien_WebAPI.Repositories;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace _0630_TuMinhHien_WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ClassroomApiController : ControllerBase
    {
        private readonly IClassroomRepository _classroomRepository;

        public ClassroomApiController(IClassroomRepository classroomRepository)
        {
            _classroomRepository = classroomRepository;
        }

        // GET: api/ClassroomApi (Xem danh sách các lớp học / môn học)
        [HttpGet]
        public async Task<IActionResult> GetClassrooms()
        {
            try
            {
                var classrooms = await _classroomRepository.GetClassroomsAsync();
                return Ok(classrooms);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi lấy danh sách lớp học", error = ex.Message });
            }
        }

        // GET: api/ClassroomApi/{id}
        [HttpGet("{id}")]
        public async Task<IActionResult> GetClassroomById(int id)
        {
            try
            {
                var classroom = await _classroomRepository.GetClassroomByIdAsync(id);
                if (classroom == null)
                    return NotFound(new { message = "Không tìm thấy lớp học" });
                return Ok(classroom);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi tìm lớp học", error = ex.Message });
            }
        }

        // POST: api/ClassroomApi (Admin và Giảng viên/Staff có quyền Thêm lớp học)
        [HttpPost]
        [Authorize(Roles = "Admin,Staff")]
        public async Task<IActionResult> AddClassroom([FromBody] Classroom classroom)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            try
            {
                var created = await _classroomRepository.AddClassroomAsync(classroom);
                return CreatedAtAction(nameof(GetClassroomById), new { id = created.Id }, created);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi thêm lớp học", error = ex.Message });
            }
        }

        // PUT: api/ClassroomApi/{id} (Admin và Giảng viên/Staff có quyền Sửa lớp học)
        [HttpPut("{id}")]
        [Authorize(Roles = "Admin,Staff")]
        public async Task<IActionResult> UpdateClassroom(int id, [FromBody] Classroom classroom)
        {
            if (id != classroom.Id)
                return BadRequest(new { message = "ID lớp học không khớp" });

            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            try
            {
                var existing = await _classroomRepository.GetClassroomByIdAsync(id);
                if (existing == null)
                    return NotFound(new { message = "Không tìm thấy lớp học để cập nhật" });

                existing.Code = classroom.Code;
                existing.Name = classroom.Name;
                existing.Room = classroom.Room;
                existing.LecturerName = classroom.LecturerName;
                existing.Latitude = classroom.Latitude;
                existing.Longitude = classroom.Longitude;
                existing.RadiusMeters = classroom.RadiusMeters;
                existing.ScheduleTime = classroom.ScheduleTime;

                await _classroomRepository.UpdateClassroomAsync(existing);
                return Ok(new { message = "Cập nhật lớp học thành công", classroom = existing });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi cập nhật lớp học", error = ex.Message });
            }
        }

        // DELETE: api/ClassroomApi/{id} (Chỉ riêng Admin có quyền Xóa lớp học)
        [HttpDelete("{id}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> DeleteClassroom(int id)
        {
            try
            {
                var existing = await _classroomRepository.GetClassroomByIdAsync(id);
                if (existing == null)
                    return NotFound(new { message = "Không tìm thấy lớp học để xóa" });

                await _classroomRepository.DeleteClassroomAsync(id);
                return Ok(new { message = "Xóa lớp học thành công" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi xóa lớp học", error = ex.Message });
            }
        }
    }
}
