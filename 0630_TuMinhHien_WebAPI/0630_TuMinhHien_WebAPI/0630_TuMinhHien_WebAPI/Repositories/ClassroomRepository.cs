using _0630_TuMinhHien_WebAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace _0630_TuMinhHien_WebAPI.Repositories
{
    public class ClassroomRepository : IClassroomRepository
    {
        private readonly ApplicationDbContext _context;

        public ClassroomRepository(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<Classroom>> GetClassroomsAsync()
        {
            return await _context.Classrooms.ToListAsync();
        }

        public async Task<Classroom?> GetClassroomByIdAsync(int id)
        {
            return await _context.Classrooms.Include(c => c.AttendanceRecords).FirstOrDefaultAsync(c => c.Id == id);
        }

        public async Task<Classroom> AddClassroomAsync(Classroom classroom)
        {
            _context.Classrooms.Add(classroom);
            await _context.SaveChangesAsync();
            return classroom;
        }

        public async Task UpdateClassroomAsync(Classroom classroom)
        {
            _context.Entry(classroom).State = EntityState.Modified;
            await _context.SaveChangesAsync();
        }

        public async Task DeleteClassroomAsync(int id)
        {
            var classroom = await _context.Classrooms.FindAsync(id);
            if (classroom != null)
            {
                _context.Classrooms.Remove(classroom);
                await _context.SaveChangesAsync();
            }
        }
    }
}
