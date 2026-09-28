namespace WebApplication1.DTOs
{
    public class QuestionCreateDto
    {
        public string QuestionText { get; set; } = string.Empty;
        public List<string> Options { get; set; } = new();
        public int CorrectAnswerIndex { get; set; }
    }
}
