# Báo cáo hoàn tác toàn bộ Neighbor Contact

Ngày: 2026-08-01

## Tóm tắt

Hoàn tác triệt để toàn bộ tính năng **Neighbor Contact Requests** (kết nối / chia sẻ liên hệ giữa nông dân lân cận). Dự án đã được khôi phục về đúng trạng thái trước khi triển khai tính năng ở tất cả các lớp: cơ sở dữ liệu, backend, mobile (dga_mobile), tài liệu. Không commit, không push.

## Phạm vi hoàn tác

Chỉ xoá/khôi phục các thay đổi thuộc tính năng Neighbor Contact. Các thay đổi tồn tại từ trước (không liên quan) trong các module dashboard, history, disease detection, AI, seed, test vẫn được giữ nguyên.

## 1. Backend — Xoá (file chưa commit, untracked)

- `backend/app/api/v1/neighbor_contact_requests.py`
- `backend/app/repositories/neighbor_contact_request_repository.py`
- `backend/app/schemas/neighbor_contact_request.py`
- `backend/app/services/neighbor_contact_request_service.py`
- `backend/seed_neighbor_contact.py`
- `backend/tests/test_neighbor_contact_requests.py`

## 2. Backend — Khôi phục nguyên trạng (git checkout HEAD)

Các file này chỉ chứa hunk thuộc Neighbor Contact nên được khôi phục hoàn toàn về trạng thái commit `b5746d4`:

- `backend/app/models/enums.py` — bỏ ánh xạ vai trò `"Farm Owner" → farmer` (chỉ phục vụ Neighbor Contact)
- `backend/app/api/v1/__init__.py` — bỏ import + `include_router(neighbor_contact_requests_router)`
- `backend/app/schemas/__init__.py` — bỏ toàn bộ import và `__all__` của schema neighbor

## 3. Mobile (dga_mobile) — Xoá (untracked)

- `dga_mobile/lib/features/neighbor_contact/` (21 file — domain, data, providers, presentation)
- `dga_mobile/test/neighbor_contact_dtos_test.dart`
- `dga_mobile/test/neighbor_contact_widget_test.dart`

## 4. Mobile (dga_mobile) — Khôi phục nguyên trạng

Khôi phục về HEAD các file chỉ chứa thay đổi Neighbor Contact:

- `dga_mobile/lib/config/routes/app_router.dart` — bỏ 6 GoRoute `/neighbor-contact*`
- `dga_mobile/lib/config/routes/route_names.dart` — bỏ 6 hằng RouteNames
- `dga_mobile/lib/core/constants/app_strings.dart` — bỏ `neighborContactAction`/`neighborContactDesc`
- `dga_mobile/lib/core/network/api_endpoints.dart` — bỏ 7 endpoint getter `neighborContact*`

Khôi phục phẫu thuật (chỉ bỏ hunk Neighbor Contact, giữ thay đổi tồn tại từ trước `CrossAxisAlignment.stretch → start`):

- `dga_mobile/lib/features/dashboard/presentation/widgets/quick_actions_grid.dart` — bỏ tile "Liên Hệ Hàng Xóm"

## 5. Cơ sở dữ liệu

- Bỏ seed script `backend/seed_neighbor_contact.py` (xem mục 1).
- Không có migration/ETL/validator/index riêng cho tính năng (collection `neighbor_contact_requests` do service tạo ngầm); không còn bất kỳ tham chiếu nào trong `database/`.

## 6. Tài liệu — Xoá

- `docs/api/NEIGHBOR_CONTACT_API_SPEC.md` (cả thư mục `docs/api/` — chỉ chứa spec này)
- `docs/reports/NEIGHBOR_CONTACT_BACKEND_IMPLEMENTATION_REPORT.md`
- `docs/reports/NEIGHBOR_CONTACT_BACKEND_READINESS_REPORT.md`
- `docs/reports/MOBILE_NEIGHBOR_CONTACT_IMPLEMENTATION_REPORT.md`

## 7. Dọn dẹp khác

- Xoá `backend/.pytest_cache/` và toàn bộ `__pycache__` trong `backend/app` và `backend/tests` (chứa bytecode `.pyc` của các module đã xoá).

## 8. Kết quả kiểm tra (verification)

| Kiểm tra | Kết quả |
| --- | --- |
| `flutter analyze` | 19 issues, **0 errors** (chỉ info/warning tồn tại từ trước — khớp baseline trước tính năng) |
| `python -m compileall backend/app backend/tests` | OK |
| Import backend (`from app.main import app`) | OK, router tải 73 route, không còn route `/neighbor-contact-requests` |
| Quét toàn repo `neighbor_contact / NeighborContact / neighbor-contact / Neighbor Contact` (loại trừ .git, build, .dart_tool, node_modules, uploads, dataset) | **0 kết quả** |
| `git status --short` | Không còn file nào thuộc Neighbor Contact; các thay đổi tồn tại từ trước được giữ nguyên |

## Ghi chú

- Không thực hiện commit/push theo yêu cầu.
- Không sửa module không liên quan.
- Thay đổi tồn tại từ trước trong `backend/app/ai/service.py`, `backend/app/api/v1/ai.py`, `backend/app/dashboard/service.py`, `backend/app/repositories/disease_repository.py`, `backend/app/schemas/dashboard.py`, `backend/app/schemas/disease.py`, `backend/seed_demo.py`, `backend/tests/*`, và các file mobile dashboard/history/disease-detection khác được giữ nguyên.
