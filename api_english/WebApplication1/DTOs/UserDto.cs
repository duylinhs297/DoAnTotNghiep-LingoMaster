namespace WebApplication1.DTOs
{
    public class UserDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Phone { get; set; } = string.Empty;
        public string Role { get; set; } = string.Empty;

        // Trả về CurrentLevel để khớp với key Flutter đang đọc
        public string CurrentLevel { get; set; } = string.Empty;
        public string AccountType { get; set; } = string.Empty;
        public bool IsPro { get; set; }

        // BỔ SUNG: Trạng thái 2FA
        public bool IsTwoFactorEnabled { get; set; }
    }
}