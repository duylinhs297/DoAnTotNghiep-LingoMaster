using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace WebApplication1.Models
{
    public class CourseCategory
    {
        public int Id { get; set; }
        public int LevelId { get; set; } // Thuộc Sơ cấp, Trung cấp hay Cao cấp

        public string SkillType { get; set; } = "VOCAB";
        // Các loại SkillType: VOCAB (Từ vựng), SPEAKING (Phát âm AI), REVIEW (Ôn tập), QUIZ (Trắc nghiệm), LISTENING (Luyện nghe)
        [ForeignKey("LevelId")]
        public CourseLevel? Level { get; set; }
        public string Name { get; set; } = string.Empty; // Ví dụ: Kho chủ đề Từ vựng cơ bản, Kho bài hội thoại AI...
        public string Description { get; set; } = string.Empty;
        [JsonIgnore]
        public ICollection<CourseTopic>? Topics { get; set; }
    }
}
