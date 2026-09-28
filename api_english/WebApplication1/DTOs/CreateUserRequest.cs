using System.ComponentModel.DataAnnotations;

namespace WebApplication1.DTOs
{
    public class CreateUserRequest
    {
        [Required]
        public string Name { get; set; } = string.Empty;

        [Required, EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required, MinLength(6)]
        public string Password { get; set; } = string.Empty;

        public string Phone { get; set; } = string.Empty;
        public string Role { get; set; } = "User";
        public string CurrentLevel { get; set; } = "Sơ cấp";
        public string AccountType { get; set; } = "Tiêu chuẩn (Free)";
        public bool IsPro { get; set; } = false;
    }
}
