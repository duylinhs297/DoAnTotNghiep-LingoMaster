using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WebApplication1.Data;
using WebApplication1.DTOs;
using WebApplication1.Models;

namespace WebApplication1.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly AppDbContext _context;

        public AuthController(AppDbContext context)
        {
            _context = context;
        }

        // POST: api/Auth/register
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            // 1. Kiểm tra Email đã tồn tại chưa
            bool emailExists = await _context.Users.AnyAsync(u => u.Email.ToLower() == request.Email.ToLower());
            if (emailExists)
            {
                return BadRequest(new { message = "Email này đã được sử dụng. Vui lòng chọn Email khác!" });
            }

            // 2. Mã hóa mật khẩu bằng BCrypt
            string passwordHash = BCrypt.Net.BCrypt.HashPassword(request.Password);

            // 3. Kiểm tra xem đây có phải là tài khoản đầu tiên không
            bool isFirstUser = !await _context.Users.AnyAsync();
            string assignedRole = isFirstUser ? "Admin" : "User";

            // 4. Tạo Entity User mới
            var newUser = new User
            {
                Name = request.Name,
                Email = request.Email,
                PasswordHash = passwordHash,
                Phone = request.Phone ?? string.Empty,
                Role = assignedRole,
                CurrentLevel = "Sơ cấp",
                AccountType = "Tiêu chuẩn (Free)",
                IsPro = false,
                IsTwoFactorEnabled = false, // Khởi tạo mặc định tắt 2FA
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            // 5. Lưu vào cơ sở dữ liệu PostgreSQL
            _context.Users.Add(newUser);
            await _context.SaveChangesAsync();

            // 6. Trả về thông tin User mới tạo dưới dạng DTO
            var userDto = new UserDto
            {
                Id = newUser.Id,
                Name = newUser.Name,
                Email = newUser.Email,
                Phone = newUser.Phone,
                Role = newUser.Role,
                CurrentLevel = newUser.CurrentLevel,
                AccountType = newUser.AccountType,
                IsPro = newUser.IsPro,
                IsTwoFactorEnabled = newUser.IsTwoFactorEnabled
            };

            return Ok(new
            {
                message = isFirstUser
                    ? "Đăng ký thành công! Bạn là Quản trị viên (Admin) đầu tiên của hệ thống."
                    : "Đăng ký tài khoản thành công!",
                user = userDto
            });
        }

        // POST: api/Auth/login
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            // 1. Kiểm tra Email
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email.ToLower() == request.Email.ToLower());
            if (user == null)
            {
                return BadRequest(new { message = "Email hoặc mật khẩu không chính xác." });
            }

            // 2. Xác thực mật khẩu BCrypt
            bool isPasswordValid = BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash);
            if (!isPasswordValid)
            {
                return BadRequest(new { message = "Email hoặc mật khẩu không chính xác." });
            }

            // 3. Trả về kết quả kèm Token, Role trực tiếp và thông tin User
            return Ok(new
            {
                token = "fake-jwt-token-sample", // Sau này bạn có thể thay bằng hàm tạo JWT thật
                role = user.Role,              // Đưa trực tiếp role ra ngoài để React dễ lấy (ví dụ: 'Admin' hoặc 'User')
                user = new UserDto
                {
                    Id = user.Id,
                    Name = user.Name,
                    Email = user.Email,
                    Phone = user.Phone,
                    Role = user.Role,
                    CurrentLevel = user.CurrentLevel,
                    AccountType = user.AccountType,
                    IsPro = user.IsPro,
                    IsTwoFactorEnabled = user.IsTwoFactorEnabled
                }
            });
        }
    }
}