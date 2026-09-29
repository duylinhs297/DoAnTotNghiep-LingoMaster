using System.Net;
using System.Net.Mail;

namespace WebApplication1.Service
{
    public class EmailService
    {
        private readonly IConfiguration _config;

        public EmailService(IConfiguration config)
        {
            _config = config;
        }

        public async Task SendOtpEmailAsync(string toEmail, string otpCode, string purpose)
        {
            var smtpHost = _config["SmtpSettings:Host"];
            var smtpPort = int.Parse(_config["SmtpSettings:Port"] ?? "587");
            var senderEmail = _config["SmtpSettings:SenderEmail"];
            var senderName = _config["SmtpSettings:SenderName"];
            var password = _config["SmtpSettings:Password"];

            using (var message = new MailMessage())
            {
                message.From = new MailAddress(senderEmail!, senderName);
                message.To.Add(new MailAddress(toEmail));
                message.Subject = $"[{purpose}] Mã xác thực OTP của bạn";
                message.Body = $@"
                    <div style='font-family: Arial, sans-serif; padding: 20px;'>
                        <h2>Xác thực bảo mật 2 bước</h2>
                        <p>Mã OTP của bạn cho mục đích <b>{purpose}</b> là:</p>
                        <h1 style='color: #4F46E5; letter-spacing: 4px;'>{otpCode}</h1>
                        <p>Mã này có hiệu lực trong <b>5 phút</b>. Vui lòng không chia sẻ mã này với bất kỳ ai.</p>
                    </div>";
                message.IsBodyHtml = true;

                using (var client = new SmtpClient(smtpHost, smtpPort))
                {
                    client.Credentials = new NetworkCredential(senderEmail, password);
                    client.EnableSsl = true; // Bắt buộc đối với Gmail Port 587

                    await client.SendMailAsync(message);
                }
            }
        }
        public async Task SendProInvoiceEmailAsync(string toEmail, string planTitle, long amount, int orderCode)
        {
            var smtpHost = _config["SmtpSettings:Host"];
            var smtpPort = int.Parse(_config["SmtpSettings:Port"] ?? "587");
            var senderEmail = _config["SmtpSettings:SenderEmail"];
            var senderName = _config["SmtpSettings:SenderName"];
            var password = _config["SmtpSettings:Password"];

            using (var message = new MailMessage())
            {
                message.From = new MailAddress(senderEmail!, senderName);
                message.To.Add(new MailAddress(toEmail));
                message.Subject = "[LingoMaster] Hóa đơn xác nhận nâng cấp tài khoản PRO thành công!";

                message.Body = $@"
                    <div style='font-family: Arial, sans-serif; padding: 20px; max-width: 600px; margin: auto; border: 1px solid #e2e8f0; border-radius: 8px;'>
                        <h2 style='color: #4F46E5; text-align: center;'>Cảm ơn bạn đã nâng cấp tài khoản!</h2>
                        <p>Xin chào bạn,</p>
                        <p>Giao dịch thanh toán mua gói học tập của bạn tại <b>LingoMaster</b> đã được xử lý thành công.</p>
                        <hr style='border: none; border-top: 1px solid #e2e8f0;'/>
                        <h3>Chi tiết hóa đơn:</h3>
                        <ul>
                            <li><b>Mã đơn hàng:</b> #{orderCode}</li>
                            <li><b>Gói dịch vụ:</b> {planTitle}</li>
                            <li><b>Số tiền thanh toán:</b> {amount:#,0} VNĐ</li>
                            <li><b>Thời gian giao dịch:</b> {DateTime.UtcNow.AddHours(7):dd/MM/yyyy HH:mm:ss}</li>
                        </ul>
                        <p style='color: #059669; font-weight: bold;'>Tài khoản của bạn đã được kích hoạt thành công quyền lợi PRO. Chúc bạn có những trải nghiệm học tập tuyệt vời!</p>
                        <p style='font-size: 12px; color: #64748b; text-align: center; margin-top: 30px;'>Đây là email tự động, vui lòng không phản hồi.</p>
                    </div>";
                message.IsBodyHtml = true;

                using (var client = new SmtpClient(smtpHost, smtpPort))
                {
                    client.Credentials = new NetworkCredential(senderEmail, password);
                    client.EnableSsl = true;

                    await client.SendMailAsync(message);
                }
            }
        }
    }
}