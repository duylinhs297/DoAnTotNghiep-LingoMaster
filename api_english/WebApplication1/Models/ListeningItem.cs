using System.ComponentModel.DataAnnotations.Schema;

namespace WebApplication1.Models
{
    public class ListeningItem
    {
        public int Id { get; set; }
        public int TopicId { get; set; }
        [ForeignKey("TopicId")]
        public CourseTopic? Topic { get; set; }

        public string AudioUrl { get; set; } = string.Empty;
        public string Transcript { get; set; } = string.Empty; // "Phần hiển thị nội dung chi tiết..."
    }
}
