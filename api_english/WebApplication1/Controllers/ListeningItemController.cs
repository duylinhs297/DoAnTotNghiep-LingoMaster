using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WebApplication1.Data;

namespace WebApplication1.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ListeningItemController : ControllerBase
    {
        private readonly AppDbContext _context;

        public ListeningItemController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/ListeningItem/topic/{topicId}
        [HttpGet("topic/{topicId}")]
        public async Task<IActionResult> GetListeningItemsByTopic(int topicId)
        {
            try
            {
                var items = await _context.ListeningItems
                    .Where(x => x.TopicId == topicId)
                    .ToListAsync();
                return Ok(items);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi lấy danh sách bài nghe", detail = ex.Message });
            }
        }
    }
}