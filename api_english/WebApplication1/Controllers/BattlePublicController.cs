using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WebApplication1.Data;
using WebApplication1.DTOs;
using WebApplication1.Models;

namespace EnglishApp.Api.Controllers
{
    [Route("api/battle")]
    [ApiController]
    public class BattlePublicController : ControllerBase
    {
        private readonly AppDbContext _context;

        public BattlePublicController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet("stages")]
        public async Task<IActionResult> GetStagesForApp()
        {
            var data = await _context.BattleStages
                .Include(s => s.Questions)
                .OrderBy(s => s.Id)
                .Select(s => new {
                    id = s.Id,
                    title = s.Title,
                    subtitle = s.Subtitle,
                    questionsCount = s.Questions.Count,
                    timeLimit = s.TimeLimit ?? "15 phút",
                    colorHex = s.ColorHex ?? "#4F46E5"
                })
                .ToListAsync();

            return Ok(new
            {
                connected = true,
                message = "Kết nối API thành công",
                data = data
            });
        }

        [HttpGet("stages/{stageId}/questions")]
        public async Task<IActionResult> GetQuestionsByStage(string stageId)
        {
            var questions = await _context.BattleQuestions
                .Where(q => q.BattleStageId == stageId)
                .OrderBy(q => q.QuestionIndex)
                .Select(q => new
                {
                    id = q.Id,
                    battleStageId = q.BattleStageId,
                    questionIndex = q.QuestionIndex,
                    questionText = q.QuestionText,
                    options = q.Options,
                    correctAnswerIndex = q.CorrectAnswerIndex
                })
                .ToListAsync();

            return Ok(new
            {
                connected = true,
                message = "Lấy câu hỏi thành công",
                data = questions
            });
        }

        // Cập nhật: Cho phép nhận thêm ?userId=... từ query để xác định đúng "isMe"
        [HttpGet("stages/{stageId}/leaderboard")]
        public async Task<IActionResult> GetLeaderboardByStage(string stageId, [FromQuery] int? userId)
        {
            int currentUserId = userId ?? 0;
            if (currentUserId == 0)
            {
                var currentUserIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
                int.TryParse(currentUserIdClaim, out currentUserId);
            }

            var rawLeaderboard = await _context.Leaderboards
                .Where(l => l.StageId == stageId)
                .Include(l => l.User)
                .OrderByDescending(l => l.Score)
                .ThenBy(l => l.TimeSpentSeconds)
                .Take(50)
                .ToListAsync();

            var data = rawLeaderboard.Select((l, index) => {
                int minutes = l.TimeSpentSeconds / 60;
                int seconds = l.TimeSpentSeconds % 60;
                string formattedTime = minutes > 0 ? $"{minutes} phút {seconds} giây" : $"{seconds} giây";

                return new
                {
                    rank = index + 1,
                    name = l.User != null ? l.User.Name : "Người chơi",
                    score = l.Score,
                    timeSpentSeconds = l.TimeSpentSeconds,
                    formattedTime = formattedTime,
                    // Sửa lại điều kiện để an toàn hơn khi currentUserId = 0
                    isMe = currentUserId > 0 && l.UserId == currentUserId
                };
            }).ToList();

            return Ok(new
            {
                connected = true,
                message = "Lấy bảng xếp hạng thành công",
                data = data
            });
        }

        // ==================== NỘP KẾT QUẢ THI ĐẤU ====================

        [HttpPost("stages/{stageId}/submit")]
        public async Task<IActionResult> SubmitResult(string stageId, [FromBody] BattleSubmitDto dto)
        {
            var stageExists = await _context.BattleStages.AnyAsync(s => s.Id == stageId);
            if (!stageExists)
                return NotFound(new { success = false, message = "Không tìm thấy màn chơi." });

            // Lấy trực tiếp UserId từ DTO do Flutter gửi lên (dto.UserId)
            int userId = dto.UserId;

            // Fallback phòng hờ nếu dto.UserId chưa có thì đọc từ Token
            if (userId <= 0)
            {
                var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
                int.TryParse(userIdClaim, out userId);
            }

            if (userId <= 0)
            {
                return Unauthorized(new { success = false, message = "Vui lòng đăng nhập để lưu kết quả." });
            }

            var existingRecord = await _context.Leaderboards
                .FirstOrDefaultAsync(l => l.StageId == stageId && l.UserId == userId);

            if (existingRecord != null)
            {
                bool isBetterScore = dto.Score > existingRecord.Score;
                bool isEqualScoreButFaster = dto.Score == existingRecord.Score && dto.TimeSpentSeconds < existingRecord.TimeSpentSeconds;

                if (isBetterScore || isEqualScoreButFaster)
                {
                    existingRecord.Score = dto.Score;
                    existingRecord.TimeSpentSeconds = dto.TimeSpentSeconds;
                    existingRecord.AchievedAt = DateTime.UtcNow;
                }
            }
            else
            {
                var newLeaderboard = new Leaderboard
                {
                    StageId = stageId,
                    UserId = userId,
                    Score = dto.Score,
                    TimeSpentSeconds = dto.TimeSpentSeconds,
                    AchievedAt = DateTime.UtcNow
                };
                _context.Leaderboards.Add(newLeaderboard);
            }

            await _context.SaveChangesAsync();

            return Ok(new { success = true, message = "Đã lưu kết quả thi đấu thành công." });
        }
    }
}