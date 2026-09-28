using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace WebApplication1.Models
{
    [Table("users")]
    public class User
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        [Column("id")]
        public int Id { get; set; }

        [Required]
        [MaxLength(100)]
        [Column("name")]
        public string Name { get; set; } = string.Empty;

        [Required]
        [MaxLength(150)]
        [Column("email")]
        public string Email { get; set; } = string.Empty;

        [Required]
        [Column("password_hash")]
        public string PasswordHash { get; set; } = string.Empty;

        [MaxLength(20)]
        [Column("phone")]
        public string Phone { get; set; } = string.Empty;

        [Required]
        [MaxLength(20)]
        [Column("role")]
        public string Role { get; set; } = "User";

        [Required]
        [MaxLength(50)]
        [Column("current_level")]
        public string CurrentLevel { get; set; } = "Sơ cấp";

        [Required]
        [MaxLength(50)]
        [Column("account_type")]
        public string AccountType { get; set; } = "Tiêu chuẩn (Free)";

        [Column("is_pro")]
        public bool IsPro { get; set; } = false;

        // ================= BỔ SUNG BẢO MẬT 2FA =================
        [Column("is_two_factor_enabled")]
        public bool IsTwoFactorEnabled { get; set; } = false;

        // ================= THÊM CÁC TRƯỜNG ĐIỂM DANH =================

        [Column("streak_count")]
        public int StreakCount { get; set; } = 0; // Tổng số ngày liên tiếp

        [Column("last_attendance_date")]
        public DateTime? LastAttendanceDate { get; set; } // Ngày điểm danh gần nhất

        // Navigation property liên kết bảng lịch sử điểm danh
        public ICollection<UserAttendance> Attendances { get; set; } = new List<UserAttendance>();
        public ICollection<Leaderboard> Leaderboards { get; set; } = new List<Leaderboard>();
        // ============================================================

        [Column("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [Column("updated_at")]
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    }
}