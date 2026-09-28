using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WebApplication1.Data; // Đổi namespace phù hợp với DbContext của bạn
using WebApplication1.Models;

namespace WebApplication1.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class QuizItemController : ControllerBase
    {
        private readonly AppDbContext _context; // Đổi tên DbContext nếu project bạn khác

        public QuizItemController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/QuizItem/topic/{topicId}
        [HttpGet("topic/{topicId}")]
        public async Task<ActionResult<IEnumerable<QuizItem>>> GetQuizItemsByTopic(int topicId)
        {
            try
            {
                var items = await _context.QuizItems
                    .Where(q => q.TopicId == topicId)
                    .ToListAsync();

                return Ok(items);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi lấy danh sách câu hỏi trắc nghiệm", error = ex.Message });
            }
        }
        [HttpGet("topic-detail/{topicId}")]
        public async Task<IActionResult> GetQuizDetailByTopic(int topicId)
        {
            var topic = await _context.CourseTopics.FindAsync(topicId);
            if (topic == null) return NotFound(new { message = "Không tìm thấy chủ đề" });

            var items = await _context.QuizItems
                .Where(q => q.TopicId == topicId)
                .ToListAsync();

            return Ok(new
            {
                topicId = topic.Id,
                topicTitle = topic.Title,
                timeLimitSeconds = topic.TimeLimitSeconds, // Lấy từ CourseTopic
                items = items
            });
        }
    }
}