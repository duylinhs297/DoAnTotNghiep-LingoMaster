using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WebApplication1.Data;
using WebApplication1.Models;

namespace WebApplication1.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class CourseAdminController : ControllerBase
    {
        private readonly AppDbContext _context;

        public CourseAdminController(AppDbContext context)
        {
            _context = context;
        }

        // --- 1. QUẢN LÝ CẤP ĐỘ (CourseLevel) ---
        [HttpGet("levels")]
        public async Task<IActionResult> GetLevels()
        {
            var levels = await _context.CourseLevels.OrderBy(l => l.Order).ToListAsync();
            return Ok(levels);
        }

        [HttpPost("level")]
        public async Task<IActionResult> CreateLevel([FromBody] CourseLevel level)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
                _context.CourseLevels.Add(level);
                await _context.SaveChangesAsync();
                return Ok(new { message = "Thêm cấp độ học thành công!", data = level });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi lưu database!", detail = ex.Message });
            }
        }

        [HttpPut("level/{id}")]
        public async Task<IActionResult> UpdateLevel(int id, [FromBody] CourseLevel level)
        {
            var existingLevel = await _context.CourseLevels.FindAsync(id);
            if (existingLevel == null) return NotFound(new { message = "Không tìm thấy cấp độ cần cập nhật." });

            existingLevel.Name = level.Name;
            existingLevel.Order = level.Order;

            await _context.SaveChangesAsync();
            return Ok(new { message = "Cập nhật cấp độ thành công!", data = existingLevel });
        }

        [HttpDelete("level/{id}")]
        public async Task<IActionResult> DeleteLevel(int id)
        {
            var level = await _context.CourseLevels.FindAsync(id);
            if (level == null) return NotFound(new { message = "Không tìm thấy cấp độ cần xóa." });

            bool hasCategories = await _context.CourseCategories.AnyAsync(c => c.LevelId == id);
            if (hasCategories)
            {
                return BadRequest(new { message = "⚠️ Không thể xóa cấp độ này vì vẫn còn danh mục khóa học bên trong! Vui lòng xóa hết danh mục trước." });
            }

            _context.CourseLevels.Remove(level);
            await _context.SaveChangesAsync();
            return Ok(new { message = "✅ Đã xóa cấp độ thành công!" });
        }

        // --- 2. QUẢN LÝ DANH MỤC (CourseCategory) ---
        [HttpGet("categories")]
        public async Task<IActionResult> GetCategories([FromQuery] int levelId, [FromQuery] string skillType)
        {
            var categories = await _context.CourseCategories
                .Where(c => c.LevelId == levelId && c.SkillType == skillType)
                .ToListAsync();
            return Ok(categories);
        }

        [HttpPost("category")]
        public async Task<IActionResult> CreateCategory([FromBody] CourseCategory category)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            _context.CourseCategories.Add(category);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Thêm danh mục thành công!", data = category });
        }

        [HttpPut("category/{id}")]
        public async Task<IActionResult> UpdateCategory(int id, [FromBody] CourseCategory category)
        {
            var existingCategory = await _context.CourseCategories.FindAsync(id);
            if (existingCategory == null) return NotFound(new { message = "Không tìm thấy danh mục cần cập nhật." });

            existingCategory.Name = category.Name;
            existingCategory.Description = category.Description;

            await _context.SaveChangesAsync();
            return Ok(new { message = "Cập nhật danh mục thành công!", data = existingCategory });
        }

        [HttpDelete("category/{id}")]
        public async Task<IActionResult> DeleteCategory(int id)
        {
            var category = await _context.CourseCategories.FindAsync(id);
            if (category == null) return NotFound(new { message = "Không tìm thấy danh mục cần xóa." });

            bool hasTopics = await _context.CourseTopics.AnyAsync(t => t.CategoryId == id);
            if (hasTopics)
            {
                return BadRequest(new { message = "⚠️ Không thể xóa danh mục này vì vẫn còn chủ đề bên trong! Vui lòng xóa hết chủ đề trước." });
            }

            _context.CourseCategories.Remove(category);
            await _context.SaveChangesAsync();
            return Ok(new { message = "✅ Đã xóa danh mục thành công!" });
        }

        // --- 3. QUẢN LÝ CHỦ ĐỀ (CourseTopic) ---
        [HttpGet("topics")]
        public async Task<IActionResult> GetTopics([FromQuery] int categoryId)
        {
            var category = await _context.CourseCategories.FindAsync(categoryId);
            string skillType = category?.SkillType ?? "VOCAB";

            var topics = await _context.CourseTopics
                .Where(t => t.CategoryId == categoryId)
                .ToListAsync();

            var result = new List<object>();
            foreach (var topic in topics)
            {
                int count = skillType switch
                {
                    "VOCAB" => await _context.VocabItems.CountAsync(x => x.TopicId == topic.Id),
                    "QUIZ" => await _context.QuizItems.CountAsync(x => x.TopicId == topic.Id),
                    "SPEAKING" => await _context.SpeakingItems.CountAsync(x => x.TopicId == topic.Id),
                    "LISTENING" => await _context.ListeningItems.CountAsync(x => x.TopicId == topic.Id),
                    _ => await _context.VocabItems.CountAsync(x => x.TopicId == topic.Id)
                };

                result.Add(new
                {
                    topic.Id,
                    topic.CategoryId,
                    topic.Title,
                    topic.Subtitle,
                    topic.CategoryKey,
                    ItemCount = count,
                    topic.TimeLimitSeconds
                });
            }

            return Ok(result);
        }

        [HttpPost("topic")]
        public async Task<IActionResult> CreateTopic([FromBody] CourseTopic topic)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            _context.CourseTopics.Add(topic);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Thêm chủ đề thành công!", data = topic });
        }

        [HttpPut("topic/{id}")]
        public async Task<IActionResult> UpdateTopic(int id, [FromBody] CourseTopic topic)
        {
            var existingTopic = await _context.CourseTopics.FindAsync(id);
            if (existingTopic == null) return NotFound(new { message = "Không tìm thấy chủ đề cần cập nhật." });

            existingTopic.Title = topic.Title;
            existingTopic.Subtitle = topic.Subtitle;
            existingTopic.CategoryKey = topic.CategoryKey;
            existingTopic.ItemCount = topic.ItemCount;
            existingTopic.TimeLimitSeconds = topic.TimeLimitSeconds;

            await _context.SaveChangesAsync();
            return Ok(new { message = "Cập nhật chủ đề thành công!" });
        }

        [HttpDelete("topic/{id}")]
        public async Task<IActionResult> DeleteTopic(int id)
        {
            var topic = await _context.CourseTopics.FindAsync(id);
            if (topic == null) return NotFound(new { message = "Không tìm thấy chủ đề cần xóa." });

            var category = await _context.CourseCategories.FindAsync(topic.CategoryId);
            string skillType = category?.SkillType ?? "VOCAB";

            int itemCount = skillType switch
            {
                "VOCAB" => await _context.VocabItems.CountAsync(x => x.TopicId == topic.Id),
                "QUIZ" => await _context.QuizItems.CountAsync(x => x.TopicId == topic.Id),
                "SPEAKING" => await _context.SpeakingItems.CountAsync(x => x.TopicId == topic.Id),
                "LISTENING" => await _context.ListeningItems.CountAsync(x => x.TopicId == topic.Id),
                _ => await _context.VocabItems.CountAsync(x => x.TopicId == topic.Id)
            };

            if (itemCount > 0)
            {
                return BadRequest(new
                {
                    message = $"⚠️ Không thể xóa chủ đề này vì vẫn còn tồn tại {itemCount} mục nội dung ({skillType}) bên trong. Vui lòng xóa hết các mục chi tiết trước!"
                });
            }

            _context.CourseTopics.Remove(topic);
            await _context.SaveChangesAsync();
            return Ok(new { message = "✅ Đã xóa chủ đề thành công!" });
        }

        // ==========================================
        // --- 4. API QUẢN LÝ DỮ LIỆU CHI TIẾT ---
        // ==========================================

        // --- A. Từ vựng & Flashcard (VocabItem) ---
        [HttpGet("vocab-items")]
        public async Task<IActionResult> GetVocabItems([FromQuery] int topicId)
        {
            var items = await _context.VocabItems.Where(x => x.TopicId == topicId).ToListAsync();
            return Ok(items);
        }

        [HttpPost("vocab-item")]
        public async Task<IActionResult> CreateVocabItem([FromBody] VocabItem item)
        {
            _context.VocabItems.Add(item);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Thêm từ vựng thành công!", data = item });
        }

        [HttpPut("vocab-item/{id}")]
        public async Task<IActionResult> UpdateVocabItem(int id, [FromBody] VocabItem item)
        {
            var existingItem = await _context.VocabItems.FindAsync(id);
            if (existingItem == null) return NotFound(new { message = "Không tìm thấy từ vựng." });

            existingItem.Word = item.Word;
            existingItem.Phonetic = item.Phonetic;
            existingItem.Meaning = item.Meaning;
            existingItem.Example = item.Example;

            await _context.SaveChangesAsync();
            return Ok(new { message = "Cập nhật từ vựng thành công!" });
        }

        [HttpDelete("vocab-item/{id}")]
        public async Task<IActionResult> DeleteVocabItem(int id)
        {
            var item = await _context.VocabItems.FindAsync(id);
            if (item == null) return NotFound(new { message = "Không tìm thấy từ vựng cần xóa." });

            _context.VocabItems.Remove(item);
            await _context.SaveChangesAsync();
            return Ok(new { message = "✅ Đã xóa từ vựng thành công!" });
        }

        // --- B. Trắc nghiệm (QuizItem) ---
        [HttpGet("quiz-items")]
        public async Task<IActionResult> GetQuizItems([FromQuery] int topicId)
        {
            var items = await _context.QuizItems.Where(x => x.TopicId == topicId).ToListAsync();
            return Ok(items);
        }

        [HttpPost("quiz-item")]
        public async Task<IActionResult> CreateQuizItem([FromBody] QuizItem item)
        {
            _context.QuizItems.Add(item);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Thêm câu hỏi thành công!", data = item });
        }

        [HttpPut("quiz-item/{id}")]
        public async Task<IActionResult> UpdateQuizItem(int id, [FromBody] QuizItem item)
        {
            var existingItem = await _context.QuizItems.FindAsync(id);
            if (existingItem == null) return NotFound(new { message = "Không tìm thấy câu hỏi." });

            existingItem.Question = item.Question;
            existingItem.OptionA = item.OptionA;
            existingItem.OptionB = item.OptionB;
            existingItem.OptionC = item.OptionC;
            existingItem.OptionD = item.OptionD;
            existingItem.CorrectOption = item.CorrectOption;

            await _context.SaveChangesAsync();
            return Ok(new { message = "Cập nhật câu hỏi thành công!", data = existingItem });
        }

        [HttpDelete("quiz-item/{id}")]
        public async Task<IActionResult> DeleteQuizItem(int id)
        {
            var item = await _context.QuizItems.FindAsync(id);
            if (item == null) return NotFound(new { message = "Không tìm thấy câu hỏi cần xóa." });

            _context.QuizItems.Remove(item);
            await _context.SaveChangesAsync();
            return Ok(new { message = "✅ Đã xóa câu hỏi thành công!" });
        }

        // --- C. Nói (SpeakingItem) ---
        [HttpGet("speaking-items")]
        public async Task<IActionResult> GetSpeakingItems([FromQuery] int topicId)
        {
            var items = await _context.SpeakingItems
                .Where(x => x.TopicId == topicId)
                .ToListAsync();
            return Ok(items);
        }

        [HttpPost("speaking-item")]
        public async Task<IActionResult> CreateSpeakingItem([FromBody] SpeakingItem item)
        {
            _context.SpeakingItems.Add(item);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Thêm câu nói thành công!", data = item });
        }

        [HttpPut("speaking-item/{id}")]
        public async Task<IActionResult> UpdateSpeakingItem(int id, [FromBody] SpeakingItem item)
        {
            var existing = await _context.SpeakingItems.FindAsync(id);
            if (existing == null) return NotFound(new { message = "Không tìm thấy dữ liệu." });

            existing.Sentence = item.Sentence;
            existing.Translation = item.Translation;
            existing.Phonetic = item.Phonetic;
            existing.AudioUrl = item.AudioUrl;

            await _context.SaveChangesAsync();
            return Ok(new { message = "Cập nhật thành công!", data = existing });
        }

        [HttpDelete("speaking-item/{id}")]
        public async Task<IActionResult> DeleteSpeakingItem(int id)
        {
            var item = await _context.SpeakingItems.FindAsync(id);
            if (item == null) return NotFound(new { message = "Không tìm thấy dữ liệu cần xóa." });

            _context.SpeakingItems.Remove(item);
            await _context.SaveChangesAsync();
            return Ok(new { message = "✅ Đã xóa câu nói thành công!" });
        }

        // --- D. Nghe (ListeningItem) ---
        [HttpGet("listening-items")]
        public async Task<IActionResult> GetListeningItems([FromQuery] int topicId)
        {
            var items = await _context.ListeningItems.Where(x => x.TopicId == topicId).ToListAsync();
            return Ok(items);
        }

        [HttpPost("listening-item")]
        public async Task<IActionResult> CreateListeningItem([FromBody] ListeningItem item)
        {
            _context.ListeningItems.Add(item);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Thêm bài nghe thành công!", data = item });
        }

        [HttpPut("listening-item/{id}")]
        public async Task<IActionResult> UpdateListeningItem(int id, [FromBody] ListeningItem item)
        {
            var existing = await _context.ListeningItems.FindAsync(id);
            if (existing == null) return NotFound(new { message = "Không tìm thấy bài nghe." });

            existing.AudioUrl = item.AudioUrl;
            existing.Transcript = item.Transcript;

            await _context.SaveChangesAsync();
            return Ok(new { message = "Cập nhật bài nghe thành công!", data = existing });
        }

        [HttpDelete("listening-item/{id}")]
        public async Task<IActionResult> DeleteListeningItem(int id)
        {
            var item = await _context.ListeningItems.FindAsync(id);
            if (item == null) return NotFound(new { message = "Không tìm thấy bài nghe cần xóa." });

            _context.ListeningItems.Remove(item);
            await _context.SaveChangesAsync();
            return Ok(new { message = "✅ Đã xóa bài nghe thành công!" });
        }
    }
}