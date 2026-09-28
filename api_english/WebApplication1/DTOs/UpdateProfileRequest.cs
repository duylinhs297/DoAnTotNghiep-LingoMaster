using System.ComponentModel.DataAnnotations;

namespace WebApplication1.DTOs
{
    public class UpdateProfileRequest
    {
        [Required]
        public string Name { get; set; } = string.Empty;

        [Required, EmailAddress]
        public string Email { get; set; } = string.Empty;

        public string? Password { get; set; }

        public string Phone { get; set; } = string.Empty;

        // Bổ sung cho trang Admin
        public string Role { get; set; } = "User";
        public string CurrentLevel { get; set; } = "Sơ cấp";
        public string AccountType { get; set; } = "Tiêu chuẩn (Free)";
        public bool IsPro { get; set; } = false;
    }
}