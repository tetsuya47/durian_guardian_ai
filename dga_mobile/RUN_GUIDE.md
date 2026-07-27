# Hướng Dẫn Khởi Chạy Dự Án — Durian Guardian AI (Hapii Green)

Tài liệu này hướng dẫn cách chuẩn bị môi trường và các bước khởi chạy dự án Durian Guardian AI (bao gồm Backend FastAPI và Mobile App Flutter) trên máy tính của bạn.

---

## 1. Yêu Cầu Cài Đặt Môi Trường (Chỉ cần làm lần đầu)

Để dự án hoạt động, máy tính của bạn cần cài đặt các công cụ sau:

### Cho Mobile App (Flutter)
1. **Flutter SDK**: Phiên bản **3.19.x** trở lên (Stable).
   * Tải từ trang chủ Flutter, giải nén và thêm đường dẫn thư mục `flutter/bin` vào biến môi trường **PATH** của Windows.
2. **Java Development Kit (JDK)**: Khuyên dùng **JDK 17** (tương thích tốt với Gradle của dự án).
3. **Android SDK & Command-line Tools**:
   * Cần có để biên dịch sang Android. Có thể cấu hình thông qua Android Studio hoặc tải bộ SDK rời.
4. **Kiểm tra**: Chạy lệnh `flutter doctor` trong Terminal để chắc chắn môi trường Flutter sẵn sàng.

### Cho Backend & Database
1. **Python 3.12**:
   * *Lưu ý*: Tránh dùng Python 3.14 (bản thử nghiệm) vì các thư viện như `pydantic-core` viết bằng Rust chưa tương thích và sẽ gây lỗi biên dịch.
2. **MongoDB Community Server (v7.0+)**:
   * Chạy local ở cổng mặc định `27017` để lưu trữ dữ liệu.
   * Khuyên dùng thêm công cụ **MongoDB Compass** để quản lý dữ liệu trực quan.

---

## 2. Quy Trình Khởi Chạy Dự Án Chuẩn (Cho các lần phát triển sau)

Khi môi trường đã được cài đặt và nạp dữ liệu thành công, mỗi lần khởi động để lập trình, bạn thực hiện theo các bước sau:

### Bước 1: Kiểm tra IP máy tính (Chỉ khi dùng điện thoại thật)
Do Router Wi-Fi thường cấp phát địa chỉ IP động (DHCP), IP nội bộ (LAN) của máy tính có thể bị thay đổi.
1. Mở Terminal (PowerShell/cmd) trên máy tính gõ:
   ```powershell
   ipconfig
   ```
2. Tìm card mạng Wi-Fi và xem dòng `IPv4 Address` (ví dụ: `192.168.1.15`).
3. Mở file `dga_mobile/lib/core/network/environment_config.dart` bằng VS Code.
4. Thay đổi giá trị IP ở dòng 18 trùng với IP máy tính của bạn:
   ```dart
   static const String deviceHost = '172.16.30.85'; // IP máy tính của bạn
   ```

### Bước 2: Khởi chạy API Backend
1. Mở Terminal tại thư mục gốc của dự án.
2. Kích hoạt môi trường ảo Python 3.12 và khởi động backend:
   ```powershell
   # Kích hoạt venv
   backend\venv\Scripts\activate
   
   # Khởi chạy server
   python backend/run.py
   ```
   *(Terminal này cần được giữ mở để server backend duy trì hoạt động).*

### Bước 3: Khởi chạy ứng dụng di động (Flutter)
1. Cắm điện thoại Android thật vào máy tính bằng cáp USB (Đảm bảo đã bật **Gỡ lỗi USB - USB Debugging** trong Tùy chọn nhà phát triển trên điện thoại và kết nối chung một mạng Wi-Fi với máy tính).
2. Mở một cửa sổ Terminal mới (cửa sổ thứ hai).
3. Chuyển vào thư mục di động và khởi chạy:
   ```powershell
   cd dga_mobile
   flutter run
   ```
4. Hệ thống sẽ biên dịch ứng dụng và cài đặt trực tiếp lên điện thoại của bạn.

---

## 3. Các Phím Tắt Tiện Ích Khi Dev (Trên Terminal chạy Mobile)

Trong quá trình thay đổi mã nguồn Flutter, tại terminal chạy app di động, bạn có thể nhấn:
* **`r`** (Hot Reload): Cập nhật giao diện lập tức lên điện thoại trong vòng dưới 1 giây mà không mất trạng thái ứng dụng.
* **`R`** (Hot Restart): Khởi động lại ứng dụng di động từ đầu.
* **`q`**: Dừng chạy ứng dụng và ngắt kết nối.

---

## 4. Hướng Dẫn Khởi Chạy Bản Web (Vite + React + TypeScript)

Bản Web Dashboard dành cho nhà quản trị được đặt trong thư mục `frontend/`. Do chạy trực tiếp trên máy tính local, bản web sẽ tự động kết nối tới backend tại `http://localhost:8000` mà không cần cấu hình IP Wi-Fi LAN.

1. **Yêu cầu**: Máy tính đã cài đặt **Node.js** (đã có sẵn trên máy của bạn).
2. **Khởi chạy**:
   Mở một Terminal mới và chạy các lệnh sau:
   ```powershell
   # 1. Di chuyển vào thư mục frontend
   cd frontend

   # 2. Cài đặt các package (Chỉ cần chạy lần đầu)
   npm install

   # 3. Khởi chạy web ở chế độ phát triển
   npm run dev
   ```
3. **Truy cập**: 
   Mở trình duyệt truy cập địa chỉ hiển thị trên terminal (mặc định là `http://localhost:5173`).

---

## 5. Tài Khoản Đăng Nhập Demo Mặc Định

Bạn có thể đăng nhập cả bản Web và bản Mobile bằng các tài khoản demo đã được nạp (seed) trong cơ sở dữ liệu:

* **Tài khoản Demo (Quyền Admin nông trại)**:
  * **Email**: `bao@gmail.com`
  * **Mật khẩu**: `123456`
* **Tài khoản Enterprise Admin (Toàn quyền hệ thống)**:
  * **Email**: `admin@durian.ai`
  * **Mật khẩu**: `admin123`




Ran command: `ipconfig`
Edited environment_config.dart

Chào bạn! Dưới đây là câu trả lời chi tiết cho 4 câu hỏi của bạn:

---

### 1. App đã kết nối được với backend chưa?
**Đã kết nối hoàn toàn**. Cả Mobile App và Backend đều được lập trình sẵn kết nối qua API HTTP thật (sử dụng thư viện `Dio` ở điện thoại gọi tới `FastAPI` ở máy tính).
* **Cập nhật IP mới nhất**: Do IP Wi-Fi trên máy tính của bạn hôm nay đã đổi thành **`192.168.1.12`** (hôm trước là `172.16.30.85`), nên tôi đã tự động sửa lại IP này trong file cấu hình [environment_config.dart](file:///d:/Code/Ai_For_Life/durian_guardian_ai/dga_mobile/lib/core/network/environment_config.dart) giúp bạn.
* **Lưu ý**: Bạn chỉ cần cắm điện thoại Android và đảm bảo **điện thoại kết nối cùng một mạng Wi-Fi** với máy tính là app sẽ tự động kết nối được ngay.

---

### 2. Hoạt động tốt chưa?
* **Phần Đăng nhập, Đăng ký, Lịch sử, Dashboard**: Hoạt động tốt và kết nối trực tiếp với database MongoDB của bạn.
* **Phần Chẩn đoán hình ảnh (AI)**: Hiện tại backend đang chạy ở chế độ **Mock (giả lập kết quả chẩn đoán ngẫu nhiên)** để phục vụ việc kiểm thử nhanh mà không cần load các file mô hình PyTorch nặng nề. Sau này để chạy chẩn đoán thật bằng AI, bạn cần tích hợp logic load model thật tại file [service.py](file:///d:/Code/Ai_For_Life/durian_guardian_ai/backend/app/ai/service.py).

---

### 3. Có thể chạy được bản web không?
**Hoàn toàn chạy được luôn**. Máy tính của bạn đã được cài sẵn Node.js và quản lý gói `npm` (phiên bản 11.6.4). Do bản Web chạy trực tiếp trên trình duyệt máy tính nên nó sẽ kết nối thẳng vào backend qua địa chỉ `http://localhost:8000` mà bạn không cần phải cấu hình IP Wi-Fi phức tạp như trên điện thoại.

-------------------------------------------------------




Các bước khởi chạy hoàn toàn từ đầu tất cả dịch vụ (Backend, Web, Mobile)

Mỗi khi bạn bật máy tính lên và muốn chạy toàn bộ hệ thống từ đầu, hãy mở các cửa sổ Terminal riêng biệt và thực hiện lần lượt các bước sau:

#### Bước 1: Đảm bảo Database (MongoDB) đã chạy
Thông thường MongoDB tự động chạy ngầm trên Windows. Nếu muốn chắc chắn, bạn mở cmd bằng quyền **Administrator** (chuột phải chọn Run as Administrator) rồi gõ:
```powershell
net start MongoDB
```

#### Bước 2: Chạy API Backend (Terminal 1)
Mở cửa sổ Terminal thứ nhất tại thư mục dự án `durian_guardian_ai` và gõ:
```powershell
# 1. Kích hoạt môi trường ảo Python 3.12 (đã tạo)
backend\venv\Scripts\activate

# 2. Khởi chạy server backend
python backend/run.py
```
*(Giữ nguyên Terminal này để server backend duy trì hoạt động ở cổng 8000).*

#### Bước 3: Chạy ứng dụng Web Dashboard (Terminal 2)
Mở cửa sổ Terminal thứ hai và gõ:
```powershell
# 1. Chuyển vào thư mục frontend
cd frontend

# 2. Cài đặt các thư viện (Chỉ cần chạy ở lần đầu tiên)
npm install

# 3. Khởi chạy web
npm run dev
```
*Trình duyệt sẽ tự động mở trang web tại địa chỉ `http://localhost:5173`.*

#### Bước 4: Chạy ứng dụng di động Android (Terminal 3)
1. Kiểm tra lại địa chỉ IP Wi-Fi của máy tính bằng cách gõ `ipconfig` (ví dụ hiện tại là `192.168.1.12`).
2. Mở file [environment_config.dart](file:///d:/Code/Ai_For_Life/durian_guardian_ai/dga_mobile/lib/core/network/environment_config.dart), sửa dòng 18 trùng với IP máy tính của bạn:
   ```dart
   static const String deviceHost = '192.168.1.12';
   ```
3. Cắm điện thoại (đã bật USB Debugging và kết nối chung Wi-Fi), mở terminal thứ ba tại thư mục `dga_mobile/` và gõ:
   ```powershell
   flutter run
   ```

*Bạn có thể đăng nhập cả bản Web và bản Mobile bằng tài khoản demo sau để kiểm tra:*
* **Email**: `bao@gmail.com`
* **Mật khẩu**: `123456`