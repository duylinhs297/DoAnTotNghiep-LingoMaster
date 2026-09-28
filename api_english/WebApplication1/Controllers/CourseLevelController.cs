using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WebApplication1.Data; // Thay bằng DbContext của bạn
using WebApplication1.Models;

namespace WebApplication1.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class CourseLevelController : ControllerBase
    {
        private readonly AppDbContext _context;

        public CourseLevelController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/CourseLevel
        [HttpGet]
        public async Task<ActionResult<IEnumerable<CourseLevel>>> GetCourseLevels()
        {
            return await _context.CourseLevels
                .OrderBy(l => l.Order)
                .ToListAsync();
        }

        // GET: api/CourseLevel/5
        [HttpGet("{id}")]
        public async Task<ActionResult<CourseLevel>> GetCourseLevel(int id)
        {
            var courseLevel = await _context.CourseLevels.FindAsync(id);

            if (courseLevel == null)
            {
                return NotFound(new { message = "Không tìm thấy cấp độ này" });
            }

            return courseLevel;
        }

        // POST: api/CourseLevel
        [HttpPost]
        public async Task<ActionResult<CourseLevel>> PostCourseLevel(CourseLevel courseLevel)
        {
            _context.CourseLevels.Add(courseLevel);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetCourseLevel), new { id = courseLevel.Id }, courseLevel);
        }
    }
}