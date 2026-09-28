using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WebApplication1.Data;
using WebApplication1.Models;

namespace WebApplication1.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class FlashcardItemController : ControllerBase
    {
        private readonly AppDbContext _context;

        public FlashcardItemController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/FlashcardItem/topic/{topicId}
        [HttpGet("topic/{topicId}")]
        public async Task<ActionResult<IEnumerable<object>>> GetFlashcardsByTopic(int topicId)
        {
            // Thử query theo TopicId trước
            var items = await _context.VocabItems
                .Where(v => v.TopicId == topicId)
                .Select(v => new
                {
                    word = v.Word,
                    phonetic = v.Phonetic ?? "/.../",
                    meaning = v.Meaning
                })
                .ToListAsync();

            // Nếu vẫn rỗng, thử query rộng hơn hoặc fallback đúng nghĩa theo DB của bạn
            if (items == null || !items.Any())
            {
                // Debug thử xem có bản ghi nào trong VocabItems không hoặc lấy top theo category nếu cần
                return Ok(new List<object>()); // Trả rỗng để Flutter tự fallback hoặc kiểm tra lại DB seed
            }

            return Ok(items);
        }
    }
}