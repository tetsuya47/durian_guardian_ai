# 🌳 Báo Cáo Dự Án Durian Guardian AI: Kết Quả Thực Hiện & Kế Hoạch Phát Triển Hệ Thống
> **AI Operating System for Smart Durian Farms**  
> 🛡️ *Protect Every Tree. Predict Every Risk.*

---

## 📌 1. TỔNG QUAN DỰ ÁN & BỐ CẢNH KỸ THUẬT

**Durian Guardian AI (DGA)** là nền tảng ứng dụng trí tuệ nhân tạo toàn diện phục vụ quản lý sức khỏe, dịch bệnh và dự báo rủi ro cho các trang trại sầu riêng thông minh quy mô lớn. Dự án sử dụng mô hình kiến trúc đa tầng (Monorepo) tích hợp nhiều công nghệ hiện đại:

*   **API Backend:** Xây dựng bằng **FastAPI** (Python 3.12) kết nối bất đồng bộ với cơ sở dữ liệu.
*   **Database Layer:** Sử dụng **MongoDB** làm cơ sở dữ liệu tài liệu lưu trữ thông tin cây trồng, phân khu và lịch sử chẩn đoán thông qua driver **Motor**.
*   **Web Dashboard:** Phát triển bằng **React, TypeScript và Vite** phục vụ ban quản trị trang trại và doanh nghiệp.
*   **Mobile App:** Phát triển bằng **Flutter** và quản lý trạng thái bằng **Riverpod**, dành cho công nhân và kỹ sư nông nghiệp trực tiếp đi kiểm tra vườn.

---

## 🟢 2. CÁC NỘI DUNG ĐÃ THỰC HIỆN THÀNH CÔNG (COMPLETED WORK)

Trong phiên làm việc này, chúng ta đã tập trung vào việc chuẩn bị môi trường, sửa lỗi cài đặt, khởi động hệ thống và đồng bộ hóa kết nối mạng nội bộ giữa các thiết bị. Chi tiết cụ thể như sau:

### 2.1. Khắc Phục Lỗi Cài Đặt Thư Viện & Xây Dựng Môi Trường Ảo Chuẩn
*   **Vấn đề trước đó:** Hệ thống sử dụng Python 3.14 (phiên bản thử nghiệm) dẫn đến việc biên dịch một số thư viện viết bằng Rust (như `pydantic-core`, `cryptography`) bị lỗi, không thể cài đặt các dependency cần thiết của dự án.
*   **Giải pháp thực hiện:**
    *   Xây dựng lại môi trường ảo Python (`venv`) tại thư mục [backend/](file:///d:/Code/Ai_For_Life/durian_guardian_ai/backend) sử dụng phiên bản ổn định **Python 3.12.10**.
    *   Cài đặt thành công toàn bộ danh sách dependency của Backend trong file [requirements.txt](file:///d:/Code/Ai_For_Life/durian_guardian_ai/backend/requirements.txt).
    *   Cài đặt bổ sung các thư viện nặng phục vụ cho việc tích hợp mô hình AI sau này bao gồm: `torch` (PyTorch bản CPU để tối ưu dung lượng), `torchvision` (xử lý hình ảnh tensor), `Pillow` (đọc và ghi file ảnh) và `pandas` (xử lý dữ liệu bảng dùng trong tiền xử lý của mô hình).
    *   Đăng ký chính thức các gói thư viện này vào danh sách yêu cầu hệ thống.

### 2.2. Khởi Chạy Thành Công Hệ Thống Máy Chủ Local
*   **FastAPI Backend Server:** Khởi chạy server thành công bằng lệnh `python run.py` (chạy qua uvicorn) trên cổng mặc định **`http://localhost:8000`**. Hệ thống tự động theo dõi thay đổi file (auto-reload) và sẵn sàng tiếp nhận các yêu cầu RESTful API từ Web Dashboard và Mobile App.
*   **Vite Web Dashboard:** Khởi chạy máy chủ phát triển web thành công thông qua lệnh `npm run dev` tại thư mục [frontend/](file:///d:/Code/Ai_For_Life/durian_guardian_ai/frontend) trên cổng **`http://localhost:5173`**.

### 2.3. Cấu Hình Đồng Bộ Hóa IP Kết Nối Cho Thiết Bị Di Động
*   **Vấn đề kết nối:** Khi chạy ứng dụng di động trên điện thoại thật để kiểm tra vườn, điện thoại không thể kết nối tới `localhost:8000` của máy tính. Cần kết nối thông qua địa chỉ IP mạng LAN (Wi-Fi).
*   **Giải pháp thực hiện:**
    *   Kiểm tra địa chỉ IP thực tế của máy chủ lưu trữ backend trên mạng Wi-Fi hiện tại là **`172.16.25.248`**.
    *   Cập nhật biến cấu hình `deviceHost` trong file hệ thống của Mobile [environment_config.dart](file:///d:/Code/Ai_For_Life/durian_guardian_ai/dga_mobile/lib/core/network/environment_config.dart#L18) thành địa chỉ IP mới này. Điều này giúp ứng dụng di động Flutter tự động trỏ đúng đường dẫn API `http://172.16.25.248:8000/api/v1` khi chạy thực tế.

---

## 🔮 3. KẾ HOẠCH THIẾT KẾ & PHÁT TRIỂN CHI TIẾT CÁC TÍNH NĂNG TIẾP THEO (PLANNED WORK)

Nhằm đáp ứng trọn vẹn các yêu cầu nâng cấp nghiệp vụ trang trại sầu riêng thông minh, các tính năng tiếp theo sẽ được triển khai lập trình theo thiết kế chi tiết dưới đây:

### 3.1. Tích Hợp Mô Hình AI Thực Tế Vào API Backend
*   **Hiện trạng:** API Backend `/api/v1/ai/detect` và `/api/v1/ai/image-quality` đang dùng hàm giả lập trả kết quả ngẫu nhiên (Mock).
*   **Giải pháp tích hợp:**
    *   **Tải mô hình (Model Loading):** Viết cơ chế lazy-loading trong lớp `AIService` để load hai mô hình PyTorch đã được huấn luyện sẵn từ thư mục dự án khi nhận request đầu tiên:
        1.  **Model 1 (Phân loại bệnh):** Tải file checkpoint `best_model.pt` từ thư mục `training/checkpoints/disease_detection/` (sử dụng kiến trúc EfficientNet-B0 để nhận diện 11 lớp bệnh hại sầu riêng).
        2.  **Model 2 (Đánh giá chất lượng ảnh):** Tải file checkpoint `best_model.pt` từ thư mục `training_quality/checkpoints/` (sử dụng kiến trúc MobileNet V3 Small phân loại ảnh Đạt/Không đạt).
    *   **Tiền xử lý ảnh (Preprocessing):** Nhúng module `val_transform` để tự động resize ảnh về kích thước chuẩn `224x224`, chuẩn hóa dữ liệu ảnh đầu vào theo phân phối trung bình/phương sai của ImageNet trước khi đưa vào mô hình.
    *   **Ánh xạ cơ sở dữ liệu:** Viết bộ lọc ánh xạ 11 nhãn bệnh của mô hình (ví dụ: `anthracnose_disease`, `stem_cracking_gummosis`) thành các nhãn tiếng Việt tương ứng lưu trữ trực tiếp vào collection `disease_history` trong MongoDB để đồng bộ hóa báo cáo.
    *   **Cơ chế dự phòng (Fallback):** Đảm bảo nếu quá trình nạp mô hình hoặc suy luận xảy ra lỗi bất ngờ (hết bộ nhớ, file hỏng), API sẽ tự động ghi nhận log cảnh báo và trả về kết quả giả lập an toàn để ứng dụng không bị crash.

### 3.2. Tính Năng "So Sánh Trước & Sau" (Before/After Comparison Page)
*   **Mục tiêu:** Cho phép nông dân theo dõi sự phục hồi trực quan và định lượng của cây sầu riêng qua các đợt chăm sóc bón phân hoặc phun thuốc.
*   **Thiết kế luồng hoạt động:**
    1.  Người dùng truy cập màn hình So sánh qua nút bấm 🔄 trên thanh tiêu đề của trang Lịch sử.
    2.  Hệ thống hiển thị Dropdown danh sách các cây sầu riêng đã từng được kiểm tra.
    3.  Khi chọn một cây (ví dụ: *Tree 1*), hệ thống tự động lọc ra danh sách các đợt khám của cây đó từ collection `inspections`.
    4.  Người dùng chọn đợt khám "Trước" và đợt khám "Sau" thông qua dropdown thời gian.
*   **Thiết kế giao diện hiển thị:**
    *   **So sánh hình ảnh:** Hiển thị song song hai hình ảnh của cây ở hai thời điểm để so sánh trực giác sự thay đổi của vết bệnh, lá cây hoặc cành thân.
    *   **Bảng đối chiếu thông số:** Tạo bảng đối chiếu chi tiết bao gồm: *Mức độ nghiêm trọng của bệnh (Nhẹ/Trung bình/Nặng), Độ tin cậy dự đoán của AI, Điểm số nguy cơ rủi ro (Risk Score), Điều kiện thời tiết (Nhiệt độ, độ ẩm) lúc chụp.*
    *   **Đánh giá phục hồi tự động:** Hệ thống tự động phân tích dữ liệu so sánh để đưa ra kết luận văn bản (ví dụ: cây phục hồi tốt, bệnh có xu hướng giảm nhẹ hoặc đưa ra cảnh báo khẩn cấp nếu điểm nguy cơ tăng cao).

### 3.3. Tính Năng "Thi Đua & Thống Kê Phân Khu" (Leaderboard & Zone Stats)
*   **Mục tiêu:** Khuyến khích các tổ đội sản xuất nâng cao chất lượng chăm sóc cây trồng, đồng thời cảnh báo sớm điểm nóng dịch bệnh theo từng khu vực trong trang trại.
*   **Thiết kế tính năng Bảng Thi Đua (Leaderboard):**
    *   Xếp hạng các phân khu (Zone A, B, C...) trong trang trại dựa trên **Điểm số chăm sóc (Care Score)**. Điểm số này được tính toán từ tỷ lệ phần trăm cây khỏe mạnh trong phân khu kết hợp với tần suất đi kiểm tra định kỳ của công nhân.
    *   Mỗi phân khu trên bảng xếp hạng sẽ hiển thị tên người phụ trách (quản lý phân khu) kèm theo giống sầu riêng trồng chủ yếu (ví dụ: Ri6, Monthong).
    *   Tích hợp nút **"Hỏi kinh nghiệm"** cho phép hiển thị hộp thoại pop-up chứa thông tin liên hệ (số điện thoại) của quản lý phân khu đó để mọi người gọi điện hoặc nhắn tin học hỏi kỹ thuật.
*   **Thiết kế tính năng Thống Kê Dịch Bệnh Khu Vực (Zone Disease Stats):**
    *   Cung cấp dropdown chọn phân khu để xem chi tiết tình hình dịch bệnh.
    *   Hiển thị biểu đồ thanh ngang biểu diễn tỷ lệ phần trăm các loại bệnh cây hay gặp trong khu vực đó (Ví dụ: Khỏe mạnh 75%, Bệnh đốm lá 15%, Sâu đục quả 10%) kèm số lượng cây cụ thể bị nhiễm bệnh.
    *   Hệ thống tự động đưa ra nhận định chung về tình hình phân khu để người quản lý tổng thể có phương án khoanh vùng xử lý thuốc bảo vệ thực vật hợp lý.

### 3.4. Hệ Thống Dự Báo Năng Suất (Yield Forecasting)
*   Xây dựng mô hình AI dự toán sản lượng thu hoạch sầu riêng (tấn/vụ) cho năm nay và năm sau dựa trên: độ tuổi của cây trồng, giống cây, lịch sử chăm sóc bón phân và số lần nhiễm bệnh trong các mùa vụ trước.
*   Thiết kế biểu đồ so sánh sản lượng thực tế đã thu hoạch và sản lượng dự báo trên Web Dashboard để phục vụ kế hoạch phân phối thương mại.

### 3.5. Kênh Phản Hồi Ý Kiến Người Dùng Bằng Command
*   Tạo collection `feedbacks` trong MongoDB để ghi nhận ý kiến đóng góp hoặc báo cáo lỗi kỹ thuật từ người dùng ngoài thực địa.
*   Tích hợp tính năng tiếp nhận lệnh chat trực tiếp trong chatbot AI Agronomist trên ứng dụng di động (Ví dụ: người dùng gõ lệnh `/feedback [nội dung ý kiến]` hệ thống sẽ tự động phân tích cú pháp và lưu bản ghi vào database).

---

## 📅 4. LỘ TRÌNH TRIỂN KHAI CHI TIẾT TIẾP THEO

Để hoàn thành các dự định trên một cách bài bản và chuẩn xác, quy trình triển khai tiếp theo được phân chia thành các bước cụ thể như sau:

| Bước | Thành Phần | Nội Dung Thực Hiện Chi Tiết | Dự Kiến |
| :--- | :--- | :--- | :--- |
| **Bước 1** | **Backend API** | Thay thế code mock trong [service.py](file:///d:/Code/Ai_For_Life/durian_guardian_ai/backend/app/ai/service.py), load trực tiếp file checkpoint `best_model.pt` của PyTorch để chạy suy luận thật cho tính năng chẩn đoán bệnh và kiểm tra chất lượng ảnh đầu vào. | 25 phút |
| **Bước 2** | **Mobile UI** | Phát triển giao diện màn hình so sánh trước/sau [compare_page.dart](file:///d:/Code/Ai_For_Life/durian_guardian_ai/dga_mobile/lib/features/history/presentation/pages/compare_page.dart) hỗ trợ chọn cây, chọn thời điểm khám và vẽ bảng so sánh chỉ số. | 25 phút |
| **Bước 3** | **Mobile UI** | Phát triển màn hình thống kê phân khu và bảng thi đua [leaderboard_page.dart](file:///d:/Code/Ai_For_Life/durian_guardian_ai/dga_mobile/lib/features/history/presentation/pages/leaderboard_page.dart) hiển thị xếp hạng điểm chăm sóc tốt và biểu đồ dịch bệnh. | 20 phút |
| **Bước 4** | **Routing & Nav** | Cấu hình liên kết định tuyến trong [app_router.dart](file:///d:/Code/Ai_For_Life/durian_guardian_ai/dga_mobile/lib/config/routes/app_router.dart) và thiết kế thêm các nút bấm điều hành trên trang [history_page.dart](file:///d:/Code/Ai_For_Life/durian_guardian_ai/dga_mobile/lib/features/history/presentation/pages/history_page.dart). | 10 phút |
| **Bước 5** | **Testing** | Tiến hành build ứng dụng di động bằng `flutter run`, nạp ảnh thử nghiệm từ camera/thư viện để kiểm tra luồng kết nối API và lưu trữ MongoDB thực tế. | 15 phút |
