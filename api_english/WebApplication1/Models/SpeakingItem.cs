using System.ComponentModel.DataAnnotations.Schema;

namespace WebApplication1.Models
{
    public class SpeakingItem
    {
        public int Id { get; set; }
        public int TopicId { get; set; }
        [ForeignKey("TopicId")]
        public CourseTopic? Topic { get; set; }

        public string Sentence { get; set; } = string.Empty;   // "It is wonderful to see you..."
        public string Translation { get; set; } = string.Empty;// "Thật tuyệt vời..."
        public string Phonetic { get; set; } = string.Empty;   // "/ɪt ɪz 'wʌn.dər.fəl.../"
        public string AudioUrl { get; set; } = string.Empty;
    }
}
