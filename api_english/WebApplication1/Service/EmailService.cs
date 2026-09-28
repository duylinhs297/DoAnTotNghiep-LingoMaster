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
    }
}