using Microsoft.EntityFrameworkCore;
using WebApplication1.Models;

namespace WebApplication1.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<User> Users { get; set; }
        public DbSet<UserAttendance> UserAttendances { get; set; }
        public DbSet<CourseLevel> CourseLevels { get; set; }
        public DbSet<CourseCategory> CourseCategories { get; set; }
        public DbSet<CourseTopic> CourseTopics { get; set; }

        // Bổ sung 4 DbSet cho 4 bảng con chi tiết
        public DbSet<VocabItem> VocabItems { get; set; }
        public DbSet<SpeakingItem> SpeakingItems { get; set; }
        public DbSet<QuizItem> QuizItems { get; set; }
        public DbSet<ListeningItem> ListeningItems { get; set; }
        public DbSet<BattleStage> BattleStages { get; set; }
        public DbSet<BattleQuestion> BattleQuestions { get; set; }

        // Thêm DbSet cho Leaderboard
        public DbSet<Leaderboard> Leaderboards { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Cấu hình bảng User
            modelBuilder.Entity<User>(entity =>
            {
                entity.HasIndex(u => u.Email).IsUnique();
                entity.Property(u => u.CurrentLevel).HasDefaultValue("Sơ cấp");
                entity.Property(u => u.AccountType).HasDefaultValue("Tiêu chuẩn (Free)");
                entity.Property(u => u.Role).HasDefaultValue("User");
                entity.Property(u => u.IsPro).HasDefaultValue(false);
            });

            // Cấu hình quan hệ giữa CourseLevel và CourseCategory (1 - N)
            modelBuilder.Entity<CourseCategory>()
                .HasOne(c => c.Level)
                .WithMany(l => l.Categories)
                .HasForeignKey(c => c.LevelId)
                .OnDelete(DeleteBehavior.Cascade);

            // Cấu hình quan hệ giữa CourseCategory và CourseTopic (1 - N)
            modelBuilder.Entity<CourseTopic>()
                .HasOne(t => t.Category)
                .WithMany(c => c.Topics)
                .HasForeignKey(t => t.CategoryId)
                .OnDelete(DeleteBehavior.Cascade);

            // Giá trị mặc định cho CourseTopic
            modelBuilder.Entity<CourseTopic>()
                .Property(t => t.TimeLimitSeconds)
                .HasDefaultValue(20);

            // -------------------------------------------------------------
            // Cấu hình quan hệ giữa CourseTopic và 4 Bảng Chi Tiết (1 - N)
            // -------------------------------------------------------------

            // 1. VocabItem -> CourseTopic
            modelBuilder.Entity<VocabItem>()
                .HasOne(v => v.Topic)
                .WithMany()
                .HasForeignKey(v => v.TopicId)
                .OnDelete(DeleteBehavior.Cascade);

            // 2. SpeakingItem -> CourseTopic
            modelBuilder.Entity<SpeakingItem>()
                .HasOne(s => s.Topic)
                .WithMany()
                .HasForeignKey(s => s.TopicId)
                .OnDelete(DeleteBehavior.Cascade);

            // 3. QuizItem -> CourseTopic
            modelBuilder.Entity<QuizItem>()
                .HasOne(q => q.Topic)
                .WithMany()
                .HasForeignKey(q => q.TopicId)
                .OnDelete(DeleteBehavior.Cascade);

            // 4. ListeningItem -> CourseTopic
            modelBuilder.Entity<ListeningItem>()
                .HasOne(l => l.Topic)
                .WithMany()
                .HasForeignKey(l => l.TopicId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<UserAttendance>(entity =>
            {
                // Đảm bảo 1 user chỉ có 1 bản ghi điểm danh per ngày
                entity.HasIndex(a => new { a.UserId, a.AttendanceDate }).IsUnique();

                // Cấu hình khóa ngoại liên kết với User
                entity.HasOne(a => a.User)
                      .WithMany(u => u.Attendances)
                      .HasForeignKey(a => a.UserId)
                      .OnDelete(DeleteBehavior.Cascade);
            });

            modelBuilder.Entity<BattleStage>().HasKey(s => s.Id);

            modelBuilder.Entity<BattleQuestion>()
                .HasOne(q => q.BattleStage)
                .WithMany(s => s.Questions)
                .HasForeignKey(q => q.BattleStageId)
                .OnDelete(DeleteBehavior.Cascade);

            // -------------------------------------------------------------
            // Cấu hình quan hệ cho Leaderboard (Bổ sung mới)
            // -------------------------------------------------------------
            modelBuilder.Entity<Leaderboard>(entity =>
            {
                entity.HasKey(l => l.Id);

                // Liên kết khóa ngoại giữa Leaderboard và User
                entity.HasOne(l => l.User)
                      .WithMany(u => u.Leaderboards)
                      .HasForeignKey(l => l.UserId)
                      .OnDelete(DeleteBehavior.Cascade);
            });
        }
    }
}