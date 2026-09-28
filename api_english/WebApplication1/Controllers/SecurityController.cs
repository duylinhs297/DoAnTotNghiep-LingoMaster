using Microsoft.AspNetCore.Mvc;
using WebApplication1.Service;

namespace WebApplication1.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class SecurityController : ControllerBase
    {
        private readonly EmailService _emailService;
        private static readonly Dictionary<string, (string Code, DateTime Expiry)> OtpStore = new();

        // Inject EmailService qua Constructor
        public SecurityController(EmailService emailService)
        {
            _emailService = emailService;
        }

        [HttpPost("send-otp")]
        public async Task<IActionResult> SendOtp([FromBody] SendOtpRequest request)
        {
            if (string.IsNullOrEmpty(request.Email))
            {
                return BadRequest(new { message = "Email không được để trống!" });
            }

            try
            {
                string otp = new Random().Next(100000, 999999).ToString();
                OtpStore[request.Email] = (otp, DateTime.UtcNow.AddMinutes(5));

                // Gửi OTP đến chính email gửi lên từ request
                await _emailService.SendOtpEmailAsync(request.Email, otp, request.Purpose);

                return Ok(new { success = true, message = $"Mã OTP đã được gửi về email {request.Email}" });
            }
            catch (Exception ex)
            {
                // Bắt lỗi cấu hình Mail/SMTP nếu có
                return StatusCode(500, new { success = false, message = $"Gửi email thất bại: {ex.Message}" });
            }
        }

        [HttpPost("verify-otp")]
        public IActionResult VerifyOtp([FromBody] VerifyOtpRequest request)
        {
            if (OtpStore.TryGetValue(request.Email, out var cachedData))
            {
                if (DateTime.UtcNow > cachedData.Expiry)
                    return BadRequest(new { success = false, message = "Mã OTP đã hết hạn!" });

                if (cachedData.Code == request.OtpCode)
                {
                    OtpStore.Remove(request.Email);
                    return Ok(new { success = true, message = "Xác thực thành công!" });
                }
            }
            return BadRequest(new { success = false, message = "Mã OTP không chính xác!" });
        }
    }

    public record SendOtpRequest(string Email, string Purpose);
    public record VerifyOtpRequest(string Email, string OtpCode);
}