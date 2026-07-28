# Báo cáo đánh giá logic và hiệu năng của [etl_pipeline.py](file:///d:/Code/Ai_For_Life/durian_guardian_ai/database/etl_pipeline.py)

Báo cáo này chi tiết các lỗi logic (logic bugs), bất cập trong thiết kế dữ liệu, và các nút thắt hiệu năng nghiêm trọng (N+1 queries) trong file [etl_pipeline.py](file:///d:/Code/Ai_For_Life/durian_guardian_ai/database/etl_pipeline.py).

---

## 1. Các lỗi Logic nghiêm trọng (Critical Logic Bugs)

### Lỗi 1.1: Gán sai `disease_id` cho các bệnh không chuẩn (Non-standard Diseases) trong Inspections
* **Vị trí**: Hàm [transform_inspections](file:///d:/Code/Ai_For_Life/durian_guardian_ai/database/etl_pipeline.py#L904) (Dòng 925–927)
* **Triệu chứng**:
  ```python
  raw_disease = str(row.get("predicted_disease", "")).strip()
  disease_code = DISEASE_NAME_TO_CODE.get(raw_disease, "healthy")
  disease_oid = disease_map.get(disease_code)
  ```
  `DISEASE_NAME_TO_CODE` chỉ chứa 10 loại bệnh cơ bản (như Anthracnose, Canker, Healthy, v.v.). Tuy nhiên, bộ dữ liệu Excel chứa các bệnh khác như `Phytophthora`, `Leaf Spot`, `Nutrient Deficiency` (các bệnh này được thêm vào danh sách master qua Excel).
  Vì các bệnh này không nằm trong `DISEASE_NAME_TO_CODE`, `disease_code` sẽ mặc định lấy giá trị `"healthy"`. Kết quả là các bản ghi kiểm tra (inspections) của các bệnh này sẽ trỏ `disease_id` tới ID của **"Khỏe mạnh" (healthy)**, mặc dù `predicted_disease` vẫn lưu tên tiếng Việt đúng là `"Bệnh thối rễ Phytophthora"` hay `"Đốm lá"`.
* **Cách khắc phục**:
  Đồng bộ hóa cách tạo mã bệnh (disease code) tương tự như lúc tạo danh mục bệnh tổng hợp:
  ```python
  disease_code = DISEASE_NAME_TO_CODE.get(raw_disease) or raw_disease.lower().replace(" ", "_")
  ```

### Lỗi 1.2: Bất đồng bộ tên trường dữ liệu `"rainfall_mm"` và `"rainfall"`
* **Vị trí**: Hàm [clean_doc](file:///d:/Code/Ai_For_Life/durian_guardian_ai/database/etl_pipeline.py#L1052) trong [load_documents](file:///d:/Code/Ai_For_Life/durian_guardian_ai/database/etl_pipeline.py#L1030)
* **Triệu chứng**:
  - Validator của MongoDB trong [db_schema.py](file:///d:/Code/Ai_For_Life/durian_guardian_ai/database/db_schema.py#L240) định nghĩa trường `"rainfall_mm"`.
  - Trong bước transform của `etl_pipeline.py`, trường được gán tên là `"rainfall_mm"`.
  - Nhưng trong `load_documents`, helper `clean_doc` thực hiện đổi tên:
    ```python
    if k == "rainfall_mm":
        cleaned["rainfall"] = v
    ```
  - Việc này khiến dữ liệu thực tế lưu trong MongoDB mang tên `"rainfall"`. Do `"rainfall"` không được liệt kê trong `properties` của validator (nhưng cũng không bị cấm do không cấu hình `additionalProperties: false`), trường này hoàn toàn bypass kiểm tra hợp lệ của DB. Đồng thời, toàn bộ phần huấn luyện/dự báo AI trong `training_recommendation` lại đang gọi tên trường là `"rainfall"` (ví dụ: `NUM_COLS` trong [train.py](file:///d:/Code/Ai_For_Life/durian_guardian_ai/training_recommendation/train.py#L40)).
* **Cách khắc phục**:
  Cần thống nhất tên trường. Do code ML và Excel đều dùng `"rainfall"`, nên sửa validator trong [db_schema.py](file:///d:/Code/Ai_For_Life/durian_guardian_ai/database/db_schema.py) thành `"rainfall"` thay vì `"rainfall_mm"`, hoặc bỏ phần rename trong `clean_doc` nếu muốn dùng chuẩn `"rainfall_mm"`.

### Lỗi 1.3: Tạo các bản ghi bệnh trùng lặp (Duplicate Diseases) do so sánh lệch ngôn ngữ
* **Vị trí**: Hàm [transform_diseases_combined](file:///d:/Code/Ai_For_Life/durian_guardian_ai/database/etl_pipeline.py#L610)
* **Triệu chứng**:
  - Dữ liệu gốc `diseases.json` chứa tên tiếng Việt (`"Thán thư"`, `"Khỏe mạnh"`).
  - Sheet `diseases` trong Excel chứa tên tiếng Anh (`"Anthracnose"`, `"Healthy"`).
  - Hàm check trùng lặp dùng: `existing_names = {d["name"].lower() for d in diseases_json}` (chứa tiếng Việt) rồi so sánh `if name.lower() not in existing_names` (tên tiếng Anh).
  - Do tên khác ngôn ngữ, hệ thống coi `"Healthy"` và `"Anthracnose"` là các bệnh mới hoàn toàn và thêm chúng vào danh sách với mã trùng lặp (`"healthy"`, `"anthracnose_disease"`). Khi lưu vào MongoDB, việc này sẽ gây lỗi `DuplicateKeyError` (do có unique index trên trường `code` của diseases) và bị bỏ qua một cách không kiểm soát.

### Lỗi 1.4: Mâu thuẫn tài liệu hướng dẫn và hằng số đầu file với nguồn dữ liệu chạy thực tế (Inconsistent Data Source)
* **Vị trí**:
  - Docstring đầu file (Dòng 8–9): chỉ định rõ ràng *"The CSV is the ONLY source of truth. This pipeline: 1. Reads every row from the CSV"*
  - Khai báo hằng số đầu file (Dòng 55): `CSV_PATH = "D:/Ten_Classes_of_Durian_Leaf_Diseases/DGA_seed_dataset_10000.csv"`
  - Code logic thực tế: Hàm `extract_excel` (Dòng 270) và các phần load bổ sung trong `run_etl` (Dòng 1284) hoàn toàn đọc dữ liệu từ file Excel `DGA_Enterprise_Dataset.xlsx` thay vì CSV. Hằng số `CSV_PATH` được định nghĩa nhưng không được sử dụng ở bất kỳ đâu trong logic nạp dữ liệu của file này.
* **Nguyên nhân**:
  Pipeline ban đầu được thiết kế để nạp dữ liệu thô từ một file CSV đơn lẻ (`DGA_seed_dataset_10000.csv`). Khi dự án nâng cấp quy mô lên mô hình doanh nghiệp với dữ liệu quan hệ chặt chẽ (gồm 10 sheet liên kết: companies, farms, zones, trees, inspections, v.v.), người phát triển đã chuyển nguồn đọc sang file Excel `DGA_Enterprise_Dataset.xlsx` nhưng bỏ quên không dọn dẹp các tài liệu cũ và hằng số `CSV_PATH` ở đầu file, dẫn tới sự mâu thuẫn gây hiểu nhầm cho người đọc code.
* **Cách khắc phục**:
  - Cập nhật lại tài liệu hướng dẫn (docstring) của file để ghi rõ nguồn dữ liệu đầu vào chuẩn hiện tại là file Excel.
  - Xóa bỏ hằng số `CSV_PATH` không sử dụng để tránh gây rác code.

---

## 2. Nút thắt hiệu năng nghiêm trọng (Performance Bottlenecks - N+1 Queries)

### Lỗi 2.1: Truy vấn MongoDB riêng lẻ cho từng Inspection trong vòng lặp load
* **Vị trí**: Hàm [load_documents](file:///d:/Code/Ai_For_Life/durian_guardian_ai/database/etl_pipeline.py#L1210)
* **Triệu chứng**:
  ```python
  for insp in inspections:
      tree_doc = db.trees.find_one({"_id": insp["tree_id"]})
      farm_doc = db.farms.find_one({"_id": tree_doc["farm_id"]})
  ```
  Với 10,000 bản ghi kiểm tra (inspections), đoạn code này thực hiện tới **20,000 câu truy vấn** `find_one` tới MongoDB. Điều này khiến thời gian import dữ liệu kéo dài từ vài giây lên tới nhiều phút/giờ.
* **Cách khắc phục**:
  Tải trước (pre-load) toàn bộ danh sách `trees` và `farms` vào map trong bộ nhớ (in-memory caching):
  ```python
  reloaded_farms = {f["_id"]: f for f in db.farms.find()}
  reloaded_trees = {t["_id"]: t for t in db.trees.find()}
  ```
  Sau đó thực hiện lookup trực tiếp trên dict của Python.

### Lỗi 2.2: Truy vấn MongoDB riêng lẻ trong vòng lặp Validation
* **Vị trí**: Khối kiểm tra tính toàn vẹn dữ liệu trong [run_etl](file:///d:/Code/Ai_For_Life/durian_guardian_ai/database/etl_pipeline.py#L1432-L1502)
* **Triệu chứng**:
  Thực hiện truy vấn DB cho từng tree (6,000 lần), từng inspection (10,000 lần), từng alert, v.v., để kiểm tra xem ID tham chiếu có tồn tại hay không. Tổng cộng phát sinh thêm hơn **50,000 câu truy vấn** DB không cần thiết.
* **Cách khắc phục**:
  Chỉ cần lấy danh sách tất cả `_id` hợp lệ của các collection cha dưới dạng `set` trong một câu truy vấn duy nhất, ví dụ: `farm_ids = {f["_id"] for f in db.farms.find({}, {"_id": 1})}`. Sau đó kiểm tra `if target_id not in farm_ids` trong bộ nhớ.

---

## 3. Code thừa và không hiệu quả (Dead Code & Redundant Operations)

### Lỗi 3.1: Vòng lặp cập nhật tham chiếu cây không làm gì (Dead Code)
* **Vị trí**: Hàm [load_documents](file:///d:/Code/Ai_For_Life/durian_guardian_ai/database/etl_pipeline.py#L1163-L1176)
* **Triệu chứng**:
  ```python
  # Update tree references
  for tree in trees:
      farm_code = None
      for fc, fdoc in reloaded_farms.items():
          if fdoc["_id"] == tree["farm_id"]:
              farm_code = fc
              break
      if farm_code:
          zone_name_from_db = None
          for zc, zdoc in reloaded_zones.items():
              if zdoc["_id"] == tree.get("zone_id"):
                  zone_name_from_db = zc
                  break
  ```
  Vòng lặp này duyệt qua tất cả các cây, tìm ra `farm_code` và `zone_name_from_db` tương ứng nhưng không hề gán lại hay cập nhật bất kỳ thuộc tính nào của `tree`. Biến này bị giải phóng ngay khi hết vòng lặp. Đây là code thừa hoàn toàn.

### Lỗi 3.2: Xây dựng bản đồ `tree_map` cực kỳ tốn kém nhưng không sử dụng
* **Vị trí**: Dòng 1203–1207 trong [load_documents](file:///d:/Code/Ai_For_Life/durian_guardian_ai/database/etl_pipeline.py#L1203)
* **Triệu chứng**:
  Code thực hiện duyệt qua tất cả cây trong database và truy vấn DB của farm tương ứng để xây dựng `tree_map` lưu key dạng `(farm_code, tree_code)`. Tuy nhiên, biến `tree_map` này hoàn toàn không được sử dụng ở bất kỳ dòng code nào phía sau.

---

## 4. Xung đột logic phát sinh từ quá trình Việt hóa dữ liệu (Localization Conflicts)

Nghi ngờ của bạn hoàn toàn chính xác. Việc Việt hóa không đồng bộ giữa dữ liệu gốc (seed JSON), dữ liệu nhập khẩu (Excel) và mã nguồn của các thành phần liên quan (ML Models, Rule Engine) đã tạo ra các xung đột nghiêm trọng:

### 4.1. Sự bất đồng bộ ngôn ngữ gây gán sai liên kết dữ liệu (`disease_id`)
* **Mô tả xung đột**:
  Dữ liệu Excel đầu vào là tiếng Anh (`"Phytophthora"`), nhưng trong hàm [transform_inspections](file:///d:/Code/Ai_For_Life/durian_guardian_ai/database/etl_pipeline.py#L904), code việt hóa chuỗi hiển thị thành tiếng Việt (`"Bệnh thối rễ Phytophthora"`). Tuy nhiên, do từ điển ánh xạ mã bệnh `DISEASE_NAME_TO_CODE` không được cập nhật đầy đủ các từ tiếng Anh này, nó đã gán mã bệnh mặc định là `"healthy"` (Khỏe mạnh).
* **Hậu quả**:
  Trường `predicted_disease` lưu `"Bệnh thối rễ Phytophthora"` nhưng khóa ngoại `disease_id` lại trỏ tới ID của bệnh `"Khỏe mạnh"`. Đây là sự bất nhất dữ liệu rất nghiêm trọng.

### 4.2. Trùng lặp danh mục bệnh do lệch ngôn ngữ so khớp trùng lặp
* **Mô tả xung đột**:
  Hàm [transform_diseases_combined](file:///d:/Code/Ai_For_Life/durian_guardian_ai/database/etl_pipeline.py#L610) lấy danh mục bệnh có sẵn từ `diseases.json` (đã việt hóa, ví dụ: `"Thán thư"`) để kiểm tra trùng lặp với danh sách bệnh từ Excel (tiếng Anh, ví dụ: `"Anthracnose"`).
  Vì so sánh trực tiếp hai chuỗi khác ngôn ngữ (`"thán thư" != "anthracnose"`), hệ thống coi tiếng Anh là bệnh mới và thêm nó vào DB. Khi lưu vào MongoDB, nó kích hoạt lỗi trùng khóa `DuplicateKeyError` trên trường `code` (vì cả hai đều ánh xạ chung về mã `"anthracnose_disease"`).

### 4.3. Mô hình ML và Rule Engine bị ràng buộc chặt chẽ vào chuỗi tiếng Việt
* **Mô tả xung đột**:
  Các file xử lý của mô hình AI như [rule_engine.py](file:///d:/Code/Ai_For_Life/durian_guardian_ai/training_recommendation/rules/rule_engine.py#L84) hay [build_dataset.py](file:///d:/Code/Ai_For_Life/durian_guardian_ai/training_recommendation/datasets/build_dataset.py#L20) được lập trình cứng (hardcoded) để kiểm tra các chuỗi tiếng Việt được việt hóa bởi ETL như `"Bị bệnh"`, `"Khỏe mạnh"`, `"Đang theo dõi"`, `"Mưa"`, `"Khô"`.
* **Hậu quả**:
  Bất kỳ sự sai lệch nào trong khâu việt hóa ở file `etl_pipeline.py` (ví dụ: gán sai sang `"Khỏe mạnh"` ở lỗi 4.1) sẽ trực tiếp phá vỡ các đặc trưng (features) nạp vào mô hình AI. AI sẽ học sai lệch khi một bản ghi có đặc trưng chữ là `"Bệnh thối rễ Phytophthora"` nhưng các liên kết logic lại trỏ về `"Khỏe mạnh"`.

---

## 5. Hướng dẫn sửa đổi code (Proposed Code Changes)

Dưới đây là gợi ý các đoạn code cần thay đổi để sửa toàn bộ các lỗi trên:

### Sửa đổi 1: Sửa logic ánh xạ Disease ID trong `transform_inspections`
```diff
-        raw_disease = str(row.get("predicted_disease", "")).strip()
-        disease_code = DISEASE_NAME_TO_CODE.get(raw_disease, "healthy")
-        disease_oid = disease_map.get(disease_code)
+        raw_disease = str(row.get("predicted_disease", "")).strip()
+        disease_code = DISEASE_NAME_TO_CODE.get(raw_disease) or raw_disease.lower().replace(" ", "_")
+        disease_oid = disease_map.get(disease_code)
```

### Sửa đổi 2: Tối ưu hóa hiệu năng lưu trữ và xóa bỏ N+1 Queries trong `load_documents`
Thay thế đoạn xử lý inspections từ dòng 1202 tới 1233 bằng phiên bản tối ưu hóa bộ nhớ:

```python
    # Tải trước trees và farms vào bộ nhớ để tránh N+1 Queries
    reloaded_farms_by_id = {f["_id"]: f for f in db.farms.find()}
    reloaded_trees_by_id = {t["_id"]: t for t in db.trees.find()}

    final_inspections = []
    for insp in inspections:
        tree_doc = reloaded_trees_by_id.get(insp["tree_id"])
        if not tree_doc:
            stats.orphan_inspections += 1
            continue

        farm_doc = reloaded_farms_by_id.get(tree_doc["farm_id"])
        if not farm_doc:
            stats.orphan_inspections += 1
            continue

        insp["farm_id"] = tree_doc["farm_id"]
        insp["zone_id"] = tree_doc.get("zone_id")
        final_inspections.append(insp)
```

### Sửa đổi 3: Tối ưu hóa hiệu năng trong bước Validation
Thay thế khối check toàn vẹn tham chiếu từ dòng 1436 tới 1502:

```python
        # Tải ID cha dưới dạng Set để lookup O(1)
        company_ids = {c["_id"] for c in db.companies.find({}, {"_id": 1})}
        farm_ids = {f["_id"] for f in db.farms.find({}, {"_id": 1})}
        zone_ids = {z["_id"] for z in db.zones.find({}, {"_id": 1})}
        tree_ids = {t["_id"] for t in db.trees.find({}, {"_id": 1})}
        disease_ids = {d["_id"] for d in db.diseases.find({}, {"_id": 1})}
        inspection_ids = {i["_id"] for i in db.inspections.find({}, {"_id": 1})}

        # Farms -> Companies
        orphan_farms = sum(1 for f in db.farms.find({"company_id": {"$exists": True}}) 
                           if f["company_id"] not in company_ids)
        stats.orphan_farms = orphan_farms
        logger.info("  Orphan farms (no company): %d", orphan_farms)

        # Zones -> Farms
        orphan_zones = sum(1 for z in db.zones.find({"farm_id": {"$exists": True}}) 
                           if z["farm_id"] not in farm_ids)
        stats.orphan_zones = orphan_zones
        logger.info("  Orphan zones (no farm): %d", orphan_zones)

        # Trees -> Farms, Zones
        orphan_trees_farm = sum(1 for t in db.trees.find() if t["farm_id"] not in farm_ids)
        orphan_trees_zone = sum(1 for t in db.trees.find() 
                                if t.get("zone_id") and t["zone_id"] not in zone_ids)
        stats.orphan_trees = orphan_trees_farm + orphan_trees_zone
        logger.info("  Orphan trees (no farm): %d", orphan_trees_farm)
        logger.info("  Orphan trees (no zone): %d", orphan_trees_zone)

        # Inspections -> Trees, Diseases
        orphan_insp_tree = sum(1 for ins in db.inspections.find() if ins["tree_id"] not in tree_ids)
        orphan_insp_disease = sum(1 for ins in db.inspections.find() 
                                  if ins.get("disease_id") and ins["disease_id"] not in disease_ids)
        stats.orphan_inspections = orphan_insp_tree + orphan_insp_disease
        logger.info("  Orphan inspections (no tree): %d", orphan_insp_tree)
        logger.info("  Orphan inspections (no disease): %d", orphan_insp_disease)

        # Detection Results -> Inspections
        orphan_detections = sum(1 for dr in db.detection_results.find() 
                                if dr["inspection_id"] not in inspection_ids)
        logger.info("  Orphan detection results (no inspection): %d", orphan_detections)

        # Disease History -> Trees
        orphan_history = sum(1 for dh in db.disease_history.find() if dh["tree_id"] not in tree_ids)
        logger.info("  Orphan disease history (no tree): %d", orphan_history)

        # Alerts -> Farms, Trees
        orphan_alerts_farm = sum(1 for al in db.alerts.find() if al["farm_id"] not in farm_ids)
        orphan_alerts_tree = sum(1 for al in db.alerts.find() if al["tree_id"] not in tree_ids)
        logger.info("  Orphan alerts (no farm): %d", orphan_alerts_farm)
        logger.info("  Orphan alerts (no tree): %d", orphan_alerts_tree)
```
