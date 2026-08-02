# DGA ENTERPRISE — AUTHORIZATION BUSINESS REQUIREMENTS
## Tài Liệu Yêu Cầu Nghiệp Vụ Phân Quyền (Business Requirements for Authorization)
**Dự án:** Durian Guardian AI (DGA) — Release 1.3.x  
**Chế độ:** Product Owner Review & Business Analysis Mode  
**Tác giả:** Antigravity IDE (Pairing with Product Owner)  
**Nguồn tham chiếu (Source of Truth):** 
1. `AUTHORIZATION_AUDIT_REPORT.md` (AUDIT)
2. `AUTHORIZATION_AUDIT_EXTENSION.md` (EXTENSION)
3. `AUTHORIZATION_DISCOVERY_REPORT.md` (DISCOVERY)

---

> [!IMPORTANT]
> **Tuyên bố Phạm vi (Scope Disclaimer):**
> Tài liệu này **CHỈ** tập trung xây dựng **Business Requirements** (Yêu cầu nghiệp vụ) cho bài toán Phân quyền Hệ thống (Authorization).
> - **KHÔNG** thiết kế Ma trận Quyền (Permission Matrix).
> - **KHÔNG** thiết kế RBAC (Role-Based Access Control) hay ABAC.
> - **KHÔNG** đề xuất Policy, Middleware, Decorator hay Code implementation.
> - **KHÔNG** đề xuất API Endpoints, DTO, Repository hay Database Schema modification.
> - Toàn bộ giả định kỹ thuật không có bằng chứng trong mã nguồn hiện tại được gắn nhãn rõ ràng là `[ASSUMPTION]` và chuyển giao Product Owner quyết định trong phần **Open Questions**.

---

## 1. Project Scope (Phạm Vi Dự Án Nghiệp Vụ)

Hệ thống **Durian Guardian AI (DGA Enterprise)** là nền tảng quản trị nông nghiệp thông minh dành cho chuỗi giá trị sầu riêng enterprise, kết hợp công nghệ nhận diện bệnh hại bằng AI, giám sát thực địa, quản lý cây trồng theo định danh số (Digital ID) và mạng lưới cảnh báo dịch bệnh liên nông trại (Neighbor Contact Request).

Phạm vi nghiệp vụ của tài liệu phân quyền này bao gồm:
1. **Thiết lập ranh giới quản trị đa cấp (Enterprise Multi-Level Boundary):** Từ cấp Doanh nghiệp (Company) xuống Nông trại (Farm), Vùng trồng (Zone), Cây trồng (Tree), cùng các bản ghi vận hành thực địa.
2. **Xác định mô hình sở hữu dữ liệu nghiệp vụ (Business Ownership Model):** Xác định tính chính chủ và trách nhiệm của các thực thể dữ liệu đối với người dùng và tổ chức.
3. **Phân vùng phạm vi dữ liệu (Business Scope):** Xác định ranh giới xem và thao tác dữ liệu theo phạm vi Doanh nghiệp, Nông trại, Cây trồng và Cá nhân.
4. **Xác định mức độ hiển thị dữ liệu (Business Visibility):** Phân loại dữ liệu theo các cấp độ Riêng tư (Private), Nội bộ (Internal), Doanh nghiệp (Enterprise), và Chia sẻ (Shared).
5. **Tổng hợp danh mục quyết định nghiệp vụ (Product Owner Decisions):** Liệt kê 50 quyết định nghiệp vụ cần Product Owner phê duyệt trước khi tiến hành thiết kế kỹ thuật.

---

## 2. Business Goals (Mục Tiêu Nghiệp Vụ)

1. **Bảo vệ Tài sản & Dữ liệu Nông nghiệp Enterprise:** Đảm bảo dữ liệu quy trình, lịch sử dịch bệnh, bản đồ vùng trồng, danh dách cây sầu riêng quý và hồ sơ nông dân không bị truy cập trái phép giữa các doanh nghiệp hoặc giữa các nông trại không liên quan.
2. **Tối ưu hóa Vận hành Thực địa:** Cung cấp trải nghiệm nghiệp vụ tinh gọn cho Kỹ thuật viên và Giám định viên thực địa, giúp họ tập trung vào việc kiểm tra, chụp ảnh, ghi nhận kết quả AI và xử lý bệnh hại mà không bị rào cản thao tác thừa.
3. **Minh bạch hóa Trách nhiệm (Operational Accountability):** Đảm bảo mỗi kiểm tra thực địa, kết quả AI, ghi nhận bệnh hại hay cảnh báo đều gắn liền với trách nhiệm nghiệp vụ rõ ràng của từng Actor.
4. **Hỗ trợ Hợp tác & Phòng dịch Vùng (Epidemic Outbreak Collaboration):** Thiết lập cơ chế chia sẻ thông tin liên lạc và cảnh báo dịch bệnh giữa các nông trại lân cận dựa trên mô hình đồng thuận hai bên (Bilateral Consent).
5. **Chuẩn hóa Đầu vào cho Thiết kế Phân quyền Kỹ thuật:** Tạo cơ sở nghiệp vụ chính xác, loại bỏ các giả định thiếu căn cứ kỹ thuật để Product Owner duyệt trước khi đội ngũ kỹ thuật xây dựng RBAC / Policy.

---

## 3. Business Principles (Nguyên Tắc Nghiệp Vụ)

1. **Nguyên tắc Ranh giới Nghiệp vụ (Business-Driven Boundaries):** Ranh giới phân quyền phải tuân theo cấu trúc tổ chức và vận hành thực tế của trang trại, không dựa trên sự tiện lợi của lập trình kỹ thuật.
2. **Nguyên tắc Quyền tối thiểu & Cần mới biết (Need-to-Know Basis):** Người dùng chỉ tiếp cận đúng phạm vi dữ liệu phục vụ trực tiếp cho trách nhiệm công việc được giao.
3. **Nguyên tắc Toàn vẹn Lịch sử Nông nghiệp (Data Integrity & Historical Retention):** Dữ liệu bệnh hại, lịch sử kiểm tra và nhật ký cảnh báo là tài sản tri thức nông nghiệp; việc loại bỏ dữ liệu phải tuân thủ quy trình lưu trữ/lưu trữ lịch sử (Archive) thay vì xóa bỏ vật lý không dấu vết.
4. **Nguyên tắc Đồng thuận Hai bên khi Chia sẻ (Bilateral Consent for Shared Data):** Dữ liệu liên lạc và tình hình dịch bệnh lân cận không bao giờ được tự động công khai mà phải thông qua quy trình phê duyệt đồng thuận giữa Farm nguồn và Farm đích.
5. **Nguyên tắc Xác thực Ranh giới Tập trung:** Mọi hành vi nghiệp vụ phải được bảo vệ thống nhất từ giao diện (Web Portal, Mobile App) đến trung tâm xử lý dữ liệu.

---

## 4. Enterprise Hierarchy (Phân Cấp Doanh Nghiệp)

Sơ đồ phân cấp thực thể nghiệp vụ end-to-end của DGA Enterprise:

```
Company (Doanh nghiệp)
   │
   ▼
Farm (Nông trại)
   │
   ▼
Zone (Vùng / Phân khu)
   │
   ▼
Tree (Cây trồng - Digital ID)
   │
   ├──────► Inspection (Kiểm tra thực địa)
   │           │
   │           ▼
   │        Detection (Kết quả nhận diện AI)
   │
   ├──────► Disease History (Lịch sử bệnh hại)
   │
   ├──────► Alert (Cảnh báo dịch bệnh / sức khỏe)
   │
   └──────► Neighbor Contact (Liên hệ & Cảnh báo vùng)
```

### Mô tả chi tiết từng cấp thực thể:
- **Company (Doanh nghiệp):** Cấp tổ chức cao nhất, quản lý danh mục các Nông trại, điều phối nguồn lực và chịu trách nhiệm báo cáo tổng thể.
- **Farm (Nông trại):** Đơn vị sản xuất nông nghiệp trực thuộc Doanh nghiệp, có vị trí địa lý, quy mô diện tích và chỉ tiêu sản lượng riêng.
- **Zone (Vùng / Phân khu):** Phân khu địa lý hoặc phân khu kỹ thuật bên trong một Nông trại để nhóm các Cây trồng có cùng độ tuổi/giống.
- **Tree (Cây trồng):** Thực thể tài sản cốt lõi, có mã định danh số (Digital ID/QR), tọa độ GPS, giống sầu riêng và lịch sử sinh trưởng.
- **Inspection (Kiểm tra thực địa):** Hoạt động thăm vườn, đánh giá thực tế sức khỏe cây trồng do Chuyên viên thực hiện.
- **Detection (Kết quả AI):** Kết quả phân tích tự động từ mô hình AI dựa trên hình ảnh chụp thực địa trong quá trình Inspection.
- **Disease History (Lịch sử bệnh hại):** Tiến trình ghi nhận bệnh, diễn biến, biện pháp xử lý và mức độ phục hồi của Cây trồng theo thời gian.
- **Alert (Cảnh báo):** Thông điệp cảnh báo về rủi ro bệnh hại, chất lượng ảnh hoặc bất thường phát sinh tại Cây trồng / Nông trại.
- **Neighbor Contact (Liên hệ hàng xóm / Cảnh báo vùng):** Mạng lưới liên kết hai bên giữa các Nông trại lân cận để cảnh báo dịch bệnh khu vực và hợp tác nông nghiệp.

---

## 5. Business Actors (Vai Trò Nghiệp Vụ)

Dựa trên 6 vai trò lưu trữ trong cơ sở dữ liệu (`REPORT §5.2`, `EXT §1`), dưới đây là mô tả thuần túy về **chức danh và vai trò nghiệp vụ** trong doanh nghiệp (không bao gồm thiết kế permission kỹ thuật):

1. **Admin (Quản trị viên Hệ thống):**
   - Vai trò: Người chịu trách nhiệm quản trị tổng thể nền tảng kỹ thuật, cấp phát tài khoản, duy trì sự ổn định của hệ thống enterprise.
2. **Company Manager (Quản lý Doanh nghiệp):**
   - Vai trò: Nhà quản lý cấp cao tại Doanh nghiệp, chịu trách nhiệm điều hành toàn bộ danh mục Nông trại, theo dõi hiệu suất sản xuất và chiến lược nông nghiệp.
3. **Farm Manager (Quản lý Nông trại):**
   - Vai trò: Người điều hành trực tiếp hoạt động tại một hoặc nhiều Nông trại, phân công nhiệm vụ cho kỹ thuật viên/giám định viên, theo dõi chỉ tiêu nông trại.
4. **Inspector (Chuyên viên kiểm tra / Giám định viên):**
   - Vai trò: Nhân sự chuyên môn thực hiện kiểm tra thực địa, chụp ảnh chuẩn đoán bệnh, chạy công cụ AI và xác nhận tình trạng sức khỏe cây sầu riêng.
5. **Technician (Kỹ thuật viên Nông nghiệp):**
   - Vai trò: Nhân sự vận hành tại trang trại, thực hiện các biện pháp chăm sóc, bón phân, phun thuốc, xử lý cây bệnh theo chỉ đạo kỹ thuật.
6. **Farm Owner (Chủ Nông trại / Nông dân):**
   - Vai trò: Chủ sở hữu hợp pháp hoặc diện đại diện tài sản nông trại, theo dõi tình hình vườn sầu riêng của mình và tham gia mạng lưới liên kết hàng xóm.

*(Ghi chú: Hiện tại hệ thống API đang gộp 6 vai trò này thành 4 nhóm API role (`REPORT §5.2`), tuy nhiên tài liệu nghiệp vụ này bảo lưu đầy đủ 6 vai trò nghiệp vụ thực tế để Product Owner xem xét).*

---

## 6. Business Responsibilities (Trách Nhiệm Nghiệp Vụ)

Mô tả các **trách nhiệm công việc (Responsibilities)** của từng Actor trong chu trình vận hành (không dùng thuật ngữ "được phép làm gì"):

- **Admin:**
  - Cấp phát và quản lý vòng đời tài khoản người dùng toàn hệ thống.
  - Cấu hình thông số nền tảng và giám sát nhật ký hoạt động chung.
- **Company Manager:**
  - Theo dõi tổng quan hiệu suất và chỉ tiêu sản lượng của tất cả các Nông trại thuộc Doanh nghiệp.
  - Quản lý danh mục Doanh nghiệp và phê duyệt định hướng mở rộng nông trại.
- **Farm Manager:**
  - Quản lý thông tin chi tiết Nông trại và phân chia các Vùng trồng (Zone).
  - Phân công công việc kiểm tra thực địa và giám sát tiến độ xử lý bệnh hại tại nông trại.
  - Theo dõi các cảnh báo dịch bệnh phát sinh trong phạm vi nông trại phụ trách.
- **Inspector:**
  - Thực hiện các đợt kiểm tra thực địa (Inspection) tại các cây trồng được giao.
  - Thu thập hình ảnh, đánh giá chất lượng ảnh chụp và vận hành công cụ chẩn đoán AI.
  - Ghi nhận chi tiết kết quả phát hiện bệnh hại và đề xuất phương án xử lý.
- **Technician:**
  - Cập nhật nhật ký chăm sóc và thi hành các biện pháp điều trị bệnh hại trên cây.
  - Kiểm tra thẻ định danh số (Digital ID / QR code) của cây trồng tại thực địa.
- **Farm Owner:**
  - Nắm bắt báo cáo tổng quan sức khỏe và chỉ tiêu sản lượng của nông trại thuộc sở hữu.
  - Xem xét và ra quyết định chấp nhận/từ chối các yêu cầu chia sẻ thông tin liên lạc từ các Nông trại hàng xóm.

---

## 7. Business Ownership Model (Mô Hình Sở Hữu Dữ Liệu)

Dựa trên kết quả khám phá (`AUTHORIZATION_DISCOVERY_REPORT.md` Decisions 007–015), mô hình sở hữu dữ liệu nghiệp vụ được xác định như sau:

| Thực thể dữ liệu | Mô hình sở hữu nghiệp vụ (Ownership Model) | Hiện trạng dữ liệu (`REPORT §3.1`, `EXT §2`) | Đánh giá & Vấn đề nghiệp vụ |
|---|---|---|---|
| **Company** | Sở hữu cấp Doanh nghiệp | Trường `companies.owner` là chuỗi văn bản tự do, chưa liên kết với tài khoản người dùng (`REPORT §3.1`). | `[UNKNOWN]` Chưa có liên kết chính chủ rõ ràng giữa người dùng và Doanh nghiệp. |
| **Farm** | Sở hữu kép (Chủ sở hữu & Quản lý) | Trường `farms.owner_user_id` (Farm Owner) và `manager_user_id` (Company Manager) (`REPORT §3.1`). | Có cấu trúc sở hữu chính (`owner_user_id`), nhưng quy trình gán/thay đổi người quản lý chưa hoàn thiện. |
| **Zone** | Sở hữu kế thừa từ Farm | Trường `zones.farm_id` kết nối về Nông trại (`REPORT §3.1`). | Không có chủ sở hữu riêng cấp Zone; phụ thuộc hoàn toàn vào Farm cha. |
| **Tree** | Sở hữu kế thừa từ Farm/Zone | Trường `trees.farm_id` và `zone_id` (`REPORT §3.1`). | Không có chủ sở hữu riêng cho từng cây; cây thuộc về Nông trại/Vùng trồng. |
| **Inspection** | Sở hữu bởi Người kiểm tra (Inspector) | Ghi nhận `inspections.inspector_id` khi tạo bản ghi (`EXT §2`). | `[UNKNOWN]` Chưa có quy tắc ai được quyền chỉnh sửa/xóa bản ghi kiểm tra ngoài người tạo. |
| **Detection Result** | Gắn liền với đợt Kiểm tra (Inspection) | Chỉ ghi nhận `inspection_id`, không lưu thông tin người dùng trực tiếp (`EXT §2`). | Thuộc sở hữu của lượt kiểm tra tương ứng. |
| **Disease History** | Gắn liền với Cây trồng & Người ghi nhận | Schema có `detected_by_user_id` nhưng dịch vụ hiện chưa ghi dữ liệu này (`EXT §2`). | `[UNKNOWN]` Chưa xác định chủ sở hữu bản ghi lịch sử bệnh. |
| **Alert** | Sở hữu cấp Nông trại / Cây trồng | Ghi nhận theo `farm_id`/`tree_id`; schema có `acknowledged_by` nhưng dịch vụ chưa ghi (`EXT §2`). | `[UNKNOWN]` Chưa xác định cá nhân chịu trách nhiệm xác nhận/giải quyết cảnh báo. |
| **Neighbor Contact** | Sở hữu hai bên (Bilateral Ownership) | Lưu trữ `source_user_id`/`source_farm_id` và `target_user_id`/`target_farm_id` cùng trạng thái đồng thuận (`REPORT §3.1`). | Quyền sở hữu và chấp thuận thuộc về cả 2 bên (Farm nguồn và Farm đích). |

---

## 8. Business Scope (Phân Vùng Phạm Vi Dữ Liệu)

Phân vùng dữ liệu nghiệp vụ bao gồm 4 phạm vi chính (`REPORT §11`, Decisions 016–020):

1. **Enterprise / Company Scope (Phạm vi Doanh nghiệp):**
   - Bao phủ toàn bộ dữ liệu thuộc một Doanh nghiệp (danh sách Nông trại, Vùng trồng, Cây trồng, Báo cáo tổng hợp, Kỹ thuật viên).
   - *Thực trạng:* Hệ thống hiện tại chưa phân vùng theo Doanh nghiệp (chưa hỗ trợ Multi-tenant isolation) (`REPORT §11`).
2. **Farm Scope (Phạm vi Nông trại):**
   - Bao phủ dữ liệu phát sinh trong nội bộ một Nông trại cụ thể (các Zone, danh mục Cây trồng, danh sách đợt Kiểm tra, Cảnh báo tại nông trại đó).
   - *Thực trạng:* ngoại trừ màn hình Farmer Overview lọc theo `owner_user_id`, các danh sách khác hiện chưa giới hạn theo Farm Scope (`REPORT §9.3`).
3. **Tree Scope (Phạm vi Cây trồng):**
   - Phân vùng dữ liệu liên quan trực tiếp đến một Cây trồng cụ thể (Lịch sử kiểm tra, Kết quả AI, Lịch sử bệnh hại, Nhật ký xử lý).
4. **User Scope / "My Data" Scope (Phạm vi Cá nhân):**
   - Phân vùng các dữ liệu do chính người dùng tạo ra hoặc được phân công (các đợt kiểm tra do mình thực hiện, nhiệm vụ được giao, thông báo cá nhân).

---

## 9. Business Operations (Thao Tác Nghiệp Vụ Chi Tiết Các Module)

Mô tả mục đích và các nghiệp vụ chính của từng Module (không sử dụng thuật ngữ kỹ thuật CRUD - Create/Read/Update/Delete):

### 9.1 Module Doanh Nghiệp (Company Module)
- **Nghiệp vụ:** Đăng ký thành lập doanh nghiệp nông nghiệp, Cập nhật thông tin tổ chức, Quản lý cấu trúc danh mục nông trại thuộc doanh nghiệp, Theo dõi tình hình vận hành tổng thể.

### 9.2 Module Nông Trại (Farm Module)
- **Nghiệp vụ:** Thiết lập nông trại mới, Khai báo diện tích và vị trí địa lý, Phân công Quản lý Nông trại, Thiết lập chỉ tiêu sản lượng (Farm Targets), Theo dõi diễn biến hiệu suất nông trại (Farm Performance).

### 9.3 Module Vùng Trồng (Zone Module)
- **Nghiệp vụ:** Phân chia nông trại thành các vùng kỹ thuật, Nhóm cây trồng theo độ tuổi/giống sầu riêng, Giám sát mật độ và tình trạng sức khỏe theo phân khu.

### 9.4 Module Cây Trồng (Tree Module)
- **Nghiệp vụ:** Đăng ký định danh số cho cây sầu riêng (Digital ID / QR / Tọa độ GPS), Theo dõi quá trình phát triển của cây, Tra cứu hồ sơ sức khỏe cây, Khai báo thông tin giống và năm trồng, Ghi nhận tình trạng hủy/thay thế cây.

### 9.5 Module Kiểm Tra Thực Địa (Inspection Module)
- **Nghiệp vụ:** Lập kế hoạch kiểm tra vườn, Thực hiện đợt khảo sát thực địa tại gốc cây, Thu thập hình ảnh tán lá/thân/trái, Khai báo ghi chú thực địa, Đánh dấu hoàn thành đợt kiểm tra.

### 9.6 Module Nhận Diện AI (AI Detection Module)
- **Nghiệp vụ:** Tải ảnh thực địa để phân tích tự động, Kiểm tra đánh giá chất lượng ảnh (Image Quality Check), Phân loại bệnh hại tự động (Model 1 Classification), Đánh giá mức độ tin cậy của chẩn đoán AI.

### 9.7 Module Lịch Sử Bệnh Hại (Disease History Module)
- **Nghiệp vụ:** Lập bản ghi bệnh hại phát hiện trên cây, Cập nhật tiến trình diễn biến dịch bệnh, Ghi nhận các biện pháp kỹ thuật đã can thiệp, Đánh giá mức độ phục hồi của cây sầu riêng.

### 9.8 Module Cảnh Báo & Thông Báo (Alert & Notification Module)
- **Nghiệp vụ:** Phát tín hiệu cảnh báo dịch bệnh tự động, Tiếp nhận thông báo rủi ro sức khỏe cây trồng, Xác nhận đã đọc/đã tiếp nhận cảnh báo (Acknowledge), Theo dõi danh sách cảnh báo chưa xử lý.

### 9.9 Module Mạng Lưới Liên Hệ Hàng Xóm (Neighbor Contact Request Module)
- **Nghiệp vụ:** Tìm kiếm các nông trại lân cận, Gửi yêu cầu kết nối chia sẻ thông tin, Phê duyệt hoặc Từ chối yêu cầu chia sẻ từ nông trại hàng xóm, Cảnh báo lây nhiễm dịch bệnh vùng.

### 9.10 Module Quản Lý Tài Khoản (User Management Module)
- **Nghiệp vụ:** Tiếp nhận nhân sự mới, Cấp phát tài khoản người dùng, Phân công chức danh nghiệp vụ, Đổi trạng thái hoạt động (Active/Inactive), Cập nhật thông tin hồ sơ cá nhân.

---

## 10. Business Workflow (Quy Trình Nghiệp Vụ End-to-End)

Chuỗi quy trình nghiệp vụ xuyên suốt từ cấp Doanh nghiệp đến việc xử lý dịch bệnh liên nông trại:

```
[1. Khởi tạo Cấu trúc Enterprise]
   Company đăng ký ──► Tạo Farm ──► Phân chia Zone ──► Đăng ký Tree (Digital ID & GPS)
                                                                 │
                                                                 ▼
[2. Vận hành & Kiểm tra Thực địa]
   Lập kế hoạch ──► Inspector khảo sát tại cây ──► Chụp ảnh & Chạy AI Detection
                                                                 │
                                                                 ▼
[3. Chẩn đoán & Ghi nhận Sức khỏe]
   AI đưa kết quả ──► Inspector xác nhận bệnh ──► Ghi vào Disease History
                                                                 │
                                                                 ▼
[4. Cảnh báo & Điều trị]
   Hệ thống phát động Alert ──► Farm Manager tiếp nhận ──► Phân công Technician xử lý
                                                                 │
                                                                 ▼
[5. Hợp tác Phòng dịch Vùng (Neighbor Network)]
   Phát hiện nguy cơ lây nhiễm ──► Gửi Neighbor Contact Request ──► Farm hàng xóm Chấp thuận ──► Chia sẻ thông tin dịch bệnh
```

---

## 11. Business Visibility (Mức Độ Hiển Thị Dữ Liệu Nghiệp Vụ)

Phân loại dữ liệu theo 4 cấp độ hiển thị (thuần túy nghiệp vụ, không nhắc tới role hay permission):

1. **Dữ liệu Riêng tư (Private Data):**
   - Mật khẩu mã hóa, mã làm mới phiên đăng nhập (Refresh Token).
   - Ghi chú nháp cá nhân của Giám định viên trước khi ấn xuất bản kết quả.
2. **Dữ liệu Nội bộ Nông trại (Internal Farm Data):**
   - Chi tiết danh mục cây sầu riêng, bản đồ vị trí các Zone trong trang trại.
   - Nhật ký kiểm tra thực địa chi tiết, kết quả chẩn đoán AI tại từng gốc cây.
   - Danh sách kỹ thuật viên và phân công nhiệm vụ nội bộ.
3. **Dữ liệu Doanh nghiệp (Enterprise Data):**
   - Báo cáo tổng hợp hiệu suất (Farm Performance), Bảng tổng quan Dashboard.
   - Bản đồ nhiệt dịch bệnh (Disease Heatmap) trên toàn bộ các nông trại thuộc Doanh nghiệp.
   - Chỉ tiêu sản lượng và kế hoạch kinh doanh nông nghiệp.
4. **Dữ liệu Chia sẻ Liên nông trại (Shared Data):**
   - Thông tin liên lạc giữa hai nông trại hàng xóm sau khi **cả hai bên đã chấp thuận**.
   - Cảnh báo bùng phát dịch bệnh cấp vùng (không tiết lộ chi tiết tài chính/sản lượng của nông trại).

---

## 12. Business Constraints (Ràng Buộc Nghiệp Vụ)

Các quy tắc ràng buộc nghiệp vụ cốt lõi bắt buộc tuân thủ:

1. **Ràng buộc Phân cấp Tổ chức:**
   - Một Nông trại (Farm) chỉ thuộc về **duy nhất một** Doanh nghiệp (Company).
   - Một Vùng trồng (Zone) chỉ thuộc về **duy nhất một** Nông trại (Farm).
   - Một Cây trồng (Tree) chỉ thuộc về **duy nhất một** Vùng trồng (Zone) và Nông trại (Farm).
2. **Ràng buộc Bản ghi Vận hành:**
   - Một đợt Kiểm tra (Inspection) bắt buộc phải liên kết với một Cây trồng (Tree) xác định.
   - Một Kết quả AI (Detection Result) bắt buộc phải xuất phát từ một đợt Kiểm tra (Inspection) hợp lệ.
   - Một bản ghi Lịch sử Bệnh hại (Disease History) phải gắn liền với một Cây trồng cụ thể.
3. **Ràng buộc Lưu trữ Lịch sử (Retention Constraint):**
   - Không được phép xóa cứng (Hard Delete) các bản ghi Lịch sử bệnh hại và Kết quả kiểm tra đã hoàn thành để phục vụ công tác truy xuất nguồn gốc nông sản và theo dõi dịch bệnh lâu dài (`REPORT §3.1`, Decision 025).
4. **Ràng buộc Đồng thuận Chia sẻ (Consent Constraint):**
   - Thông tin liên lạc và chi tiết cảnh báo của Nông trại A tuyệt đối không được hiển thị cho Nông trại B ngoại trừ khi Trạng thái Đồng thuận Neighbor Contact đạt trạng thái `contact_shared` (đã được cả 2 bên phê duyệt) (`REPORT §3.1`, Decision 015, 046).

---

## 13. Business Assumptions (Các Giả Định Nghiệp Vụ)

Dưới đây là danh sách các giả định được rút ra do mã nguồn và tài liệu hiện tại chưa có bằng chứng khẳng định (`REPORT §14`, `DISCOVERY REPORT`):

- `[ASSUMPTION-01]` **Mặc định Đăng ký công khai:** Việc hệ thống cho phép đăng ký tài khoản công khai và tự động nhận vai trò `field_technician` (`REPORT §4.3`) được giả định là cơ chế thử nghiệm phát triển, không phải quy trình nghiệp vụ chính thức cho môi trường Enterprise (Decision 004).
- `[ASSUMPTION-02]` **Hiệu lực Trạng thái Tài khoản:** Giả định rằng khi tài khoản ở trạng thái `INACTIVE`, người dùng sẽ bị chặn toàn bộ quyền đăng nhập và vô hiệu hóa các phiên làm việc hiện tại (Decision 006).
- `[ASSUMPTION-03]` **Chủ sở hữu Doanh nghiệp:** Giả định rằng trường chuỗi ký tự tự do `companies.owner` sẽ được thay thế bằng liên kết tài khoản đại diện pháp nhân / Quản lý Doanh nghiệp cụ thể (Decision 007).
- `[ASSUMPTION-04]` **Độc lập Đa doanh nghiệp (Multi-Tenancy Isolation):** Giả định rằng DGA Enterprise sẽ vận hành theo mô hình Multi-tenant, trong đó dữ liệu của Doanh nghiệp này hoàn toàn biệt lập với Doanh nghiệp khác (Decision 016, 017).
- `[ASSUMPTION-05]` **Cơ chế Lưu trữ (Archive) thay vì Xóa:** Giả định rằng các thao tác xóa Cây trồng hoặc Nông trại trên giao diện thực chất là chuyển trạng thái Lưu trữ (Archive/Inactive) để không phá vỡ tính toàn vẹn của dữ liệu thống kê dịch bệnh (Decision 025).
- `[ASSUMPTION-06]` **Đồng bộ Nghiệp vụ Mobile & Web:** Giả định rằng ứng dụng Mobile (DGA Mobile) và Web Portal áp dụng chung một tập quy tắc nghiệp vụ và phạm vi truy cập dữ liệu (Decision 050).

---

## 14. Open Questions for Product Owner Decision (Danh Mục 50 Quyết Định Nghiệp Vụ Cần Product Owner Phê Duyệt)

Toàn bộ 50 quyết định nghiệp vụ từ `AUTHORIZATION_DISCOVERY_REPORT.md` được tổng hợp dưới đây, phân nhóm để Product Owner xem xét và đưa ra quyết định chính thức:

### Nhóm A: Quyết Định Về Chức Danh & Vai Trò Nghiệp Vụ (Decisions 001–006)
1. **Decision 001 & 003:** Hệ thống nên chốt sử dụng **6 vai trò nghiệp vụ thực tế** (Admin, Company Manager, Farm Manager, Inspector, Technician, Farm Owner) hay gộp thành **4 nhóm vai trò API**?
2. **Decision 002:** Định nghĩa nghiệp vụ chính thức và nhiệm vụ chi tiết của từng vai trò trong 6 vai trò trên là gì?
3. **Decision 004:** Có tiếp tục mở đăng ký tài khoản tự do với vai trò mặc định `field_technician` hay chuyển sang cơ chế duyệt/cấp tài khoản bởi Quản trị viên?
4. **Decision 005:** Quy trình thay đổi vai trò của người dùng sau khi tạo tài khoản sẽ do ai phê duyệt?
5. **Decision 006:** Trạng thái tài khoản `INACTIVE` sẽ có hiệu lực cụ thể như thế nào (chặn đăng nhập ngay lập tức, hủy phiên làm việc hiện tại hay chỉ chặn thao tác mới)?

### Nhóm B: Quyết Định Về Mô Hình Sở Hữu Dữ Liệu (Decisions 007–015)
6. **Decision 007:** Mô hình xác định chủ sở hữu của Doanh nghiệp (Company Owner) được quy định như thế nào?
7. **Decision 008:** Một Nông trại có cho phép mô hình đồng sở hữu (vừa có Chủ sở hữu `owner_user_id` vừa có Quản lý `manager_user_id`) hay không?
8. **Decision 009 & 010:** Vùng trồng (Zone) và Cây trồng (Tree) có cần thiết lập chủ sở hữu cá nhân riêng biệt ngoài chủ sở hữu của Nông trại không?
9. **Decision 011:** Bản ghi Kiểm tra thực địa (Inspection) có thuộc quyền sở hữu riêng của Chuyên viên kiểm tra (Inspector) tạo ra nó hay thuộc về Nông trại?
10. **Decision 012 & 013:** Ai là người sở hữu và có quyền điều chỉnh bản ghi Kết quả AI (Detection) và Lịch sử Bệnh hại (Disease History)?
11. **Decision 014:** Cảnh báo (Alert) phát sinh tại Nông trại sẽ do Quản lý Nông trại hay Chủ Nông trại chịu trách nhiệm xác nhận (Acknowledge)?
12. **Decision 015:** Quy trình xác nhận đồng thuận hai bên đối với Yêu cầu liên hệ hàng xóm (Neighbor Contact Request) diễn ra như thế nào?

### Nhóm C: Quyết Định Về Phạm Vi & Mức Độ Hiển Thị Dữ Liệu (Decisions 016–020, 041–044)
13. **Decision 016 & 017:** Hệ thống là Single-tenant hay Multi-tenant? Dữ liệu giữa các Doanh nghiệp có được phép cách ly tuyệt đối không?
14. **Decision 018 & 019:** Danh sách Nông trại, Vùng trồng và Cây trồng có được giới hạn hiển thị nghiêm ngặt theo phạm vi Nông trại được giao hay không?
15. **Decision 020:** Khái niệm "Dữ liệu của tôi" (My Data Scope) áp dụng cho những vai trò nào ngoài Chủ Nông trại?
16. **Decision 026:** Màn hình Dashboard tổng quan và các chỉ số KPI doanh nghiệp sẽ hiển thị cho những vai trò nghiệp vụ nào?
17. **Decision 027:** Hồ sơ tổng quan nông dân (Farmer Overview) chỉ dành riêng cho Quản trị viên hay cho phép Quản lý Nông trại và chính Nông dân xem?
18. **Decision 028:** Danh bạ người dùng toàn hệ thống (Users Directory) có được mở rộng cho tất cả nhân sự xem hay chỉ dành cho Quản trị viên?
19. **Decision 029 & 042:** Mức độ chi tiết của danh sách Cây trồng, Đợt kiểm tra, Kết quả AI và Cảnh báo khi hiển thị cho các vai trò khác nhau?
20. **Decision 044:** Có yêu cầu ẩn/che (Redact) các thông tin nhạy cảm (như số điện thoại, thông tin liên lạc, mã nội bộ) theo từng vai trò hay không?

### Nhóm D: Quyết Định Về Thao Tác & Quy Trình Nghiệp Vụ (Decisions 021–025, 030–033)
21. **Decision 021, 022, 023:** Trách nhiệm thực hiện việc khai báo/cập nhật/loại bỏ đối với Cây trồng, Doanh nghiệp và Tài khoản người dùng được giao cho những vai trò nào?
22. **Decision 024:** Ai có trách nhiệm chỉnh sửa hoặc điều chỉnh các bản ghi vận hành thực địa (Inspection, Detection Result, Disease History)?
23. **Decision 025:** Chính sách xử lý dữ liệu: Hệ thống cho phép xóa vĩnh viễn (Hard Delete) hay bắt buộc sử dụng cơ chế Lưu trữ (Archive/Soft Delete)?
24. **Decision 030:** Những thao tác nghiệp vụ nào bắt buộc phải qua quy trình Phê duyệt / Từ chối / Giải quyết (Approve/Reject/Resolve)?
25. **Decision 031:** Ai có thẩm quyền phân công người dùng vào các Doanh nghiệp và Nông trại?
26. **Decision 032:** Có mở rộng nghiệp vụ Trích xuất dữ liệu (Export) và Nhập dữ liệu hàng loạt (Import) trên hệ thống hay không?
27. **Decision 033:** Việc đánh dấu đã đọc/xác nhận thông báo và cảnh báo là thao tác cá nhân (per-user) hay thao tác chung toàn Nông trại?

### Nhóm E: Quyết Định Về Giao Diện, Điều Hướng & Ứng Dụng Mobile (Decisions 034–037, 050)
28. **Decision 034:** Thanh điều hướng Sidebar có ẩn/hiện các mục menu theo vai trò nghiệp vụ hay giữ nguyên cho tất cả người dùng?
29. **Decision 035 & 036:** Các đường dẫn trang bị ẩn (như `/detection-results`, `/diseases`) và truy cập trực tiếp qua URL (Deep-link) sẽ được kiểm soát nghiệp vụ ra sao?
30. **Decision 037:** Các nút thao tác nghiệp vụ trên màn hình có được ẩn/hiện tương ứng với vai trò của người dùng hay không?
31. **Decision 050:** Ứng dụng di động (DGA Mobile) có áp dụng chung tập quy tắc nghiệp vụ và vai trò giống như Web Portal hay không?

### Nhóm F: Quyết Định Về Các Tình Huống Enterprise Đặc Thụ (Decisions 038–040, 045–049)
32. **Decision 038 & 039:** Xác định danh mục các cổng thông tin công khai (Public Endpoints) chính thức của hệ thống Enterprise.
33. **Decision 040:** Quy tắc định tuyến và gửi thông báo/cảnh báo đến đúng đối tượng nhân sự mục tiêu.
34. **Decision 045:** Có tình huống nghiệp vụ nào cho phép nhân sự thuộc Doanh nghiệp này truy cập dữ liệu của Doanh nghiệp khác hay không?
35. **Decision 046:** Quy trình chia sẻ thông tin liên lạc và cảnh báo dịch bệnh khu vực giữa các Nông trại hàng xóm (End-to-end Neighbor Sharing Workflow).
36. **Decision 047:** Có tình huống tài sản (Nông trại, Cây trồng) hoặc bản ghi AI nào được chia sẻ dùng chung giữa nhiều Doanh nghiệp không?
37. **Decision 048:** Có cần cơ chế Ủy quyền tạm thời (Delegation / Manager Stand-in) khi Quản lý Nông trại hoặc Chủ Nông trại vắng mặt hay không?
38. **Decision 049:** Yêu cầu về Nhật ký vết nghiệp vụ (Business Audit Log): Những hành vi nào bắt buộc ghi vết và ai có quyền xem nhật ký này?

---

> [!NOTE]
> **Bước Tiếp Theo (Next Step):**
> Vui lòng gửi tài liệu `AUTHORIZATION_REQUIREMENTS.md` này cho Product Owner phê duyệt. 
> Ngay khi Product Owner đưa ra các quyết định cho 50 câu hỏi tại **Mục 14**, Antigravity IDE sẽ chuyển sang giai đoạn **Authorization Design** (Thiết kế Ma trận Quyền RBAC, Policy và Chi tiết Kỹ thuật).
