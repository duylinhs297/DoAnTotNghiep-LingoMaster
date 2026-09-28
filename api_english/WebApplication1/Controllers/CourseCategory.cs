using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WebApplication1.Data;
using WebApplication1.Models;

namespace WebApplication1.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class CourseCategoryController : ControllerBase
    {
        private readonly AppDbContext _context;

        public CourseCategoryController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/CourseCategory?levelName=Sơ cấp&skillType=VOCAB
        [HttpGet]
        public async Task<ActionResult<IEnumerable<CourseCategory>>> GetCategories(
            [FromQuery] string? levelName,
            [FromQuery] string? skillType)
        {
            var query = _context.CourseCategories
                .Include(c => c.Level)
                .AsQueryable();

            if (!string.IsNullOrEmpty(levelName))
            {
                query = query.Where(c => c.Level != null && c.Level.Name.ToLower() == levelName.ToLower());
            }

            if (!string.IsNullOrEmpty(skillType))
            {
                query = query.Where(c => c.SkillType.ToUpper() == skillType.ToUpper());
            }

            return await query.ToListAsync();
        }

        // GET: api/CourseCategory/level/1
        [HttpGet("level/{levelId}")]
        public async Task<ActionResult<IEnumerable<CourseCategory>>> GetCategoriesByLevel(int levelId)
        {
            return await _context.CourseCategories
                .Where(c => c.LevelId == levelId)
                .ToListAsync();
        }

        // POST: api/CourseCategory
        [HttpPost]
        public async Task<ActionResult<CourseCategory>> PostCourseCategory(CourseCategory category)
        {
            _context.CourseCategories.Add(category);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetCategories), new { id = category.Id }, category);
        }
    }
}