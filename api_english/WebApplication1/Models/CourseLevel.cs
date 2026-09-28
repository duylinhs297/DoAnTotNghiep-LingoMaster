using System.Text.Json.Serialization;

namespace WebApplication1.Models
{
    public class CourseLevel
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty; // Sơ cấp, Trung cấp, Cao cấp
        public int Order { get; set; }
        [JsonIgnore]
        public ICollection<CourseCategory>? Categories { get; set; }
    }
}
