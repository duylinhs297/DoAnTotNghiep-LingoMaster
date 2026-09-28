using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WebApplication1.Data; // Thay bằng Namespace DbContext của bạn
using WebApplication1.Models;

namespace WebApplication1.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class SpeakingItemController : ControllerBase
    {
        private readonly AppDbContext _context;

        public SpeakingItemController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/SpeakingItem/topic/5
        [HttpGet("topic/{topicId}")]
        public async Task<IActionResult> GetByTopic(int topicId)
        {
            var items = await _context.SpeakingItems
                .Where(x => x.TopicId == topicId)
                .Select(x => new
                {
                    x.Id,
                    x.TopicId,
                    x.Sentence,
                    x.Translation,
                    x.Phonetic,
                    x.AudioUrl
                })
                .ToListAsync();

            return Ok(items);
        }
    }
}