using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace WebApplication1.Models
{
    [Table("leaderboards")]
    public class Leaderboard
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        [Column("id")]
        public int Id { get; set; }

        [Required]
        [Column("user_id")]
        public int UserId { get; set; }

        [Required]
        [MaxLength(100)]
        [Column("stage_id")]
        public string StageId { get; set; } = string.Empty; // Mã màn chơi hoặc chế độ chơi (tương ứng với selectedLeaderboardStageId bên Flutter)

        [Column("score")]
        public int Score { get; set; } = 0; // Điểm số đạt được

        [Column("time_spent_seconds")]
        public int TimeSpentSeconds { get; set; } = 0; // Thời gian hoàn thành (tùy chọn, dùng để xếp hạng phụ nếu trùng điểm)

        [Column("achieved_at")]
        public DateTime AchievedAt { get; set; } = DateTime.UtcNow; // Thời điểm đạt thành tích

        // Navigation property liên kết ngược lại với bảng User
        [ForeignKey("UserId")]
        public User? User { get; set; }
    }
}