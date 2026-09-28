namespace WebApplication1.Models
{
    public class BattleStage
    {
        public string Id { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string Subtitle { get; set; } = string.Empty;
        public int QuestionsCount { get; set; } = 40;
        public string TimeLimit { get; set; } = "15 phút";
        public string ColorHex { get; set; } = "#3B82F6";
        public List<BattleQuestion> Questions { get; set; } = new();
    }
}
