using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WebApplication1.Data;
using WebApplication1.Models;

namespace WebApplication1.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class VocabItemController : ControllerBase
    {
        private readonly AppDbContext _context;

        public VocabItemController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/VocabItem/topic/1
        [HttpGet("topic/{topicId}")]
        public async Task<ActionResult<IEnumerable<VocabItem>>> GetVocabItemsByTopic(int topicId)
        {
            Console.WriteLine($"===> Đang gọi API lấy từ vựng với TopicId = {topicId}");

            var items = await _context.VocabItems
                .Where(v => v.TopicId == topicId)
                .ToListAsync();

            Console.WriteLine($"===> Tìm thấy {items.Count} từ vựng.");
            return items;
        }

        // GET: api/VocabItem/5
        [HttpGet("{id}")]
        public async Task<ActionResult<VocabItem>> GetVocabItem(int id)
        {
            var vocabItem = await _context.VocabItems.FindAsync(id);

            if (vocabItem == null)
            {
                return NotFound(new { message = "Không tìm thấy từ vựng" });
            }

            return vocabItem;
        }

        // POST: api/VocabItem
        [HttpPost]
        public async Task<ActionResult<VocabItem>> PostVocabItem(VocabItem vocabItem)
        {
            _context.VocabItems.Add(vocabItem);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetVocabItem), new { id = vocabItem.Id }, vocabItem);
        }
    }
}