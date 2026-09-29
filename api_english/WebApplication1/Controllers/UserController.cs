using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PayOS;          // Thư viện chính
using PayOS.Models;   // Namespace chứa các Model dữ liệu chuẩn của PayOS v2.x
using PayOS.Models.V2.PaymentRequests;
using WebApplication1.Data;
using WebApplication1.DTOs;
using WebApplication1.Models;
using WebApplication1.Service;

namespace WebApplication1.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UserController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IConfiguration _configuration;
        private readonly EmailService _emailService;
        public UserController(AppDbContext context, IConfiguration configuration, EmailService emailService)
        {
            _context = context;
            _configuration = configuration;
            _emailService = emailService;
        }

        // DTOs
        public class CheckInRequest
        {
            public int UserId { get; set; }
        }

        // 1. GET: api/User/profile/5 -> Lấy thông tin user + Lịch sử điểm danh tuần này
        [HttpGet("profile/{userId}")]
        public async Task<IActionResult> GetUserProfile(int userId)
        {
            var user = await _context.Users.FindAsync(userId);
            if (user == null) return NotFound(new { message = "Không tìm thấy người dùng!" });

            var today = DateTime.UtcNow.Date;

            bool hasCheckedInToday = user.LastAttendanceDate.HasValue &&
                                     user.LastAttendanceDate.Value.Date == today;

            int diff = (int)today.DayOfWeek - (int)DayOfWeek.Monday;
            if (diff < 0) diff += 7;
            var startOfWeek = today.AddDays(-diff);
            var endOfWeek = startOfWeek.AddDays(6);

            var weeklyAttendances = await _context.UserAttendances
                .Where(a => a.UserId == userId && a.AttendanceDate >= startOfWeek && a.AttendanceDate <= endOfWeek)
                .Select(a => a.AttendanceDate.ToString("yyyy-MM-dd"))
                .ToListAsync();

            return Ok(new
            {
                user.Id,
                user.Name,
                user.Email,
                user.CurrentLevel,
                user.StreakCount,
                user.LastAttendanceDate,
                hasCheckedInToday,
                weeklyAttendances
            });
        }

        // 2. POST: api/User/check-in -> Thực hiện điểm danh
        [HttpPost("check-in")]
        public async Task<IActionResult> CheckIn([FromBody] CheckInRequest req)
        {
            var user = await _context.Users.FindAsync(req.UserId);
            if (user == null) return NotFound(new { message = "Không tìm thấy người dùng!" });

            var today = DateTime.UtcNow.Date;

            if (user.LastAttendanceDate.HasValue && user.LastAttendanceDate.Value.Date == today)
            {
                return BadRequest(new { message = "Hôm nay bạn đã điểm danh rồi!" });
            }

            if (user.LastAttendanceDate.HasValue && user.LastAttendanceDate.Value.Date == today.AddDays(-1))
            {
                user.StreakCount += 1;
            }
            else
            {
                user.StreakCount = 1;
            }

            user.LastAttendanceDate = today;
            user.UpdatedAt = DateTime.UtcNow;

            var attendance = new UserAttendance
            {
                UserId = user.Id,
                AttendanceDate = today,
                CreatedAt = DateTime.UtcNow
            };

            _context.UserAttendances.Add(attendance);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "Điểm danh thành công!",
                streakCount = user.StreakCount,
                attendanceDate = today.ToString("yyyy-MM-dd")
            });
        }

        // 3. PUT: api/User/profile/{userId} -> Cập nhật thông tin cá nhân
        [HttpPut("profile/{userId}")]
        public async Task<IActionResult> UpdateProfile(int userId, [FromBody] UpdateProfileRequest request)
        {
            var user = await _context.Users.FindAsync(userId);
            if (user == null)
            {
                return NotFound(new { message = "Không tìm thấy người dùng!" });
            }

            if (!string.Equals(user.Email, request.Email, StringComparison.OrdinalIgnoreCase))
            {
                bool emailExists = await _context.Users.AnyAsync(u => u.Email.ToLower() == request.Email.ToLower() && u.Id != userId);
                if (emailExists)
                {
                    return BadRequest(new { message = "Email này đã được sử dụng bởi tài khoản khác!" });
                }
                user.Email = request.Email;
            }

            user.Name = request.Name;
            user.Phone = request.Phone;

            if (!string.IsNullOrWhiteSpace(request.Password))
            {
                user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password);
            }

            if (!string.IsNullOrEmpty(request.CurrentLevel)) user.CurrentLevel = request.CurrentLevel;
            if (!string.IsNullOrEmpty(request.AccountType)) user.AccountType = request.AccountType;
            user.IsPro = request.IsPro;
            user.UpdatedAt = DateTime.UtcNow;

            _context.Users.Update(user);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "Cập nhật thông tin thành công!",
                user = new
                {
                    user.Id,
                    user.Name,
                    user.Email,
                    user.Phone,
                    user.CurrentLevel,
                    user.AccountType,
                    user.IsPro
                }
            });
        }

        // 4. POST: api/User/upgrade-pro -> Thanh toán nâng cấp tài khoản lên PRO
        [HttpPost("upgrade-pro")]
        public async Task<IActionResult> UpgradePro([FromBody] UpgradeProRequest req)
        {
            var user = await _context.Users.FindAsync(req.UserId);
            if (user == null)
            {
                return NotFound(new { message = "Không tìm thấy người dùng!" });
            }

            user.IsPro = true;
            user.AccountType = req.PlanTitle.Contains("Trọn Đời") ? "PRO Trọn Đời" : "PRO (1 Tháng)";
            user.UpdatedAt = DateTime.UtcNow;

            _context.Users.Update(user);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "Nâng cấp tài khoản PRO thành công!",
                user = new
                {
                    user.Id,
                    user.Name,
                    user.Email,
                    user.AccountType,
                    user.IsPro
                }
            });
        }

        [HttpPost("create-momo-payment")]
        public async Task<IActionResult> CreatePayOSPayment([FromBody] UpgradeProRequest req)
        {
            try
            {
                var user = await _context.Users.FindAsync(req.UserId);
                if (user == null) return NotFound(new { message = "Không tìm thấy người dùng!" });

                bool isMockMode = false;

                long amount = (req.PlanTitle != null && req.PlanTitle.Contains("Trọn Đời")) ? 11000 : 10000;
                int orderCode = int.Parse(DateTime.UtcNow.Ticks.ToString().Substring(9, 9));

                if (isMockMode)
                {
                    if (!string.IsNullOrEmpty(user.Email))
                    {
                        await _emailService.SendProInvoiceEmailAsync(user.Email, req.PlanTitle ?? "Gói PRO", amount, orderCode);
                    }

                    var mockResponse = new
                    {
                        error = 0,
                        message = "Tạo link thanh toán thành công & Đã gửi email (Mock Mode)",
                        data = new
                        {
                            checkoutUrl = "https://flutter.dev",
                            qrCode = "https://api.vietqr.io/image/970422-0000000000-compact2.png?amount=" + amount,
                            orderCode = orderCode
                        }
                    };
                    return Ok(mockResponse);
                }

                string clientId = "c864b83d-d60c-4f83-a527-f5dc072b7772";
                string apiKey = "c3431ad7-109e-496e-ad3a-6074d3e25a4f";
                string checksumKey = "0b487855d1f9546e8cd0bc90c3250c08d667f107185388d313d95cae1d69920f";

                PayOSClient payOS = new PayOSClient(clientId, apiKey, checksumKey);

                string description = $"Nang cap PRO {req.UserId}";
                string cancelUrl = "lingomaster://payment-cancel";

                // CẬP NHẬT RETURN URL ĐỂ ĐẨY VỀ APP FLUTTER
                string returnUrl = "lingomaster://payment-success";

                var paymentRequest = new CreatePaymentLinkRequest
                {
                    OrderCode = orderCode,
                    Amount = (int)amount,
                    Description = description,
                    CancelUrl = cancelUrl,
                    ReturnUrl = returnUrl
                };

                var createPayment = await payOS.PaymentRequests.CreateAsync(paymentRequest);

                if (!string.IsNullOrEmpty(user.Email))
                {
                    await _emailService.SendProInvoiceEmailAsync(user.Email, req.PlanTitle ?? "Gói PRO", amount, orderCode);
                }

                return Ok(new
                {
                    error = 0,
                    message = "Tạo link thanh toán thành công và đã gửi thông tin qua email",
                    data = createPayment
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi tạo thanh toán PayOS", error = ex.Message });
            }
        }
    }
}