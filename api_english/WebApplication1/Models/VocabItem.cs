using System.ComponentModel.DataAnnotations.Schema;

namespace WebApplication1.Models
{
    public class VocabItem
    {
        public int Id { get; set; }
        public int TopicId { get; set; }
        [ForeignKey("TopicId")]
        public CourseTopic? Topic { get; set; }

        public string Word { get; set; } = string.Empty;       // "Hello / Greeting"
        public string Phonetic { get; set; } = string.Empty;   // "/həˈloʊ/"
        public string Meaning { get; set; } = string.Empty;    // "Xin chào..."
        public string Example { get; set; } = string.Empty;    // "Hello, nice to meet you!"
    }
}
