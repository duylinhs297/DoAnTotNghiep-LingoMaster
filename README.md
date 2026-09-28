# 📚 ĐỒ ÁN HỆ THỐNG HỌC TIẾNG ANH (LingoMaster)

Dự án bao gồm 3 thành phần chính:
1. **Backend API**: Xây dựng bằng C# (.NET) kết nối cơ sở dữ liệu PostgreSQL.
2. **Admin Web**: Giao diện quản trị xây dựng bằng ReactJS, TailwindCSS[cite: 22], Vite[cite: 22].
3. **Mobile App**: Ứng dụng di động đa nền tảng xây dựng bằng Flutter (Dart).

---

## 🛠️ YÊU CẦU HỆ THỐNG TRƯỚC KHI CÀI ĐẶT
Trước khi bắt đầu, hãy đảm bảo máy tính của bạn đã được cài đặt sẵn các công cụ sau:
- **Node.js** (phiên bản LTS khuyến nghị) và npm.
- **.NET SDK** (phiên bản tương thích với dự án .NET mới nhất).
- **PostgreSQL** và công cụ quản lý **pgAdmin**.
- **Flutter SDK** kết hợp với Android Studio hoặc VS Code (để chạy app mobile).

---

## 📂 CẤU TRÚC THƯ MỤC DỰ ÁN
```text
Project4/
├── api_english/       # Source code C# Web API (.NET)
├── english_app/          # Source code Admin Web (ReactJS + Vite)
├── lingomaster-app/       # Source code App Mobile (Flutter)
├── database_postgresql/             # Chứa file backup cơ sở dữ liệu PostgreSQL (.sql)
└── README.md             # Hướng dẫn cài đặt hệ thống
⚙️ HƯỚNG DẪN CÀI ĐẶT CHI TIẾT TỪNG THÀNH PHẦN

Bước 1: Khôi phục Cơ sở dữ liệu (Database PostgreSQL)Mở pgAdmin trên máy của bạn và kết nối tới máy chủ PostgreSQL cục bộ.Tạo một Database mới (ví dụ đặt tên: lingomaster_db).Nhấp chuột phải vào database vừa tạo $\rightarrow$ Chọn Restore...Tại ô Filename, trỏ đường dẫn đến file backup nằm trong thư mục dự án: database/database_backup.sql.Nhấn Restore để nạp toàn bộ cấu trúc bảng và dữ liệu mẫu vào hệ thống.

Bước 2: Chạy Backend C# Web APIMở thư mục api_english bằng Visual Studio hoặc VS Code[cite: 21].Mở file cấu hình kết nối (ví dụ: appsettings.json hoặc appsettings.Development.json).Cập nhật lại chuỗi kết nối cơ sở dữ liệu (ConnectionStrings) sao cho khớp với tên database, tài khoản và mật khẩu PostgreSQL của máy bạn:JSON"ConnectionStrings": {
  "DefaultConnection": "Host=localhost;Port=5432;Database=lingomaster_db;Username=postgres;Password=matkhau_cua_ban"
}
Mở Terminal tại thư mục chứa dự án C# và chạy lệnh khởi động API:Bash dotnet run
Mặc định API sẽ chạy tại địa chỉ dạng: http://localhost:5208  port này để cấu hình cho Admin là ví dụ http://localhost:5173/admin và App ví dụ là http://10.0.2.2:5208/api.

Bước 3: Chạy Admin Web (ReactJS)Mở terminal tại thư mục chứa mã nguồn giao diện admin (admin-react)[cite: 22].Cài đặt các gói thư viện phụ thuộc bằng lệnh:Bash npm install
Kiểm tra file cấu hình kết nối API trong code React (thường nằm ở các file service hoặc file biến môi trường .env) để đảm bảo địa chỉ URL đang trỏ đúng vào cổng của Backend C# ở Bước 2.Chạy môi trường phát triển (Development):Bash npm run dev
Mở trình duyệt web và truy cập theo đường dẫn mà terminal cung cấp http://localhost:5173/admin/auth để đăng nhập vào trang quản trị Admin.

Bước 4: Chạy Ứng Dụng Mobile (Flutter)Mở thư mục mobile-flutter bằng VS Code hoặc Android Studio.Kiểm tra file pubspec.yaml với các thư viện đã được cấu hình sẵn (shared_preferences, http, flutter_tts, qr_flutter, v.v.).Mở file cấu hình gọi API trong mã nguồn Flutter (ví dụ: UserApiService.baseUrl), chỉnh sửa lại địa chỉ IP cho khớp với Backend:Nếu chạy trên Máy ảo Android (Emulator): Dùng http://10.0.2.2:5208/api:<port_csharp> Tải về các gói thư viện Flutter bằng lệnh:Bash flutter pub get
Kết nối thiết bị (Máy ảo hoặc Điện thoại thật có bật chế độ gỡ lỗi USB) và chạy ứng dụng:Bash flutter run và nếu không mở được mic thì chọc dấu 3 chấm dọc ở trên máy ảo chọn vào đó. Tìm tới Microphone và ở dưới Microphone có Enable Host Microphone Access clich vào xanh để có thể nói chuyện 

Chúc hội đồng chấm đồ án đánh giá sản phẩm thuận lợi!