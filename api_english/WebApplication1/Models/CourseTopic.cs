using System.ComponentModel.DataAnnotations.Schema;

namespace WebApplication1.Models
{
    public class CourseTopic
    {
        public int Id { get; set; }
        public int CategoryId { get; set; } // Thuộc Danh mục nào
        [ForeignKey("CategoryId")]
        public CourseCategory? Category { get; set; }
        public string Title { get; set; } = string.Empty; // Ví dụ: Giao tiếp hàng ngày, Đời sống & Mua sắm
        public string Subtitle { get; set; } = string.Empty;
        public string CategoryKey { get; set; } = string.Empty; // GiaoTiepHangNgay, MuaSam...
        public int ItemCount { get; set; } = 0; // Số câu/Số từ vựng trong bài
        public int TimeLimitSeconds { get; set; } = 0;
    }
}
