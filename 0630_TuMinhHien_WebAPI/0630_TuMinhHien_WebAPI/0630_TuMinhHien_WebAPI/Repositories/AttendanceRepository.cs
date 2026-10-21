using _0630_TuMinhHien_WebAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace _0630_TuMinhHien_WebAPI.Repositories
{
    public class AttendanceRepository : IAttendanceRepository
    {
        private readonly ApplicationDbContext _context;

        public AttendanceRepository(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<AttendanceRecord> CheckInAsync(AttendanceRecord record)
        {
            _context.AttendanceRecords.Add(record);
            await _context.SaveChangesAsync();
            return record;
        }

        public async Task<IEnumerable<AttendanceRecord>> GetRecordsByClassroomAsync(int classroomId)
        {
            return await _context.AttendanceRecords
                .Include(a => a.Classroom)
                .Where(a => a.ClassroomId == classroomId)
                .OrderByDescending(a => a.CheckInTime)
                .ToListAsync();
        }

        public async Task<IEnumerable<AttendanceRecord>> GetRecordsByStudentAsync(string studentId)
        {
            return await _context.AttendanceRecords
                .Include(a => a.Classroom)
                .Where(a => a.StudentId == studentId)
                .OrderByDescending(a => a.CheckInTime)
                .ToListAsync();
        }

        public async Task<AttendanceRecord?> GetRecordByIdAsync(int id)
        {
            return await _context.AttendanceRecords
                .Include(a => a.Classroom)
                .FirstOrDefaultAsync(a => a.Id == id);
        }

        public async Task UpdateStatusAsync(int recordId, string status, string? note)
        {
            var record = await _context.AttendanceRecords.FindAsync(recordId);
            if (record != null)
            {
                record.Status = status;
                if (!string.IsNullOrEmpty(note))
                {
                    record.Note = note;
                }
                await _context.SaveChangesAsync();
            }
        }

        public async Task DeleteRecordAsync(int id)
        {
            var record = await _context.AttendanceRecords.FindAsync(id);
            if (record != null)
            {
                _context.AttendanceRecords.Remove(record);
                await _context.SaveChangesAsync();
            }
        }
    }
}
