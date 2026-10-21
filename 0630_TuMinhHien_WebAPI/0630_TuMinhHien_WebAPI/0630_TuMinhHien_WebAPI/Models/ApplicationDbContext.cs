using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace _0630_TuMinhHien_WebAPI.Models
{
    public class ApplicationDbContext : IdentityDbContext<User>
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options) { }

        // Bảng Lớp học & Điểm danh cho đề tài Điểm danh sinh viên
        public DbSet<Classroom> Classrooms { get; set; }
        public DbSet<AttendanceRecord> AttendanceRecords { get; set; }

        // Bảng Sản phẩm & Danh mục (bài tập tuần 7)
        public DbSet<Product> Products { get; set; }
        public DbSet<Category> Categories { get; set; }

        protected override void OnModelCreating(ModelBuilder builder)
        {
            base.OnModelCreating(builder);

            // Cấu hình thuộc tính cho User
            builder.Entity<User>().Property(u => u.Initials).HasMaxLength(5);

            // Cấu hình schema mặc định theo yêu cầu bài học
            builder.HasDefaultSchema("identity");

            // Cấu hình kiểu dữ liệu cho Price
            builder.Entity<Product>().Property(p => p.Price).HasColumnType("decimal(18,2)");

            // Quan hệ 1-N giữa Category và Product
            builder.Entity<Product>()
                .HasOne(p => p.Category)
                .WithMany(c => c.Products)
                .HasForeignKey(p => p.CategoryId)
                .OnDelete(DeleteBehavior.SetNull);

            // Quan hệ giữa Classroom và AttendanceRecord
            builder.Entity<AttendanceRecord>()
                .HasOne(a => a.Classroom)
                .WithMany(c => c.AttendanceRecords)
                .HasForeignKey(a => a.ClassroomId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
