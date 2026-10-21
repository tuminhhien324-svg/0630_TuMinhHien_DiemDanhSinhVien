using _0630_TuMinhHien_WebAPI.Models;

namespace _0630_TuMinhHien_WebAPI.Repositories
{
    public interface IAttendanceRepository
    {
        Task<AttendanceRecord> CheckInAsync(AttendanceRecord record);
        Task<IEnumerable<AttendanceRecord>> GetRecordsByClassroomAsync(int classroomId);
        Task<IEnumerable<AttendanceRecord>> GetRecordsByStudentAsync(string studentId);
        Task<AttendanceRecord?> GetRecordByIdAsync(int id);
        Task UpdateStatusAsync(int recordId, string status, string? note);
        Task DeleteRecordAsync(int id);
    }
}
