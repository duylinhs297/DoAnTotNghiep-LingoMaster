using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json;

namespace WebApplication1.Models
{
    public class BattleQuestion
    {
        [Key]
        public int Id { get; set; }

        public string BattleStageId { get; set; } = string.Empty;

        [ForeignKey("BattleStageId")]
        public BattleStage? BattleStage { get; set; }

        public int QuestionIndex { get; set; }
        public string QuestionText { get; set; } = string.Empty;

        // Lưu danh sách options dưới dạng chuỗi JSON trong CSDL quan hệ thông thường
        public string OptionsJson { get; set; } = "[]";

        [NotMapped]
        public List<string> Options
        {
            get => string.IsNullOrEmpty(OptionsJson) ? new List<string>() : JsonSerializer.Deserialize<List<string>>(OptionsJson) ?? new List<string>();
            set => OptionsJson = JsonSerializer.Serialize(value);
        }

        public int CorrectAnswerIndex { get; set; }
    }
}