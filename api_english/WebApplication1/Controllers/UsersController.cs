using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WebApplication1.Data;
using WebApplication1.DTOs;
using WebApplication1.Models;

namespace WebApplication1.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UsersController : ControllerBase
    {
        private readonly AppDbContext _context;

        public UsersController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/Users (Lấy danh sách, sắp xếp Admin lên đầu, sau đó theo ID tăng dần)
        [HttpGet]
        public async Task<ActionResult<IEnumerable<UserDto>>> GetAllUsers()
        {
            var users = await _context.Users
                .OrderByDescending(u => u.Role == "Admin") // Đưa 'Admin' lên trên cùng (true > false)
                .ThenBy(u => u.Id)                         // Sau đó sắp xếp tăng dần theo Id
                .Select(user => new UserDto
                {
                    Id = user.Id,
                    Name = user.Name,
                    Email = user.Email,
                    Phone = user.Phone,
                    Role = user.Role,
                    CurrentLevel = user.CurrentLevel,
                    AccountType = user.AccountType,
                    IsPro = user.IsPro
                })
                .ToListAsync();

            return Ok(users);
        }
        // POST: api/Users (Admin thêm tài khoản mới)
        [HttpPost]
        public async Task<IActionResult> CreateUser([FromBody] CreateUserRequest request)
        {
            bool emailExists = await _context.Users.AnyAsync(u => u.Email.ToLower() == request.Email.ToLower());
            if (emailExists)
            {
                return BadRequest(new { message = "Email này đã tồn tại trong hệ thống." });
            }

            var newUser = new User
            {
                Name = request.Name,
                Email = request.Email,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
                Phone = request.Phone,
                Role = request.Role,
                CurrentLevel = request.CurrentLevel,
                AccountType = request.AccountType,
                IsPro = request.IsPro,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _context.Users.Add(newUser);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Thêm tài khoản thành công!" });
        }
        // GET: api/Users/5 (Lấy thông tin chi tiết 1 người dùng để đổ vào Form Sửa)
        [HttpGet("{id}")]
        public async Task<ActionResult<UserDto>> GetUserById(int id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null)
            {
                return NotFound(new { message = "Không tìm thấy người dùng." });
            }

            var userDto = new UserDto
            {
                Id = user.Id,
                Name = user.Name,
                Email = user.Email,
                Phone = user.Phone,
                Role = user.Role,
                CurrentLevel = user.CurrentLevel,
                AccountType = user.AccountType,
                IsPro = user.IsPro
            };

            return Ok(userDto);
        }
        // PUT: api/Users/5 (Cập nhật tài khoản)
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateUser(int id, [FromBody] UpdateProfileRequest request)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null) return NotFound(new { message = "Không tìm thấy người dùng." });

            // BẢO VỆ: Nếu là tài khoản Admin gốc (Id = 1), KHÔNG cho phép đổi Role thành User
            if (user.Id == 1 && request.Role != "Admin")
            {
                return BadRequest(new { message = "Không được phép thay đổi vai trò của tài khoản Quản trị viên tối cao (ID = 1)." });
            }

            user.Name = request.Name;
            user.Email = request.Email;
            user.Phone = request.Phone;
            user.Role = request.Role; // Cập nhật role cho các admin khác (nếu có)
            user.CurrentLevel = request.CurrentLevel;
            user.AccountType = request.AccountType;
            user.IsPro = request.IsPro;
            user.UpdatedAt = DateTime.UtcNow;

            if (!string.IsNullOrWhiteSpace(request.Password))
            {
                user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password);
            }

            _context.Users.Update(user);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Cập nhật tài khoản thành công!" });
        }

        // DELETE: api/Users/5 (Xóa tài khoản)
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteUser(int id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null) return NotFound(new { message = "Không tìm thấy người dùng." });

            // BẢO VỆ: Tuyệt đối không cho phép xóa tài khoản ID = 1
            if (user.Id == 1)
            {
                return BadRequest(new { message = "Không thể xóa tài khoản Quản trị viên gốc của hệ thống (ID = 1)." });
            }

            _context.Users.Remove(user);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Xóa tài khoản thành công!" });
        }
    }
}