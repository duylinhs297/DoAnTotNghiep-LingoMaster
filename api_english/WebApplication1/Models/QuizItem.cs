using System.ComponentModel.DataAnnotations.Schema;

namespace WebApplication1.Models
{
    public class QuizItem
    {
        public int Id { get; set; }
        public int TopicId { get; set; }
        [ForeignKey("TopicId")]
        public CourseTopic? Topic { get; set; }

        public string Question { get; set; } = string.Empty;   // "Từ nào đồng nghĩa với..."
        public string OptionA { get; set; } = string.Empty;    // "Competitor"
        public string OptionB { get; set; } = string.Empty;    // "Cooperate"
        public string OptionC { get; set; } = string.Empty;    // "Conflict"
        public string OptionD { get; set; } = string.Empty;    // "Control"
        public string CorrectOption { get; set; } = string.Empty; // "B"
    }
}
