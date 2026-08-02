# DATABASE_RESET_INVESTIGATION_REPORT

**Release:** 1.3.2 — Emergency Audit (Database Reset Investigation)
**Project:** Durian Guardian AI
**Date:** 2026-08-01
**Status:** Investigation complete — **read-only, nothing was modified, no ETL/Seed run, no data created, no commit**

---

## 1. Executive Summary

Toàn bộ dữ liệu của Enterprise Database `durian_guardian_ai` đã bị **xóa trắng và thay thế
bằng dữ liệu test** trong lúc Release 1.3.1 (KPI Aggregation Fix) được thực hiện.

**Nguyên nhân gốc — chính xác:**

| Thuộc tính | Giá trị |
|---|---|
| **File** | `backend/tests/conftest.py` |
| **Function** | `setup_db` — `pytest_asyncio.fixture(autouse=True)` |
| **Line** | 28–30 |
| **Code** | `collections = await db.list_collection_names()`<br>`for col in collections:`<br>`    await db[col].delete_many({})` |
| **Trigger** | Chạy lệnh `pytest` để kiểm tra KPI Fix (thực hiện nhiều lần trong Release 1.3.1) |
| **Reason** | Fixture `autouse` này chạy **trước mỗi test**, gọi `MongoDBManager.get_db()` → trả về **chính database production** `durian_guardian_ai` (`backend/app/core/config.py:19`, `backend/app/database/mongodb.py:27`, không có `.env` override), rồi `delete_many({})` trên **mọi collection**. Sau đó các test fixture chèn dữ liệu test tiếng Anh tối thiểu; riêng `trees`/`inspections` bị `$jsonSchema` validator (chỉ nhận tiếng Việt) **từ chối ghi** (`pymongo.errors.WriteError` code 121) nên các collection này còn **0 document**. |

**Bản thân KPI Aggregation Fix hoàn toàn READ-ONLY** (chỉ thêm các truy vấn `count_documents`
và `distinct`, đính kèm khóa `stats` vào response). **Nó không ghi, không drop, không seed, không
thay đổi dữ liệu.** Việc reset xảy ra vì quy trình kiểm thử (`pytest`) đã bị chạy trên database
production mà không có cơ chế cô lập test database.

Trạng thái hiện tại (đo trực tiếp, read-only): `companies=1, farms=1, zones=1, users=2`, tất cả
collection còn lại `= 0` — đúng là "test residue" còn sót lại sau lần chạy pytest cuối, cộng với
`Bao Admin` do sự kiện startup của app tự seed lại (`backend/app/main.py:53-76`).

---

## 2. Git Change Analysis

### 2.1 `git status` / `git diff` — file thay đổi trong Working Tree

HEAD hiện tại: `eaaafc0 feat: final sync database _1`.

**Backend / Frontend — Release 1.3.1 (KPI Fix):** diff đã kiểm tra toàn bộ, chỉ gồm:

- `backend/app/api/v1/{users,trees,inspections,disease_history}.py` — thêm `stats` vào `data`.
- `backend/app/repositories/{user,tree,inspection,disease_history}_repository.py` — thêm `get_kpi_stats()` (chỉ `count_documents` / `distinct`).
- `backend/app/services/{user,tree,inspection,disease_history}_service.py` — delegate + `pass_rate`.
- `backend/app/models/enums.py`, `backend/app/schemas/user_crud.py` — `db_role` (read-only mapping).
- Frontend: `Users.tsx`, `Trees.tsx`, `Inspections.tsx`, `DiseaseHistory.tsx`, `Sidebar.tsx`, `routes/index.tsx`, `types/user.ts`, `translate.ts`.

**Không có file mới chứa thao tác ghi DB.** Không có file bị xóa. (Các file `database/*` đang
"modified" trong working tree là thay đổi từ Phase 4 Database — commit trước, không thuộc Release 1.3.1.)

### 2.2 Diff KPI Fix — minh chứng read-only

Toàn bộ diff của KPI Fix (đã trích ra trong quá trình audit) chỉ chứa `count_documents({})`,
`count_documents({"role": ...})`, `count_documents({"status": {"$in": ...}})`, `distinct(...)`,
`round(healthy / total * 100)` và gán `data["stats"] = ...`. **Không chứa `insert_*`, `update_*`,
`delete_*`, `replace_*`, `drop`, `drop_database`.**

### 2.3 Kết luận Git Analysis

→ Release 1.3.1 **không** chứa code ghi/đổi dữ liệu DB. Reset **không** đến từ code KPI.

---

## 3. Startup Analysis

### 3.1 `backend/app/main.py`

- `create_app()` chỉ: middleware CORS, routers, static uploads, `/health`.
- `@app.on_event("startup")` → `_seed_admin_user()` (dòng 53–76): **chỉ** tạo admin `bao@gmail.com`
  nếu chưa tồn tại (`get_by_email` → nếu có thì `return`). **Idempotent, không xóa, không reset.**
- Không gọi ETL, không gọi seed, không init database trên startup.

### 3.2 Dependency Injection

- `backend/app/database/mongodb.py:38` `get_database()` → `MongoDBManager.get_db()` → đọc-only, không khởi tạo dữ liệu.
- Không có `init_database()`, `initialize_database()`, `seed_database()` được gọi tự động ở bất kỳ đâu trong `backend/app`.

### 3.3 Kết luận Startup Analysis

→ Startup của backend **không** gây reset. (Admin seeding trên startup chỉ giải thích vì sao
`Bao Admin` xuất hiện lại sau khi bị xóa — đây là dấu vết xác nhận DB đã từng bị xóa.)

---

## 4. ETL Analysis

### 4.1 `database/` module

| File | Vai trò | Chạy tự động? |
|---|---|---|
| `database/etl_pipeline.py` | ETL CSV/Excel → MongoDB; `random.seed(42)` ở các transform tự sinh → **xác định (deterministic)** | Không — chỉ chạy qua CLI `python -m database.etl_pipeline` / `python -m database.setup_database` |
| `database/setup_database.py` | Orchestrator: ETL + validator + index + seed admin | Không — CLI-only |
| `database/db_schema.py` | Định nghĩa collection + `$jsonSchema` validator | Không chạy độc lập |
| `database/indexes.py` | Index specs | Không chạy độc lập |
| `database/seed_admin.py`, `seed_farm_owners.py` | Seed admin / farm owner | Không — CLI-only |

### 4.2 Điểm mấu chốt

- `run_etl(drop_existing=False, ...)` (dòng 1907): mặc định **không drop** collection; `--drop-existing`
  mới drop. Nếu ETL được chạy mặc định, các collection sẽ được **cộng dồn**, không thể tự sinh ra
  trạng thái "chỉ còn 1 company / 0 cây" — tức **ETL không phải nguyên nhân**.
- Nguồn dữ liệu: `etl_pipeline.py:1926` đọc `D:\data\DGA_Enterprise_Dataset.xlsx` (file **còn tồn tại**, đã xác minh).
- Không có lệnh nào trong Release 1.3.1 gọi các script này.

### 4.3 Kết luận ETL Analysis

→ ETL/Seed **không bị chạy lại** trong Release 1.3.1 và cũng **không giải thích được** trạng thái hiện tại.

---

## 5. Database Comparison

Đo trực tiếp (read-only) database `durian_guardian_ai` bằng `pymongo`:

| Collection | **Expected** (ETL Design / đã xác minh trước reset) | **Actual** (hiện tại) | Mismatch |
|---|---|---|---|
| companies | 10 | **1** (`Test Company`) | ❌ |
| farms | 10 | **1** (`Test Farm`) | ❌ |
| zones | 50 | **1** | ❌ |
| trees | 6,000 | **0** | ❌ |
| users | 61 | **2** (`Seeded Inspector` test + `Bao Admin` startup) | ❌ |
| diseases | 15 (master) | **0** | ❌ |
| inspections | 10,000 | **0** | ❌ |
| detection_results | 10,000 | **0** | ❌ |
| disease_history | 2,136 | **0** | ❌ |
| alerts | (từ Excel, xác định) | **0** | ❌ |
| seasons | 20 (2/farm) | **0** | ❌ |
| harvests | 20 (1/season) | **0** | ❌ |
| farm_targets | 20 (1/season) | **0** | ❌ |
| farm_performance | 20 (1/season) | **0** | ❌ |
| neighbor_contact_requests | ~25–26 (sinh xác định) | **0** | ❌ |

**Nhận định:** Trạng thái `companies=1, farms=1, zones=1, users=2`, còn lại `0` khớp **chính xác**
với dấu vết mà test fixtures để lại sau khi `setup_db` xóa sạch và các insert cây/kiểm tra bị
validator chặn (`WriteError`). Sample docs xác nhận: `COMP001 / Test Company`, `FARM001 / Test Farm`,
user `inspector@test.com` — toàn bộ là dữ liệu test, không phải dữ liệu enterprise.

---

## 6. Root Cause

### 6.1 Chuỗi sự kiện

1. **Thiết kế lỗi:** `backend/tests/conftest.py:22-31` định nghĩa fixture `autouse=True` tên `setup_db`
   nhằm dọn dữ liệu trước mỗi test — nhưng nó gọi `MongoDBManager.get_db()`, tức database **production**
   `durian_guardian_ai` (`config.py:19`). Không có test database riêng, không có `.env` override.
2. **Hành động kích hoạt:** Trong Release 1.3.1, để xác nhận KPI Fix, các lệnh sau đã được chạy
   (mỗi lần đều kích hoạt `setup_db` → xóa sạch toàn bộ collection của `durian_guardian_ai`):
   - `pytest tests/test_users_crud.py tests/test_inspections_crud.py tests/test_disease_history_crud.py -q`
   - chạy toàn bộ test suite
   - `pytest ... -v` và các lần chạy baseline `git stash`
3. **Hệ quả:** sau khi xóa, các test fixture chèn dữ liệu test tối thiểu (tiếng Anh);
   `trees`/`inspections`/`detection_results`/`disease_history`/… không có bản ghi nào vì validator
   chỉ nhận enum tiếng Việt → `WriteError` code 121 → collection còn 0.
4. **Dấu vết thứ cấp:** khi backend restart, `main.py` startup re-seed `Bao Admin` → `users=2`.

### 6.2 Chỉ định chính xác

| | |
|---|---|
| **File** | `backend/tests/conftest.py` |
| **Function** | `setup_db` (`pytest_asyncio.fixture(autouse=True)`) |
| **Line** | 22–31; thao tác hủy dữ liệu tại **line 29–30** |
| **Reason** | `delete_many({})` trên mọi collection của **database production** (không cô lập test DB); kích hoạt bởi lệnh `pytest` chạy trong lúc validate Release 1.3.1 |

**Kết luận rõ ràng:** Database bị reset **không phải do code KPI** mà do **chạy test suite
(`pytest`) trên database production** — `conftest.py` xóa toàn bộ dữ liệu trước mỗi test và để lại
dữ liệu test tối thiểu.

---

## 7. Recovery Recommendation

> Đề xuất phương án — **chưa thực hiện** (đúng yêu cầu STEP 1: không sửa, không ETL, không seed, không tạo dữ liệu, không commit).

### 7.1 Phương án chính (khuyến nghị) — Tái tạo chính xác bằng ETL xác định

Dataset enterprise được sinh **xác định** (`random.seed(42)` trong `etl_pipeline.py`), nguồn
`D:\data\DGA_Enterprise_Dataset.xlsx` **còn tồn tại** (đã xác minh). Chạy lại pipeline **của chính dự án**
sẽ tái tạo đúng Enterprise Dataset ban đầu (10 companies, 10 farms, ~50 zones, 6,000 trees,
61 users, 15 diseases, 10,000 inspections, 10,000 detection_results, 2,136 disease_history,
alerts từ Excel, 20 seasons, 20 harvests, 20 farm_targets, 20 farm_performance, ~25–26 NCR).

Cách thực hiện (chỉ khi được duyệt):

```bash
# Từ thư mục repo gốc D:\durian_guardian_ai
python -m database.setup_database --drop-existing
```

- `--drop-existing` để loại bỏ hoàn toàn dữ liệu test residue (1 company / 1 farm / 2 users test)
  trước khi nạp dataset đầy đủ.
- `setup_database` còn tự: tạo collection + `$jsonSchema` validator (`db_schema.py`), tạo indexes
  (`indexes.py`), seed admin (`seed_admin.py`).
- Xác minh sau khi chạy: đối chiếu lại số document với bảng Expected tại mục 5, và kiểm tra
  `users=61`, `trees=6000`, `inspections=10000`, `detection_results=10000`, `disease_history=2136`.

> Lưu ý: đây **không phải** tạo dữ liệu mới/random — nó là tái tạo **đúng dataset chuẩn của dự án**
> bằng chính ETL đã được duyệt, với seed xác định.

### 7.2 Phương án thay thế — Khôi phục từ backup

- Nếu có `mongodump`/backup ngoài repo (thư mục backup riêng): khôi phục trực tiếp.
- Trong repo **không tìm thấy** file dump/backup nào (`*.dump`, `*.gz`, `*.bson`), `git stash list` rỗng.

### 7.3 Phương án phòng ngừa (đề xuất cho bước sau, ngoài phạm vi STEP 1)

- Tách test database: cấu hình test dùng DB riêng (vd `durian_guardian_ai_test`) — `conftest.py`
  không được dùng `MongoDBManager.get_db()` production.
- Chặn kiểm tra tên DB trong `setup_db`: chỉ xóa khi DB là test DB.
- Không chạy `pytest` khi `MONGODB_DB_NAME` trỏ vào production; thêm guard trong CI.

---

## 8. Final Conclusion

1. **Database không bị reset bởi code KPI.** Toàn bộ diff Release 1.3.1 là read-only.
2. **Thủ phạm:** `backend/tests/conftest.py:22-31` — fixture `autouse` `setup_db` dùng
   `delete_many({})` trên database production `durian_guardian_ai` trước mỗi test, được kích hoạt
   khi chạy `pytest` để validate KPI Fix.
3. Trạng thái hiện tại (`companies=1, farms=1, users=2`, còn lại `0`) là **dữ liệu test residue**
   cộng với admin do startup tự seed — đã đối chiếu trực tiếp với MongoDB.
4. **Khôi phục khả thi ngay:** chạy `python -m database.setup_database --drop-existing` sẽ tái tạo
   đúng Enterprise Dataset chuẩn (deterministic, nguồn Excel còn nguyên). Chưa thực hiện — chờ duyệt.
5. Cần phòng ngừa: cô lập test DB và guard chống chạy pytest trên production database.
