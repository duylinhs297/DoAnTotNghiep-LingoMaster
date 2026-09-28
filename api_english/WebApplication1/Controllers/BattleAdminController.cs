using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WebApplication1.Data;
using WebApplication1.DTOs;
using WebApplication1.Models;

namespace EnglishApp.Api.Controllers
{
    [Route("api/admin/battle")]
    [ApiController]
    public class BattleAdminController : ControllerBase
    {
        private readonly AppDbContext _context;

        public BattleAdminController(AppDbContext context)
        {
            _context = context;
        }

        // ==================== QUẢN LÝ MÀN CHƠI ====================

        [HttpGet]
        public async Task<IActionResult> GetAllStages()
        {
            var data = await _context.BattleStages
                .Include(s => s.Questions)
                .OrderBy(s => s.Id) // Hoặc đổi thành .OrderBy(s => s.CreatedAt) nếu bạn có lưu thời gian tạo
                .Select(s => new {
                    s.Id,
                    s.Title,
                    s.Subtitle,
                    s.TimeLimit,
                    s.ColorHex,
                    QuestionsCount = s.Questions.Count,
                    Questions = s.Questions.OrderBy(q => q.QuestionIndex).ToList()
                })
                .ToListAsync();

            return Ok(new { success = true, data });
        }

        [HttpPost]
        public async Task<IActionResult> CreateStage([FromBody] BattleStage stage)
        {
            if (string.IsNullOrWhiteSpace(stage.Id))
                stage.Id = $"stage_{Guid.NewGuid().ToString()[..8]}";

            stage.Questions ??= new List<BattleQuestion>();
            stage.QuestionsCount = stage.Questions.Count;

            _context.BattleStages.Add(stage);
            await _context.SaveChangesAsync();

            return Ok(new { success = true, message = "Đã thêm màn chơi thành công.", data = stage });
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateStage(string id, [FromBody] BattleStage updatedStage)
        {
            var existingStage = await _context.BattleStages
                .Include(s => s.Questions)
                .FirstOrDefaultAsync(s => s.Id == id);

            if (existingStage == null)
                return NotFound(new { success = false, message = "Không tìm thấy màn chơi." });

            existingStage.Title = updatedStage.Title;
            existingStage.Subtitle = updatedStage.Subtitle;
            existingStage.TimeLimit = updatedStage.TimeLimit;
            existingStage.ColorHex = updatedStage.ColorHex;
            existingStage.QuestionsCount = existingStage.Questions?.Count ?? 0;

            await _context.SaveChangesAsync();

            // Trả về object ẩn danh sạch sẽ thay vì trả về nguyên entity `existingStage`
            var resultData = new
            {
                existingStage.Id,
                existingStage.Title,
                existingStage.Subtitle,
                existingStage.TimeLimit,
                existingStage.ColorHex,
                existingStage.QuestionsCount,
                Questions = existingStage.Questions?.OrderBy(q => q.QuestionIndex).Select(q => new
                {
                    q.Id,
                    q.BattleStageId,
                    q.QuestionIndex,
                    q.QuestionText,
                    q.Options,
                    q.CorrectAnswerIndex
                }).ToList()
            };

            return Ok(new { success = true, message = "Đã cập nhật màn chơi.", data = resultData });
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteStage(string id)
        {
            var stage = await _context.BattleStages
                .Include(s => s.Questions)
                .FirstOrDefaultAsync(s => s.Id == id);

            if (stage == null)
                return NotFound(new { success = false, message = "Không tìm thấy màn chơi cần xóa." });

            // Kiểm tra nếu màn chơi vẫn còn câu hỏi
            bool hasQuestions = stage.Questions != null && stage.Questions.Any();

            // Kiểm tra nếu màn chơi vẫn còn dữ liệu xếp hạng (Leaderboard)
            bool hasLeaderboard = await _context.Leaderboards.AnyAsync(l => l.StageId == id);

            if (hasQuestions || hasLeaderboard)
            {
                return BadRequest(new
                {
                    success = false,
                    message = "Không thể xóa màn chơi này vì vẫn còn câu hỏi hoặc bảng xếp hạng người chơi. Vui lòng xóa hết câu hỏi và dữ liệu xếp hạng trước!"
                });
            }

            _context.BattleStages.Remove(stage);
            await _context.SaveChangesAsync();

            return Ok(new { success = true, message = "Đã xóa màn chơi thành công." });
        }

        // ==================== QUẢN LÝ CÂU HỎI ====================

        [HttpGet("{stageId}/questions")]
        public async Task<IActionResult> GetQuestions(string stageId)
        {
            var stageExists = await _context.BattleStages.AnyAsync(s => s.Id == stageId);
            if (!stageExists)
                return NotFound(new { success = false, message = "Không tìm thấy màn chơi." });

            var questions = await _context.BattleQuestions
                .Where(q => q.BattleStageId == stageId)
                .OrderBy(q => q.QuestionIndex)
                .ToListAsync();

            return Ok(new { success = true, data = questions });
        }

        [HttpPost("{stageId}/questions")]
        public async Task<IActionResult> AddQuestion(string stageId, [FromBody] QuestionCreateDto dto)
        {
            var stage = await _context.BattleStages.FirstOrDefaultAsync(s => s.Id == stageId);
            if (stage == null)
                return NotFound(new { success = false, message = "Không tìm thấy màn chơi." });

            var maxIndex = await _context.BattleQuestions
                .Where(x => x.BattleStageId == stageId)
                .MaxAsync(x => (int?)x.QuestionIndex) ?? 0;

            var newQuestion = new BattleQuestion
            {
                BattleStageId = stageId,
                QuestionIndex = maxIndex + 1,
                QuestionText = dto.QuestionText,
                Options = dto.Options,
                CorrectAnswerIndex = dto.CorrectAnswerIndex
            };

            _context.BattleQuestions.Add(newQuestion);

            // Tối ưu cập nhật count và lưu đồng thời
            stage.QuestionsCount = await _context.BattleQuestions.CountAsync(x => x.BattleStageId == stageId) + 1;

            await _context.SaveChangesAsync();

            // Trả về anonymous object sạch, tránh serialize toàn bộ Entity graph gây lỗi 500
            return Ok(new
            {
                success = true,
                message = "Đã thêm câu hỏi.",
                data = new
                {
                    newQuestion.Id,
                    newQuestion.BattleStageId,
                    newQuestion.QuestionIndex,
                    newQuestion.QuestionText,
                    newQuestion.Options,
                    newQuestion.CorrectAnswerIndex
                }
            });
        }

        [HttpPut("{stageId}/questions/{questionId}")]
        public async Task<IActionResult> UpdateQuestion(string stageId, int questionId, [FromBody] BattleQuestion q)
        {
            var existingQuestion = await _context.BattleQuestions
                .FirstOrDefaultAsync(x => x.BattleStageId == stageId && x.Id == questionId);

            if (existingQuestion == null)
                return NotFound(new { success = false, message = "Không tìm thấy câu hỏi." });

            existingQuestion.QuestionText = q.QuestionText;
            existingQuestion.Options = q.Options; // Sẽ tự serialize vào OptionsJson qua setter
            existingQuestion.CorrectAnswerIndex = q.CorrectAnswerIndex;

            await _context.SaveChangesAsync();

            return Ok(new { success = true, message = "Đã cập nhật câu hỏi.", data = existingQuestion });
        }

        [HttpDelete("{stageId}/questions/{questionId}")]
        public async Task<IActionResult> DeleteQuestion(string stageId, int questionId)
        {
            var question = await _context.BattleQuestions
                .FirstOrDefaultAsync(x => x.BattleStageId == stageId && x.Id == questionId);

            if (question == null)
                return NotFound(new { success = false, message = "Không tìm thấy câu hỏi cần xóa." });

            _context.BattleQuestions.Remove(question);
            await _context.SaveChangesAsync();

            // Đánh lại index cho các câu hỏi còn lại
            var remainingQuestions = await _context.BattleQuestions
                .Where(q => q.BattleStageId == stageId)
                .OrderBy(q => q.QuestionIndex)
                .ToListAsync();

            for (int i = 0; i < remainingQuestions.Count; i++)
            {
                remainingQuestions[i].QuestionIndex = i + 1;
            }

            var stage = await _context.BattleStages.FirstOrDefaultAsync(s => s.Id == stageId);
            if (stage != null)
            {
                stage.QuestionsCount = remainingQuestions.Count;
            }

            await _context.SaveChangesAsync();

            return Ok(new { success = true, message = "Đã xóa câu hỏi." });
        }

        [HttpPost("{stageId}/questions/shuffle")]
        public async Task<IActionResult> ShuffleQuestions(string stageId)
        {
            var stageExists = await _context.BattleStages.AnyAsync(s => s.Id == stageId);
            if (!stageExists)
                return NotFound(new { success = false, message = "Không tìm thấy màn chơi." });

            var questions = await _context.BattleQuestions
                .Where(q => q.BattleStageId == stageId)
                .ToListAsync();

            if (questions.Count == 0)
                return Ok(new { success = true, message = "Danh sách câu hỏi trống.", data = questions });

            var rnd = new Random();

            // 1. Xáo trộn đáp án (options) và cập nhật CorrectAnswerIndex cho từng câu hỏi
            foreach (var q in questions)
            {
                var currentOptions = q.Options ?? new List<string>();
                if (currentOptions.Count > 1 && q.CorrectAnswerIndex >= 0 && q.CorrectAnswerIndex < currentOptions.Count)
                {
                    var correctOptionText = currentOptions[q.CorrectAnswerIndex];

                    // Shuffle mảng options
                    var shuffledOptions = currentOptions.OrderBy(_ => rnd.Next()).ToList();

                    // Tìm lại index mới của đáp án đúng
                    q.Options = shuffledOptions;
                    q.CorrectAnswerIndex = shuffledOptions.IndexOf(correctOptionText);
                }
            }

            // 2. Xáo trộn vị trí danh sách câu hỏi
            var shuffledList = questions.OrderBy(_ => rnd.Next()).ToList();
            for (int i = 0; i < shuffledList.Count; i++)
            {
                shuffledList[i].QuestionIndex = i + 1;
            }

            await _context.SaveChangesAsync();

            // Trả về anonymous object sạch để tránh vòng lặp serialize
            var resultData = shuffledList.Select(q => new
            {
                q.Id,
                q.BattleStageId,
                q.QuestionIndex,
                q.QuestionText,
                q.Options,
                q.CorrectAnswerIndex
            });

            return Ok(new { success = true, message = "Đã đảo vị trí câu hỏi và xáo trộn đáp án.", data = resultData });
        }
        [HttpGet("{id}")]
        public async Task<IActionResult> GetStage(string id)
        {
            var stage = await _context.BattleStages
                .Include(s => s.Questions)
                .FirstOrDefaultAsync(s => s.Id == id);

            if (stage == null)
                return NotFound(new { success = false, message = "Không tìm thấy màn chơi." });

            var result = new
            {
                stage.Id,
                stage.Title,
                stage.Subtitle,
                stage.TimeLimit,
                stage.ColorHex,
                QuestionsCount = stage.Questions.Count,
                Questions = stage.Questions.OrderBy(q => q.QuestionIndex).Select(q => new
                {
                    q.Id,
                    q.BattleStageId,
                    q.QuestionIndex,
                    q.QuestionText,
                    q.Options,
                    q.CorrectAnswerIndex
                }).ToList()
            };

            return Ok(new { success = true, data = result });
        }
        // ==================== QUẢN LÝ XẾP HẠNG (LEADERBOARD) ====================

        [HttpGet("{stageId}/leaderboard")]
        public async Task<IActionResult> GetLeaderboard(string stageId)
        {
            var stageExists = await _context.BattleStages.AnyAsync(s => s.Id == stageId);
            if (!stageExists)
                return NotFound(new { success = false, message = "Không tìm thấy màn chơi." });

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
                    id = l.Id, // Đảm bảo có ID để gọi hàm Xóa kết quả
                    rank = index + 1,
                    userName = l.User != null ? l.User.Name : "Người chơi ẩn danh",
                    score = l.Score,
                    timeSpentSeconds = l.TimeSpentSeconds,
                    timeSpent = formattedTime // Khớp với trường component React đang đọc
                };
            }).ToList();

            return Ok(new { success = true, data = data });
        }

        [HttpDelete("{stageId}/leaderboard/{resultId}")]
        public async Task<IActionResult> DeleteLeaderboardItem(string stageId, int resultId)
        {
            var resultItem = await _context.Leaderboards
                .FirstOrDefaultAsync(r => r.StageId == stageId && r.Id == resultId);

            if (resultItem == null)
                return NotFound(new { success = false, message = "Không tìm thấy kết quả xếp hạng cần xóa." });

            _context.Leaderboards.Remove(resultItem);
            await _context.SaveChangesAsync();

            return Ok(new { success = true, message = "Đã xóa kết quả khỏi bảng xếp hạng." });
        }
    }
}