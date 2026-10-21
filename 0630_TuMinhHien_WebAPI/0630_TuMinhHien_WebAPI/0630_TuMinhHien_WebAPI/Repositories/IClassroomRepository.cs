using _0630_TuMinhHien_WebAPI.Models;

namespace _0630_TuMinhHien_WebAPI.Repositories
{
    public interface IClassroomRepository
    {
        Task<IEnumerable<Classroom>> GetClassroomsAsync();
        Task<Classroom?> GetClassroomByIdAsync(int id);
        Task<Classroom> AddClassroomAsync(Classroom classroom);
        Task UpdateClassroomAsync(Classroom classroom);
        Task DeleteClassroomAsync(int id);
    }
}
