# Hướng Dẫn Chạy Dự Án Durian Guardian AI Hoàn Toàn Từ Đầu Trên Máy Mới

Tài liệu này hướng dẫn chi tiết các bước thiết lập môi trường, nạp cơ sở dữ liệu lên **MongoDB Atlas**, cấu hình đường hầm **ngrok** và chạy/build cả hai đầu Backend (FastAPI) và Frontend (Vite/React) trên một máy tính hoàn toàn mới.

---

## 📌 Yêu Cầu Cài Đặt Ban Đầu (Prerequisites)
1. **Python**: Tải và cài đặt [Python 3.10 - 3.12](https://www.python.org/downloads/).
   > [!IMPORTANT]
   > Khi cài đặt trên Windows, hãy tích chọn **"Add Python to PATH"** ở màn hình đầu tiên để có thể chạy lệnh từ CMD/Powershell.
2. **Node.js**: Tải và cài đặt [Node.js LTS](https://nodejs.org/).
3. **ngrok**: Đăng ký một tài khoản miễn phí tại [ngrok.com](https://ngrok.com/) và làm theo hướng dẫn để xác thực (auth token) trên máy mới.

---

## 🗄️ BƯỚC 1: Khởi Tạo & Nạp Cơ Sở Dữ Liệu (Database Setup)
Thao tác tại **Thư mục gốc** của dự án (`durian_guardian_ai`):

1. **Cài đặt thư viện Python chung**:
   ```bash
   pip install -r requirements.txt
   ```
2. **Cấu hình kết nối**:
   Mở file `database/config.py` và kiểm tra giá trị mặc định của `MONGODB_URI` và `DATABASE_NAME` để chắc chắn chúng đang trỏ đúng tới cụm cơ sở dữ liệu MongoDB Atlas đám mây của bạn.
3. **Chạy lệnh nạp dữ liệu từ CSV**:
   ```bash
   python -m database.setup_database --drop-existing
   ```
   *Hệ thống đã được tối ưu hóa luồng ghi bulk-write, sẽ tự động xóa sạch DB cũ, thiết lập cấu trúc Schema Validation/Index mới và nạp toàn bộ 10,000 dòng dữ liệu mẫu chỉ trong vòng ~30 giây.*

---

## 💻 BƯỚC 2: Cài Đặt & Chạy Backend (FastAPI)
Di chuyển vào thư mục backend: `cd backend`

1. **Tạo môi trường ảo (Virtual Environment)**:
   ```bash
   python -m venv venv
   ```
2. **Kích hoạt môi trường ảo**:
   * **Trên Windows**:
     ```bash
     .\venv\Scripts\activate
     ```
   * **Trên macOS / Linux**:
     ```bash
     source venv/bin/activate
     ```
3. **Cài đặt các thư viện phụ thuộc cho Backend**:
   ```bash
   pip install -r requirements.txt
   ```
4. **Cấu hình file môi trường `.env`**:
   Tạo mới một file đặt tên là `.env` nằm trực tiếp trong thư mục `backend/` với nội dung cấu hình kết nối database như sau:
   ```env
   MONGODB_URL=mongodb+srv://sanghoanga8_db_user:9390PahlsR5J2d8X@durianguardianai.72acfra.mongodb.net/?appName=DurianGuardianAI
   MONGODB_DB_NAME=durian_guardian_ai
   CORS_ORIGINS=*
   ```
5. **Khởi chạy Backend Server**:
   ```bash
   python run_server.py
   ```
   *Lưu ý: File `run_server.py` đã được tích hợp đoạn sửa lỗi Socket Error trên Windows.*
   *Backend sẽ khởi động thành công và chạy tại cổng local: `http://localhost:8000`*

---

## 🌐 BƯỚC 3: Mở Cổng ngrok (Public API)
Mở một cửa sổ Terminal mới trên máy của bạn (không tắt cửa sổ chạy backend ở bước 2):

1. **Chạy lệnh mở cổng chuyển tiếp**:
   ```bash
   ngrok http 8000
   ```
2. **Lấy địa chỉ công khai**:
   Sao chép địa chỉ URL ngrok được cấp tại dòng `Forwarding` (có định dạng tương tự như: `https://xxxx-xxxx-xxxx.ngrok-free.app`).

---

## 🎨 BƯỚC 4: Cấu Hình & Chạy/Build Frontend (Vite/React)
Di chuyển vào thư mục frontend: `cd ../frontend`

1. **Cài đặt thư viện Node.js**:
   ```bash
   npm install
   ```
2. **Cập nhật địa chỉ API kết nối**:
   * **Nếu chạy local (Development)**: Tạo file `.env.local` ở thư mục `frontend/` và điền:
     ```env
     VITE_API_BASE_URL=https://<địa-chỉ-ngrok-của-bạn>/api/v1
     ```
   * **Nếu build đưa lên hosting trực tuyến (Production)**: Mở file `frontend/.env.production` và thay đổi giá trị `VITE_API_BASE_URL` bằng URL ngrok mới:
     ```env
     VITE_API_BASE_URL=https://<địa-chỉ-ngrok-của-bạn>/api/v1
     ```
3. **Cách chạy & Đóng gói**:
   * **Cách 1: Chạy trực tiếp dưới máy local để kiểm thử**:
     ```bash
     npm run dev
     ```
   * **Cách 2: Đóng gói để tải lên hosting**:
     ```bash
     npm run build
     ```
     Sau khi chạy, thư mục đóng gói `dist/` sẽ được tạo ra. Bạn hãy nén thư mục `dist` này lại dưới dạng zip, tải lên phần quản lý File của Hosting (thư mục gốc `public_html`) và giải nén ra. Trang web online sẽ tự động liên kết hoàn hảo với local backend của bạn.
