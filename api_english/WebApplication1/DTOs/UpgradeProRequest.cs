namespace WebApplication1.DTOs
{
    public class UpgradeProRequest
    {
        public int UserId { get; set; }
        public string PlanTitle { get; set; } = string.Empty; // "Gói 1 Tháng" hoặc "Gói Trọn Đời (PRO)"
        public string PaymentMethod { get; set; } = "MoMo";
    }
}
