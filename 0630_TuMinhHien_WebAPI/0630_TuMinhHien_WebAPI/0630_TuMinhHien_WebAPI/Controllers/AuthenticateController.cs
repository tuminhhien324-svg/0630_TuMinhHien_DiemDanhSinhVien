using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using _0630_TuMinhHien_WebAPI.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.IdentityModel.Tokens;

namespace _0630_TuMinhHien_WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthenticateController : ControllerBase
    {
        private readonly UserManager<User> _userManager;
        private readonly RoleManager<IdentityRole> _roleManager;
        private readonly IConfiguration _configuration;
        private readonly IMemoryCache _memoryCache;

        public AuthenticateController(
            UserManager<User> userManager,
            RoleManager<IdentityRole> roleManager,
            IConfiguration configuration,
            IMemoryCache memoryCache)
        {
            _userManager = userManager;
            _roleManager = roleManager;
            _configuration = configuration;
            _memoryCache = memoryCache;
        }

        /// <summary>
        /// 1.1 Gửi mã OTP xác nhận Email khi Đăng ký tài khoản
        /// </summary>
        [HttpPost("send-register-otp")]
        public async Task<IActionResult> SendRegisterOtp([FromBody] SendRegisterOtpModel model)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var email = model.Email.Trim().ToLower();
            var emailExists = await _userManager.FindByEmailAsync(email);
            if (emailExists != null)
                return BadRequest(new { Status = false, Message = "Email này đã được sử dụng bởi tài khoản khác" });

            var otpCode = Random.Shared.Next(100000, 999999).ToString();
            var cacheKey = $"REG_OTP_{email}";
            _memoryCache.Set(cacheKey, otpCode, TimeSpan.FromMinutes(10));

            return Ok(new
            {
                Status = true,
                Message = "Mã xác nhận OTP đã được gửi đến email (hiệu lực 10 phút)",
                Otp = otpCode,
                Email = email
            });
        }

        /// <summary>
        /// 1.2 Đăng ký tài khoản qua Email (Yêu cầu xác thực mã OTP gửi về Email)
        /// </summary>
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegistrationModel model)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var email = model.Email.Trim().ToLower();

            // Xác thực mã OTP nếu có gửi mã OTP
            if (!string.IsNullOrWhiteSpace(model.Otp))
            {
                var cacheKey = $"REG_OTP_{email}";
                if (!_memoryCache.TryGetValue(cacheKey, out string? cachedOtp) || cachedOtp != model.Otp.Trim())
                {
                    return BadRequest(new { Status = false, Message = "Mã OTP xác thực email không chính xác hoặc đã hết hạn" });
                }
                _memoryCache.Remove(cacheKey);
            }

            var userExists = await _userManager.FindByNameAsync(model.Username);
            if (userExists != null)
                return StatusCode(StatusCodes.Status400BadRequest, new { Status = false, Message = "Tên đăng nhập đã tồn tại" });

            var emailExists = await _userManager.FindByEmailAsync(email);
            if (emailExists != null)
                return StatusCode(StatusCodes.Status400BadRequest, new { Status = false, Message = "Email đã được sử dụng" });

            var user = new User
            {
                UserName = model.Username,
                Email = email,
                FullName = model.FullName,
                StudentCode = model.StudentCode,
                EmailConfirmed = true,
                Initials = model.Initials ?? (string.IsNullOrEmpty(model.FullName) ? null : model.FullName.Substring(0, Math.Min(5, model.FullName.Length)))
            };

            var result = await _userManager.CreateAsync(user, model.Password);
            if (!result.Succeeded)
            {
                var errors = string.Join("; ", result.Errors.Select(e => e.Description));
                return StatusCode(StatusCodes.Status500InternalServerError, new { Status = false, Message = $"Đăng ký thất bại: {errors}" });
            }

            // Gán Role: Hỗ trợ "Admin", "Staff", "Student" hoặc "User"
            var targetRole = string.IsNullOrWhiteSpace(model.Role) ? "User" : model.Role.Trim();
            if (targetRole.Equals("Student", StringComparison.OrdinalIgnoreCase))
            {
                targetRole = "User"; // Đồng bộ Student vào nhóm User
            }

            if (!await _roleManager.RoleExistsAsync(targetRole))
            {
                await _roleManager.CreateAsync(new IdentityRole(targetRole));
            }
            await _userManager.AddToRoleAsync(user, targetRole);

            return Ok(new
            {
                Status = true,
                Message = "Đăng ký tài khoản thành công qua email và OTP",
                Username = user.UserName,
                Email = user.Email,
                FullName = user.FullName,
                StudentCode = user.StudentCode,
                Role = targetRole
            });
        }

        /// <summary>
        /// 1.3 Gửi mã OTP Quên mật khẩu
        /// </summary>
        [HttpPost("send-forgot-otp")]
        public async Task<IActionResult> SendForgotOtp([FromBody] ForgotPasswordOtpModel model)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var user = await FindUserByIdentifierAsync(model.Identifier);
            if (user == null)
            {
                return NotFound(new { Status = false, Message = "Không tìm thấy tài khoản với thông tin này" });
            }

            var otpCode = Random.Shared.Next(100000, 999999).ToString();
            var cacheKey = $"FORGOT_OTP_{user.UserName.ToLower()}";
            _memoryCache.Set(cacheKey, otpCode, TimeSpan.FromMinutes(10));

            return Ok(new
            {
                Status = true,
                Message = "Mã OTP đặt lại mật khẩu đã được tạo thành công (hiệu lực 10 phút)",
                Otp = otpCode,
                Username = user.UserName,
                Email = user.Email
            });
        }

        /// <summary>
        /// 1.4 Đặt lại mật khẩu bằng mã OTP
        /// </summary>
        [HttpPost("reset-password-otp")]
        public async Task<IActionResult> ResetPasswordOtp([FromBody] ResetPasswordOtpModel model)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var user = await FindUserByIdentifierAsync(model.Identifier);
            if (user == null)
            {
                return NotFound(new { Status = false, Message = "Không tìm thấy tài khoản để đặt lại mật khẩu" });
            }

            var cacheKey = $"FORGOT_OTP_{user.UserName.ToLower()}";
            if (!_memoryCache.TryGetValue(cacheKey, out string? cachedOtp) || cachedOtp != model.Otp.Trim())
            {
                return BadRequest(new { Status = false, Message = "Mã OTP đặt lại mật khẩu không chính xác hoặc đã hết hạn" });
            }

            _memoryCache.Remove(cacheKey);

            // Xóa mật khẩu cũ và đặt mật khẩu mới
            var token = await _userManager.GeneratePasswordResetTokenAsync(user);
            var result = await _userManager.ResetPasswordAsync(user, token, model.NewPassword);
            if (!result.Succeeded)
            {
                var remove = await _userManager.RemovePasswordAsync(user);
                var add = await _userManager.AddPasswordAsync(user, model.NewPassword);
                if (!add.Succeeded)
                {
                    var errors = string.Join("; ", add.Errors.Select(e => e.Description));
                    return BadRequest(new { Status = false, Message = $"Đặt lại mật khẩu thất bại: {errors}" });
                }
            }

            return Ok(new
            {
                Status = true,
                Message = "Đặt lại mật khẩu thành công! Bạn có thể dùng mật khẩu mới để đăng nhập ngay bây giờ.",
                Username = user.UserName
            });
        }

        /// <summary>
        /// Tìm kiếm người dùng theo UserName, Email hoặc MSSV (StudentCode)
        /// </summary>
        private async Task<User?> FindUserByIdentifierAsync(string identifier)
        {
            if (string.IsNullOrWhiteSpace(identifier)) return null;
            var trimmed = identifier.Trim();

            // 1. Tìm theo UserName
            var user = await _userManager.FindByNameAsync(trimmed);
            if (user != null) return user;

            // 2. Tìm theo Email
            user = await _userManager.FindByEmailAsync(trimmed);
            if (user != null) return user;

            // 3. Tìm theo MSSV (StudentCode)
            user = _userManager.Users.FirstOrDefault(u => u.StudentCode == trimmed);
            return user;
        }

        /// <summary>
        /// 2. Gửi mã OTP xác thực (6 chữ số, hiệu lực 5 phút)
        /// </summary>
        [HttpPost("send-otp")]
        public async Task<IActionResult> SendOtp([FromBody] SendOtpModel model)
        {
            var identifier = !string.IsNullOrWhiteSpace(model.Username) ? model.Username : model.Email;
            var user = await FindUserByIdentifierAsync(identifier ?? string.Empty);

            if (user == null)
            {
                return NotFound(new { Status = false, Message = "Không tìm thấy người dùng với thông tin cung cấp (UserName, Email hoặc MSSV)" });
            }

            var otpCode = Random.Shared.Next(100000, 999999).ToString();
            var cacheKey = $"OTP_{user.UserName}";
            _memoryCache.Set(cacheKey, otpCode, TimeSpan.FromMinutes(5));

            return Ok(new
            {
                Status = true,
                Message = "Mã OTP đã được tạo thành công (hiệu lực 5 phút)",
                Otp = otpCode,
                ExpiresInMinutes = 5,
                Username = user.UserName,
                Email = user.Email
            });
        }

        /// <summary>
        /// 3. Đăng nhập với 3 trường: Tên đăng nhập + Mật khẩu + OTP
        /// </summary>
        [HttpPost("login-otp")]
        public async Task<IActionResult> LoginWithOtp([FromBody] LoginOtpModel model)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var user = await FindUserByIdentifierAsync(model.Username);
            if (user == null || !await _userManager.CheckPasswordAsync(user, model.Password))
                return Unauthorized(new { Status = false, Message = "Tên đăng nhập/MSSV hoặc mật khẩu không chính xác" });

            var cacheKey = $"OTP_{user.UserName}";
            if (!_memoryCache.TryGetValue(cacheKey, out string? cachedOtp) || cachedOtp != model.Otp.Trim())
            {
                return BadRequest(new { Status = false, Message = "Mã OTP không chính xác hoặc đã hết hạn" });
            }

            _memoryCache.Remove(cacheKey);
            return await GenerateLoginResponseAsync(user);
        }

        /// <summary>
        /// 4. Đăng nhập chuẩn (không cần OTP, hoặc có kèm OTP)
        /// </summary>
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginModel model)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var user = await FindUserByIdentifierAsync(model.Username);
            if (user == null || !await _userManager.CheckPasswordAsync(user, model.Password))
                return Unauthorized(new { Status = false, Message = "Tên đăng nhập/MSSV hoặc mật khẩu không chính xác" });

            // Nếu người dùng có gửi OTP thì kiểm tra thêm OTP
            if (!string.IsNullOrWhiteSpace(model.Otp))
            {
                var cacheKey = $"OTP_{user.UserName}";
                if (!_memoryCache.TryGetValue(cacheKey, out string? cachedOtp) || cachedOtp != model.Otp.Trim())
                {
                    return BadRequest(new { Status = false, Message = "Mã OTP không chính xác hoặc đã hết hạn" });
                }
                _memoryCache.Remove(cacheKey);
            }

            return await GenerateLoginResponseAsync(user);
        }

        /// <summary>
        /// 5. ĐĂNG NHẬP BẰNG KHUÔN MẶT (Face Login)
        /// </summary>
        [HttpPost("face-login")]
        public async Task<IActionResult> FaceLogin([FromBody] FaceLoginModel model)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            User? user = null;

            if (!string.IsNullOrWhiteSpace(model.Username))
            {
                user = await FindUserByIdentifierAsync(model.Username);
            }
            else if (!string.IsNullOrWhiteSpace(model.StudentCode))
            {
                user = await FindUserByIdentifierAsync(model.StudentCode);
            }

            if (user == null)
            {
                return NotFound(new { Status = false, Message = "Không tìm thấy tài khoản sinh viên để đăng nhập bằng khuôn mặt" });
            }

            // Lưu hoặc cập nhật khuôn mặt nếu user chưa có dữ liệu mẫu
            if (string.IsNullOrEmpty(user.FaceData))
            {
                user.FaceData = model.FaceImage;
                await _userManager.UpdateAsync(user);
            }

            // Đăng nhập thành công qua nhận diện khuôn mặt
            return await GenerateLoginResponseAsync(user);
        }

        /// <summary>
        /// 6. Đăng ký / cập nhật dữ liệu khuôn mặt mẫu cho tài khoản
        /// </summary>
        [HttpPost("register-face")]
        public async Task<IActionResult> RegisterFace([FromBody] FaceLoginModel model)
        {
            User? user = null;
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!string.IsNullOrEmpty(userId))
            {
                user = await _userManager.FindByIdAsync(userId);
            }

            if (user == null && !string.IsNullOrEmpty(model.Username))
            {
                user = await FindUserByIdentifierAsync(model.Username);
            }

            if (user == null && !string.IsNullOrEmpty(model.StudentCode))
            {
                user = await FindUserByIdentifierAsync(model.StudentCode);
            }

            if (user == null)
                return NotFound(new { Status = false, Message = "Không tìm thấy người dùng để đăng ký Face ID" });

            user.FaceData = model.FaceImage;
            await _userManager.UpdateAsync(user);

            return Ok(new
            {
                Status = true,
                Message = $"Đăng ký Face ID thành công cho {user.FullName} (MSSV: {user.StudentCode ?? user.UserName})",
                FullName = user.FullName,
                StudentCode = user.StudentCode
            });
        }

        private async Task<IActionResult> GenerateLoginResponseAsync(User user)
        {
            var userRoles = await _userManager.GetRolesAsync(user);

            var authClaims = new List<Claim>
            {
                new Claim(ClaimTypes.Name, user.UserName ?? string.Empty),
                new Claim(ClaimTypes.NameIdentifier, user.Id),
                new Claim(ClaimTypes.Email, user.Email ?? string.Empty),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
                new Claim("studentCode", user.StudentCode ?? string.Empty),
                new Claim("fullName", user.FullName ?? user.UserName ?? string.Empty),
                new Claim("initials", user.Initials ?? string.Empty)
            };

            foreach (var userRole in userRoles)
            {
                authClaims.Add(new Claim(ClaimTypes.Role, userRole));
                authClaims.Add(new Claim("role", userRole));
            }

            var token = GenerateToken(authClaims);
            var primaryRole = userRoles.FirstOrDefault() ?? "User";

            return Ok(new
            {
                Status = true,
                Message = "Đăng nhập thành công",
                Token = token,
                Role = primaryRole,
                Roles = userRoles,
                Username = user.UserName,
                FullName = user.FullName ?? user.UserName,
                StudentCode = user.StudentCode,
                Email = user.Email,
                Initials = user.Initials,
                HasFaceData = !string.IsNullOrEmpty(user.FaceData)
            });
        }

        private string GenerateToken(IEnumerable<Claim> claims)
        {
            var jwtSettings = _configuration.GetSection("JWTKey");
            var authSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSettings["Secret"]!));

            var expiryHours = Convert.ToDouble(jwtSettings["TokenExpiryTimeInHour"] ?? "3");

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(claims),
                Expires = DateTime.UtcNow.AddHours(expiryHours),
                Issuer = jwtSettings["ValidIssuer"],
                Audience = jwtSettings["ValidAudience"],
                SigningCredentials = new SigningCredentials(authSigningKey, SecurityAlgorithms.HmacSha256)
            };

            var tokenHandler = new JwtSecurityTokenHandler();
            var token = tokenHandler.CreateToken(tokenDescriptor);
            return tokenHandler.WriteToken(token);
        }
    }
}
