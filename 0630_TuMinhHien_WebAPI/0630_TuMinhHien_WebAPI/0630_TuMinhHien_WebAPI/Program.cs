using System.Text;
using _0630_TuMinhHien_WebAPI.Models;
using _0630_TuMinhHien_WebAPI.Repositories;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

// Cấu hình kết nối SQL Server
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// Cấu hình ASP.NET Core Identity
builder.Services.AddIdentity<User, IdentityRole>(options =>
{
    options.Password.RequireDigit = false;
    options.Password.RequireLowercase = false;
    options.Password.RequireUppercase = false;
    options.Password.RequireNonAlphanumeric = false;
    options.Password.RequiredLength = 6;
})
.AddEntityFrameworkStores<ApplicationDbContext>()
.AddDefaultTokenProviders();

// Đăng ký các Repository
builder.Services.AddScoped<IproductRepository, ProductRepository>();
builder.Services.AddScoped<ICategoryRepository, CategoryRepository>();
builder.Services.AddScoped<IClassroomRepository, ClassroomRepository>();
builder.Services.AddScoped<IAttendanceRepository, AttendanceRepository>();

// Cấu hình Authentication với JWT Bearer
var jwtSettings = builder.Configuration.GetSection("JWTKey");
var secretKey = jwtSettings["Secret"] ?? "TuMinhHien_0630_SuperSecretKeyForJWTSigning2026!";
var key = Encoding.UTF8.GetBytes(secretKey);

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.SaveToken = true;
    options.RequireHttpsMetadata = false;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtSettings["ValidIssuer"],
        ValidAudience = jwtSettings["ValidAudience"],
        IssuerSigningKey = new SymmetricSecurityKey(key),
        ClockSkew = TimeSpan.Zero
    };
});

builder.Services.AddAuthorization();

builder.Services.AddMemoryCache(); // Quản lý lưu trữ mã OTP trong bộ nhớ tạm
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();

// Cấu hình Swagger hỗ trợ Authorize bằng JWT Bearer
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "0630_TuMinhHien_WebAPI - App Điểm Danh Sinh Viên",
        Version = "v1",
        Description = "Hệ thống Web API Điểm danh sinh viên: Xác thực OTP, Đăng nhập khuôn mặt (Face Login), Điểm danh GPS, Phân quyền Admin - Giảng viên - Sinh viên, CRUD Lớp học"
    });

    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Nhập mã token JWT (không cần gõ chữ Bearer, hệ thống tự điền)"
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

// Cấu hình CORS cho phép Flutter mobile và Web kết nối
builder.Services.AddCors(options =>
{
    options.AddPolicy("MyAllowOrigins", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

var app = builder.Build();

// Tự động tạo bảng và dữ liệu mẫu khi ứng dụng khởi động
using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
    await dbContext.Database.MigrateAsync();

    var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole>>();
    var userManager = scope.ServiceProvider.GetRequiredService<UserManager<User>>();

    var roles = new[] { "Admin", "Staff", "User" };
    foreach (var role in roles)
    {
        if (!await roleManager.RoleExistsAsync(role))
        {
            await roleManager.CreateAsync(new IdentityRole(role));
        }
    }

    // Seed Admin
    var adminUser = await userManager.FindByNameAsync("admin01");
    if (adminUser == null)
    {
        adminUser = new User
        {
            UserName = "admin01",
            Email = "admin01@example.com",
            FullName = "Quản trị viên Hệ thống",
            Initials = "AD",
            EmailConfirmed = true
        };
        var res = await userManager.CreateAsync(adminUser, "AdminPassword123!");
        if (res.Succeeded)
        {
            await userManager.AddToRoleAsync(adminUser, "Admin");
        }
    }

    // Seed Staff
    var staffUser = await userManager.FindByNameAsync("staff01");
    if (staffUser == null)
    {
        staffUser = new User
        {
            UserName = "staff01",
            Email = "staff01@example.com",
            FullName = "Giảng viên Nguyễn Văn A",
            Initials = "GV",
            EmailConfirmed = true
        };
        var res = await userManager.CreateAsync(staffUser, "StaffPassword123!");
        if (res.Succeeded)
        {
            await userManager.AddToRoleAsync(staffUser, "Staff");
        }
    }

    // Seed Sinh viên (Từ Minh Hiển)
    var studentUser = await userManager.FindByNameAsync("sinhvien01");
    if (studentUser == null)
    {
        studentUser = new User
        {
            UserName = "sinhvien01",
            Email = "tuminhhien@student.edu.vn",
            FullName = "Từ Minh Hiển",
            StudentCode = "20260630",
            Initials = "TMH",
            EmailConfirmed = true
        };
        var res = await userManager.CreateAsync(studentUser, "StudentPass123!");
        if (res.Succeeded)
        {
            await userManager.AddToRoleAsync(studentUser, "User");
        }
    }

    // Tự động tạo sẵn lớp học mẫu nếu chưa có
    if (!dbContext.Classrooms.Any())
    {
        dbContext.Classrooms.AddRange(
            new Classroom
            {
                Code = "LTDD_01",
                Name = "Lập trình di động",
                Room = "A3-402",
                LecturerName = "Thầy Hùng",
                Latitude = 10.762622,
                Longitude = 106.660172,
                RadiusMeters = 100.0,
                ScheduleTime = "Thứ 4, Tiết 1-4"
            },
            new Classroom
            {
                Code = "CNPM_02",
                Name = "Công nghệ phần mềm",
                Room = "B1-205",
                LecturerName = "Cô Lan",
                Latitude = 10.762800,
                Longitude = 106.660300,
                RadiusMeters = 80.0,
                ScheduleTime = "Thứ 6, Tiết 5-8"
            }
        );
        await dbContext.SaveChangesAsync();
    }

    // Tự động tạo danh mục và sản phẩm mẫu (bài tập tuần 7 CRUD)
    if (!dbContext.Categories.Any())
    {
        var cat1 = new Category { Name = "Sách giáo trình" };
        var cat2 = new Category { Name = "Thiết bị học tập" };
        dbContext.Categories.AddRange(cat1, cat2);
        await dbContext.SaveChangesAsync();

        dbContext.Products.AddRange(
            new Product { Name = "Giáo trình Lập trình di động", Price = 85000, CategoryId = cat1.Id },
            new Product { Name = "Sổ tay sinh viên", Price = 25000, CategoryId = cat2.Id }
        );
        await dbContext.SaveChangesAsync();
    }
}

// Luôn bật Swagger công khai
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "0630_TuMinhHien_WebAPI v1");
    c.DocumentTitle = "0630_TuMinhHien_WebAPI - Swagger UI";
});

// Tự động chuyển hướng từ trang chủ "/" về "/swagger"
app.MapGet("/", () => Results.Redirect("/swagger"));

// app.UseHttpsRedirection();
app.UseCors("MyAllowOrigins");

// Authentication phải đứng trước Authorization
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
