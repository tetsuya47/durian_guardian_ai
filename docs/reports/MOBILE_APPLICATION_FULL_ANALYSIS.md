# Báo cáo Phân tích Toàn diện Ứng dụng Mobile — Durian Guardian AI

> **Phạm vi báo cáo:** Ứng dụng Flutter `dga_mobile` (thư mục con của repo `durian_guardian_ai`).
> **Phương pháp:** Đọc toàn bộ mã nguồn ở chế độ **chỉ đọc** (read-only), không sửa/format/refactor, không tạo mã mới.
> **Ngày:** 03/08/2026

---

## Mục lục

1. [Tổng quan dự án](#1-tổng-quan-dự-án)
2. [Mục tiêu và phạm vi ứng dụng](#2-mục-tiêu-và-phạm-vi-ứng-dụng)
3. [Kiến trúc tổng thể](#3-kiến-trúc-tổng-thể)
4. [Tổ chức thư mục](#4-tổ-chức-thư-mục)
5. [Stack công nghệ và dependencies](#5-stack-công-nghệ-và-dependencies)
6. [Cấu hình môi trường](#6-cấu-hình-môi-trường)
7. [Hạ tầng mạng và API client](#7-hạ-tầng-mạng-và-api-client)
8. [Interceptors và xác thực token](#8-interceptors-và-xác-thực-token)
9. [Quản lý state với Riverpod](#9-quản-lý-state-với-riverpod)
10. [Điều hướng với go_router](#10-điều-hướng-với-go_router)
11. [Lưu trữ cục bộ](#11-lưu-trữ-cục-bộ)
12. [Xử lý lỗi và kết quả bất đồng bộ](#12-xử-lý-lỗi-và-kết-quả-bất-đồng-bộ)
13. [Theme, localization và design system](#13-theme-localization-và-design-system)
14. [Tính năng Xác thực (Authentication)](#14-tính-năng-xác-thực-authentication)
15. [Màn hình Splash và Onboarding](#15-màn-hình-splash-và-onboarding)
16. [Tính năng Dashboard](#16-tính-năng-dashboard)
17. [Tính năng Phát hiện bệnh (Disease Detection)](#17-tính-năng-phát-hiện-bệnh-disease-detection)
18. [Camera Simulator và Image Editor Wizard](#18-camera-simulator-và-image-editor-wizard)
19. [Tính năng Khuyến nghị (Recommendation)](#19-tính-năng-khuyến-nghị-recommendation)
20. [Tính năng Lịch sử (History), So sánh và Bảng xếp hạng](#20-tính-năng-lịch-sử-history-so-sánh-và-bảng-xếp-hạng)
21. [Tính năng Thời tiết (Weather)](#21-tính-năng-thời-tiết-weather)
22. [Tính năng Hồ sơ (Profile)](#22-tính-năng-hồ-sơ-profile)
23. [Tính năng Cài đặt (Settings)](#23-tính-năng-cài-đặt-settings)
24. [Tính năng Đăng ký vườn (Register Farm)](#24-tính-năng-đăng-ký-vườn-register-farm)
25. [Tính năng IoT (Cửa hàng và Quản lý thiết bị)](#25-tính-năng-iot-cửa-hàng-và-quản-lý-thiết-bị)
26. [Tích hợp AI Backend](#26-tích-hợp-ai-backend)
27. [Đánh giá, rủi ro và đề xuất cải tiến](#27-đánh-giá-rủi-ro-và-đề-xuất-cải-tiến)
28. [Kết luận](#28-kết-luận)

---

## 1. Tổng quan dự án

| Thuộc tính | Giá trị |
|---|---|
| Tên dự án | Durian Guardian AI |
| Tên ứng dụng di động | `dga_mobile` |
| Nền tảng | Flutter (Dart) |
| Đối tượng | Nông dân / quản lý vườn sầu riêng |
| Hệ sinh thái | Mobile app + Backend (FastAPI) + AI model (EfficientNet-B0) |
| Ngôn ngữ UI | Tiếng Việt |

**Mô tả:** Durian Guardian AI là một hệ thống hỗ trợ quản lý vườn sầu riêng thông minh. Ứng dụng di động cho phép người dùng chụp ảnh lá cây để phát hiện bệnh bằng AI, xem khuyến nghị chăm sóc, theo dõi thời tiết, quản lý vườn (farms/zones/trees), xem lịch sử scan, quản lý hồ sơ và cài đặt, cùng giao diện mua sắm/quản lý thiết bị IoT.

---

## 2. Mục tiêu và phạm vi ứng dụng

### 2.1 Mục tiêu
- Cung cấp công cụ **phát hiện bệnh trên lá sầu riêng bằng AI** trực tiếp trên điện thoại (upload ảnh qua API).
- Cung cấp **khuyến nghị chăm sóc** dựa trên kết quả chẩn đoán.
- Hiển thị **thông tin thời tiết và cảnh báo nguy cơ nấm bệnh** theo thời gian thực.
- Quản lý **vườn, khu vực, cây** và lịch sử kiểm tra.
- Quản lý **hồ sơ người dùng, cài đặt ứng dụng**.
- Giao diện quản lý thiết bị **IoT** (hiện là UI mock).

### 2.2 Phạm vi đã triển khai (theo mã nguồn)
- Đầy đủ 13 màn hình chính với route đã đăng ký (xem mục 10).
- Luồng xác thực hoàn chỉnh: đăng nhập, đăng ký, quên mật khẩu, đổi mật khẩu, đăng xuất.
- Luồng chính "scan bệnh → kết quả → khuyến nghị" kết nối API thật.
- Nhiều tính năng hiện dùng **mock dữ liệu / hardcode** (IoT, một phần dashboard, một phần lịch sử).

### 2.3 Ngoài phạm vi / chưa hoàn thiện
- IoT shop và quản lý thiết bị: **UI mock**, chưa gọi API.
- Một số repository remote datasource còn `throw UnimplementedError` (HistoryLocalDataSource, SettingsRemoteDataSource).
- Image Quality check và Chat recommendation ở backend **vẫn còn mock** (xem mục 26).

---

## 3. Kiến trúc tổng thể

Ứng dụng kết hợp hai mô hình:

### 3.1 Feature-First (tổ chức theo tính năng)
Mỗi tính năng nằm trong thư mục `lib/features/<tên_tính_năng>/` với các tầng rõ ràng:
- `domain/` — entities, repository interfaces (abstract), use-cases (nếu có).
- `data/` — DTOs, mappers, datasources (remote/local/mock), repository implementations.
- `presentation/` — pages, widgets, providers (Riverpod).

### 3.2 Clean Architecture (phân tầng)
```
Domain (entities + abstract repos + use-cases)
   ▲
Data (DTOs + mappers + datasources + repo impls)
   ▲
Presentation (Riverpod providers + widgets + pages)
```

**Luồng dữ liệu điển hình:**
```
Page (ConsumerWidget)
  → Riverpod Provider (FutureProvider)
    → RepositoryImpl
      → DataSource (Remote: DioApiClient / Local: StorageService / Mock)
        → API Backend (FastAPI)
```

### 3.3 Dependency Injection
- Dùng `riverpod` làm container DI.
- `ProviderScope` trong `main.dart` override `storageServiceProvider`.
- `dioApiClientProvider` phụ thuộc vào `storageServiceProvider` để đọc/ghi token (xem `core/network/dio_api_client.dart:189`).

### 3.4 Mock song song thực tế
Kiến trúc hỗ trợ song song cả datasource thật và mock:
- `MockAuthRepository`, `MockHistoryRepository`, `MockProfileDatasource`, `MockDashboardDatasource`, `MockDiseaseDetectionDatasource`, `MockRecommendationDatasource`.
- Recommendation remote datasource có **fallback hardcode** khi API lỗi.

---

## 4. Tổ chức thư mục

```
dga_mobile/
├── lib/
│   ├── main.dart                        # Entry point, ProviderScope, MaterialApp.router
│   ├── config/
│   │   ├── routes/
│   │   │   ├── app_router.dart          # go_router + redirect guard auth
│   │   │   └── route_names.dart         # RouteNames constants
│   │   └── router_guards/               # Auth guard (redirect logic)
│   ├── core/
│   │   ├── constants/                   # StorageKeys, AppConstants...
│   │   ├── errors/                      # AppException + exception mapping
│   │   ├── localization/                # Chuỗi tiếng Việt, lang helper
│   │   ├── network/                     # environment_config, api_endpoints, dio_api_client, interceptors, network_foundation, result
│   │   ├── theme/                       # ColorScheme, theme, GoogleFonts
│   │   └── utils/                       # Các hàm tiện ích
│   ├── services/
│   │   ├── storage_service.dart         # SharedPreferences + FlutterSecureStorage
│   │   ├── connectivity_service.dart    # Internet connection checker
│   │   ├── logger_service.dart          # logger
│   │   └── api_service.dart             # ApiService abstraction
│   ├── features/
│   │   ├── authentication/
│   │   ├── dashboard/
│   │   ├── disease_detection/
│   │   ├── recommendation/
│   │   ├── history/
│   │   ├── weather/
│   │   ├── profile/
│   │   ├── settings/
│   │   ├── farms/
│   │   └── iot/
│   ├── shared/
│   │   ├── tab_scaffold.dart            # Scaffold với bottom nav
│   │   ├── widgets/                     # Cards, buttons, skeletons, dialogs, empty states...
│   │   └── ...
└── pubspec.yaml
```

---

## 5. Stack công nghệ và dependencies

| Nhóm | Package | Vai trò |
|---|---|---|
| State management | `flutter_riverpod` | DI + state (ProviderScope, FutureProvider, StateProvider...) |
| Navigation | `go_router` | Routing + deep-link + guard |
| Networking | `dio` | HTTP client, interceptors, multipart |
| Storage | `flutter_secure_storage` | Lưu token an toàn (access/refresh) |
| Storage | `shared_preferences` | Cache nhẹ (settings, cache scan, onboarding flag...) |
| Hình ảnh | `image_picker` | Chụp/chọn ảnh |
| Hình ảnh | `cached_network_image` | Cache ảnh từ server |
| Font | `google_fonts` | Font chữ |
| Logging | `logger` | Log hệ thống |
| Connectivity | `internet_connection_checker` | Kiểm tra kết nối mạng |
| Định dạng | `intl` | Định dạng ngày/giờ, số |
| UI framework | `flutter` | Material Design |

**Ghi chú kiến trúc:** Không dùng `go_router` extensions cho redirect guard riêng mà có thư mục `config/router_guards/`.

---

## 6. Cấu hình môi trường

Tập trung tại `lib/core/network/environment_config.dart`:

| Tham số | Giá trị |
|---|---|
| `_activeEnv` | `_Env.device` (mặc định chạy dev) |
| `deviceHost` | `127.0.0.1` |
| `baseUrl` (dev) | `http://127.0.0.1:8000/api/v1` |
| `baseUrl` (production) | `https://api.durian-guardian.ai/v1` |
| `uploadsBaseUrl` | `<baseUrl gốc>/uploads` (dùng cho ảnh từ server) |

**Nhận xét:** Có sẵn cấu hình production; việc chuyển môi trường được kiểm soát qua `_activeEnv`. Dev base URL trỏ về `127.0.0.1:8000` (FastAPI backend chạy local).

---

## 7. Hạ tầng mạng và API client

### 7.1 `DioApiClient` (`core/network/dio_api_client.dart`)
- Base URL từ `EnvironmentConfig.baseUrl`.
- Timeout theo `TimeoutConfig`: connect / receive / send (30 giây).
- `responseType: json`, `contentType: application/json`, header `Accept: application/json`.
- Các phương thức:
  - `request<T>()` — generic GET/POST/PUT/DELETE, decode qua `decoder` callback.
  - `requestMultipart<T>()` — POST `multipart/form-data` cho upload ảnh scan.
  - Helpers: `get/post/put/delete`.
- Chuyển `DioException` → `AppException` (ưu tiên lấy `e.error` nếu đã là `AppException` do interceptor bọc).

### 7.2 `ResponseWrapper<T>`
Contract chuẩn cho mọi response từ backend:
```
{ data, message, status_code, success }
```
- `decoder` do từng repository cung cấp để parse `data` → DTO → Entity.

### 7.3 `ApiEndpoints` (`core/network/api_endpoints.dart`)
Danh sách endpoint đầy đủ:

| Nhóm | Endpoint | Ghi chú |
|---|---|---|
| Auth | `POST /auth/login` | Đăng nhập |
| Auth | `POST /auth/register` | Đăng ký |
| Auth | `POST /auth/refresh` | Refresh token |
| Auth | `POST /auth/logout` | Đăng xuất |
| Auth | `GET /auth/me` | Thông tin user (profile) |
| Auth | `PUT/POST /auth/profile` | Cập nhật hồ sơ |
| Auth | `POST /auth/change-password` | Đổi mật khẩu |
| Farm | `GET/POST /farms` | Quản lý vườn |
| Zone | `/zones` | Khu vực |
| Tree | `GET/POST /trees` | Cây trồng |
| Tree | `GET /trees/{id}/digital-id` | Mã định danh số của cây |
| AI | `POST /ai/detect` | Phát hiện bệnh (multipart) |
| AI | `POST /ai/image-quality` | Kiểm tra chất lượng ảnh |
| Dashboard | `GET /dashboard` | Tổng quan |
| Dashboard | `GET /dashboard/heatmap` | Heatmap vườn |
| Weather | `GET /weather/current` | Thời tiết hiện tại |
| Chat/Recommendation | `POST /chat` | Khuyến nghị chăm sóc |
| History | `GET /trees` + `historyByTree(treeId)` | Lịch sử scan theo cây |

---

## 8. Interceptors và xác thực token

Thứ tự interceptor trong `DioApiClient`:
1. `LoggingInterceptor` — log request/response (chỉ build debug).
2. `AuthInterceptor` — bơm token + xử lý refresh 401.
3. `ErrorInterceptor` — bọc `DioException` → `AppException`.

### 8.1 `AuthInterceptor`
- Đọc access token từ `FlutterSecureStorage` (key `StorageKeys.token`) qua `tokenReader`.
- Bơm `Authorization: Bearer <token>` vào header.
- Khi nhận **401**: gọi `POST /auth/refresh` bằng refresh token để xoay vòng token mới.
  - Thành công → ghi token mới (`tokenWriter` + `refreshTokenWriter`), **retry lại request 1 lần**.
  - Thất bại → xóa phiên (`sessionClearer`): xóa access token, refresh token và `latest_scanned_disease`.

### 8.2 `sessionClearer` (dio_api_client.dart:196)
```dart
await storageService.deleteSecure(StorageKeys.token);
await storageService.deleteSecure(StorageKeys.refreshToken);
await storageService.remove('latest_scanned_disease');
```

### 8.3 `ErrorInterceptor`
- Bọc mọi `DioException` thành `AppException` với message thân thiện.

---

## 9. Quản lý state với Riverpod

Các loại provider được dùng:
- **`Provider`** — dịch vụ đơn (dio client, storage, repositories).
- **`FutureProvider`** — dữ liệu bất đồng bộ (dashboard, weather, history, profile, settings).
- **`StateProvider`** — state tạm trên UI (query tìm kiếm, filter, sort trong history; settings).
- **`StateNotifierProvider`** — state phức tạp có logic.

**Ví dụ chi tiết:**
- `dashboardDataProvider` (FutureProvider) — tổng hợp số liệu dashboard.
- `currentWeatherProvider` (FutureProvider) — thời tiết hiện tại.
- `historyRawLogsProvider` + `filteredHistoryLogsProvider` + state providers (query `''`, filter `'Tất cả'`, timeFilter `'Tất cả'`, sort `'Mới nhất'`).
- `appSettingsProvider` + `settingsStateProvider` — cài đặt ứng dụng.
- `userProfileProvider` — hồ sơ người dùng (load lazy, chỉ khi vào Profile).

---

## 10. Điều hướng với go_router

`RouteNames` đầy đủ (`config/routes/route_names.dart`) và `AppRouter` (`config/routes/app_router.dart`):

| Route | Màn hình |
|---|---|
| splash | SplashScreen |
| onboarding | OnboardingScreen |
| login | LoginScreen |
| forgot-password | ForgotPasswordScreen |
| dashboard | DashboardScreen |
| disease-detection | DiseaseDetectionScreen |
| recommendation | RecommendationScreen |
| history | HistoryScreen |
| profile | ProfileScreen |
| settings | SettingsScreen |
| camera-simulator | CameraSimulatorScreen |
| image-editor-wizard | ImageEditorWizardScreen |
| register-farm | RegisterFarmScreen |
| iot-shop | IotShopScreen |
| iot-management | IotManagementScreen |

**Guard:** có `config/router_guards/` thực hiện redirect dựa trên trạng thái đăng nhập (auth guard) — ví dụ chưa đăng nhập → redirect login, có session → bỏ qua splash/onboarding.

---

## 11. Lưu trữ cục bộ

`StorageService` (`services/storage_service.dart`) bọc 2 nền tảng:

| Loại | Storage | Key sử dụng |
|---|---|---|
| Secure | `FlutterSecureStorage` | `StorageKeys.token`, `StorageKeys.refreshToken` |
| Nhẹ | `SharedPreferences` | `app_settings`, `cached_scan_results`, `latest_scanned_disease`, onboarding flag... |

**Các cache quan trọng:**
- `cached_scan_results` (disease_detection): cache tối đa **50** kết quả scan, key trong SharedPreferences.
- `latest_scanned_disease`: bệnh phát hiện gần nhất — là cầu nối giữa Disease Detection → Recommendation (ghi ở `disease_detection_repository_impl.dart:166`, đọc ở `recommendation_repository_impl.dart:17`, mặc định `'Healthy'`).

---

## 12. Xử lý lỗi và kết quả bất đồng bộ

### 12.1 `AppException`
- Tầng `core/errors/` định nghĩa `AppException` và mapping lỗi (dựa theo HTTP status code / backend `status_code`).
- Message thân thiện tiếng Việt, hiển thị qua dialog/snackbar.

### 12.2 Sealed `Result<T>` (`core/network/result.dart`)
```dart
sealed class Result<T>
├── Success<T>   { T data }
├── Failure<T>   { AppException error }
├── Loading<T>
└── Empty<T>
```
- Dùng cho các luồng có trạng thái rõ ràng: idle / loading / success / error / empty.
- Được dùng ở các page như Recommendation (idle → loading → success/error).

---

## 13. Theme, localization và design system

- **Theme:** `core/theme/` — Material 3 `ColorScheme`, theme sáng/tối/"theo hệ thống", font `google_fonts`.
- **Chuỗi UI:** `core/localization/` — toàn bộ chuỗi tiếng Việt, helper `Lang`.
- **Design system:** `shared/widgets/`:
  - `TabScaffold` + bottom navigation (5 tab chính).
  - Cards (dashboard, weather, health...), buttons, skeletons (loading), dialogs, empty states.
- **Style nhất quán:** gradient trạng thái (đỏ = nguy hiểm, cam = cảnh báo, xanh = an toàn) — ví dụ WeatherCard và AIFarmStatusCard.

---

## 14. Tính năng Xác thực (Authentication)

**Thư mục:** `features/authentication/` (domain/data/presentation hoàn chỉnh).

### 14.1 Luồng
- **Login:** `AuthRepositoryImpl.login` → `POST /auth/login` → lưu access + refresh token → `GET /auth/me` để lấy thông tin người dùng.
- **Register:** `POST /auth/register` → tự động đăng nhập (auto-login).
- **Logout:** `POST /auth/logout` + xóa token cục bộ.
- **Quên mật khẩu / đổi mật khẩu:** qua API tương ứng.
- **Guest mode:** cho phép vào ứng dụng mà không cần đăng nhập (splash xử lý).

### 14.2 Datasource
- `AuthRemoteDataSourceImpl` — gọi API thật qua `DioApiClient`.
- `MockAuthRepository` — dữ liệu giả khi chưa có backend.

### 14.3 Màn hình
- `login_page.dart` — form đăng nhập, validation, hiển thị lỗi.
- `register_page.dart` — form đăng ký.
- `forgot_password_page.dart` — nhập email để khôi phục.
- `onboarding_page.dart` — giới thiệu tính năng trước khi vào app.

### 14.4 Widgets
- Input fields, password visibility toggle, nút submit có loading state, các validation message.

---

## 15. Màn hình Splash và Onboarding

- **Splash:** animation khởi động → load settings → quyết định hướng đi dựa trên trạng thái auth:
  - Chưa onboard → onboarding.
  - Có session → dashboard.
  - Không có session → login (hoặc guest mode).
- **Onboarding:** 3–4 trang giới thiệu (swipe), có nút "Bỏ qua" / "Bắt đầu".

---

## 16. Tính năng Dashboard

**Thư mục:** `features/dashboard/`.

### 16.1 Dữ liệu
- Entities/DTOs + mappers cho tổng quan vườn.
- 3 datasource: remote (`GET /dashboard`, `GET /dashboard/heatmap`), local, mock.
- `DashboardRepositoryImpl` + `dashboardDataProvider` (FutureProvider).

### 16.2 Màn hình & widgets (8 widgets)
| Widget | Chức năng |
|---|---|
| `DashboardAppBar` | Thanh tiêu đề |
| `AIFarmStatusCard` | Trạng thái tổng quan vườn (gradient theo sức khỏe) |
| `DashboardWeatherCard` | Thời tiết thu gọn (liên kết weather) |
| `QuickActionsGrid` | Lưới hành động nhanh (scan, recommendation, history...) |
| `QuickStatsGrid` | Thống kê nhanh |
| `RecentInspectionsList` | Danh sách kiểm tra gần đây |
| `DashboardAlertsCard` | Cảnh báo (nấm bệnh, thời tiết nguy hiểm...) |
| ... | Các card phụ |

---

## 17. Tính năng Phát hiện bệnh (Disease Detection)

**Thư mục:** `features/disease_detection/`.

### 17.1 API contract
- **`detectDisease(treeId, imagePath)`** → `POST /ai/detect` (multipart: ảnh + `tree_id`).
- **`checkImageQuality(imagePath)`** → `POST /ai/image-quality`.

**`DetectionResponseDto` (parsing backend):**
```
tree_id, image_url,
detection: { disease, confidence, severity },
created_at,
heatmap_url?, overlay_url?,
risk_level?, risk_probability?, recommendation?, processing_time_ms?
```

**`ImageQualityResponseDto`:**
```
blur: bool, brightness: string, leaf_detected: bool, passed: bool
```

### 17.2 Luồng UI
1. User chọn ảnh (image_picker) → **checkImageQuality** kiểm tra trước.
2. Nếu không đạt → yêu cầu chụp lại.
3. Nếu đạt → **detectDisease** upload → hiển thị kết quả (tên bệnh, confidence, severity, thông tin bệnh, ảnh gốc/heatmap/overlay).
4. Lưu vào cache local `cached_scan_results` (max 50) và `latest_scanned_disease` → dùng cho Recommendation.

### 17.3 Chi tiết triển khai
- `DiseaseDetectionRepositoryImpl` (line 166) ghi `latest_scanned_disease` bằng `storageService.setString`.
- `MockDiseaseDetectionDatasource` — dữ liệu giả khi chưa có backend.
- Màn hình: `disease_detection_page.dart`, `camera_simulator_page.dart`, `image_editor_wizard_page.dart`.
- 9 widgets hỗ trợ (upload card, result card, quality check banner, confidence meter...).

---

## 18. Camera Simulator và Image Editor Wizard

- **Camera Simulator:** mô phỏng khung camera chụp ảnh lá (dùng cho demo khi thiếu phần cứng/device).
- **Image Editor Wizard:** hướng dẫn cắt/xử lý ảnh trước khi gửi AI — cải thiện chất lượng ảnh để tăng độ chính xác phát hiện.

---

## 19. Tính năng Khuyến nghị (Recommendation)

**Thư mục:** `features/recommendation/`.

### 19.1 Entities
- `WeatherAdvisoryEntity`, `CareRecommendationEntity`, `CareScheduleEntity`, `MaterialDetailEntity`, `RecommendationResultEntity`.

### 19.2 Dữ liệu
- `RecommendationRemoteDataSourceImpl.getRecommendations(diseaseName)` → `POST /chat` với:
  - `question` = câu hỏi xin lời khuyên chăm sóc cho bệnh.
  - `tree_id` = id giả định `'60d5ec49f1b2c56b402c56b5'`.
- **Fallback khi API lỗi:** chuỗi khuyến nghị + heuristic `riskLevel`:
  - `healthy` → `'Nguy cơ thấp'`
  - chứa `rot`/`phytophthora` → `'Nguy cơ cao'`
  - còn lại → `'Nguy cơ trung bình'`
- `RecommendationRepositoryImpl` đọc `latest_scanned_disease` từ storage (mặc định `'Healthy'`).

### 19.3 Màn hình & widgets
- `recommendation_page.dart` — state máy: idle → loading → success/error; nút chia sẻ/in.
- `WeatherConditionsCard` — điều kiện thời tiết (ưu tiên `currentWeatherProvider`).
- `HealthSummaryCard` — tóm tắt sức khỏe cây.
- `CareRecommendationsList` — danh sách khuyến nghị.
- `CareTimeline` — lịch trình chăm sóc.
- `SuggestedMaterialsTable` — vật tư đề xuất.
- `SmartTaskListCard` — danh sách việc cần làm (checkbox stateful, **hardcode**).
- `DiseaseCalculatorCard` — tính liều thuốc theo bệnh/tuổi cây/số cây/bình xịt.
- `AINotesCard` — ghi chú từ AI.
- `RecommendationActionButtons`, `RecommendationLoadingWidget`.

---

## 20. Tính năng Lịch sử (History), So sánh và Bảng xếp hạng

**Thư mục:** `features/history/`.

### 20.1 Dữ liệu
- `HistoryRepositoryImpl.getHistoryLogs()`:
  - `GET /trees` → ánh xạ `treeMap[id] = tree_code` (fallback id `'6a6cc2ba3432b70022fba65d'`).
  - Query lịch sử theo batch 30 cây (tối đa 150 cây) qua `ApiEndpoints.historyByTree(treeId)`.
  - Gộp log, sort/limit.
- `HistoryLocalDataSourceImpl`: **chưa implement** (`throw UnimplementedError`).
- `MockHistoryDatasource.generate30Logs()` — dùng `Random(42)` (deterministic).
- `MockHistoryRepository` — delay giả lập 1.2s.

### 20.2 State (Riverpod)
- `historyRawLogsProvider` (FutureProvider)
- `filteredHistoryLogsProvider` + state providers: `query ''`, `filter 'Tất cả'`, `timeFilter 'Tất cả'`, `sort 'Mới nhất'`.

### 20.3 Màn hình & widgets
- `history_page.dart` — AppBar có nút So sánh/…, search/filter/sort, stats card, ListView, bottom sheet chi tiết.
- `compare_page.dart` — chọn 2 log (Before/After) → so sánh ảnh + thông tin.
- `leaderboard_page.dart` — TabController, mock 4 khu A–D (điểm, healthy_rate, inspect_count).
- `history_statistics_card`, `history_search_bar`, `history_filter_bar` (FilterChip loại bệnh + thời gian + sort), `history_detail_sheet`, `history_card` (dùng `CachedNetworkImage`), `empty_history_widget`.

---

## 21. Tính năng Thời tiết (Weather)

**Thư mục:** `features/weather/`.

### 21.1 Dữ liệu
- `WeatherCurrentDto`: `locationName, tempCelsius, feelsLikeCelsius, humidityPercent, windSpeedMS, description, iconUrl, fungalDiseaseRisk, agriculturalAdvice`.
- `WeatherRemoteDataSourceImpl.getCurrentWeather()` → `GET /weather/current`; fallback constant khi `response.data` null.
- `currentWeatherProvider` (FutureProvider).

### 21.2 UI
- `weather_card.dart`: gradient theo risk —
  - `HIGH` → cam/đỏ + badge **"CẢNH BÁO NẤM BỆNH CAO"**
  - `MEDIUM` → cam + badge **"CHÚ Ý NẤM BỆNH"**
  - `LOW` → xanh lá + badge **"THỜI TIẾT AN TOÀN"**
- Hiển thị: nhiệt độ, cảm giác, độ ẩm, tốc độ gió, mô tả, lời khuyên nông nghiệp.

---

## 22. Tính năng Hồ sơ (Profile)

**Thư mục:** `features/profile/`.

### 22.1 Dữ liệu
- Entities: `UserProfileEntity` (kèm `FarmEntity` + `ProfileStatsEntity`).
- `ProfileRemoteDataSourceImpl.getUserProfile()` → `GET /auth/me` (`UserOutDto`):
  - Map vai trò UI; phone/workUnit/address/dob/gender/farmInfo để trống khi backend chưa trả.
  - Stats khởi tạo = 0.
- `updateUserProfile` → `PUT/POST /auth/profile`.
- `MockProfileDatasource`: "Nguyễn Văn Nông", vườn "Vườn Sầu Riêng Phong Điền", DGA-FARM-99, 368 cây, stats 142/18/35/94.5.

### 22.2 Màn hình & widgets
- `profile_page.dart` — load khi `userProfile` null; state idle/loading/loaded/error; nút Chỉnh sửa → `EditProfileSheet`; menu items.
- `profile_header` (avatar + edit badge), `profile_statistics` (2×2 grid), `profile_information_card`, `farm_information_card`, `profile_menu_item`, `edit_profile_sheet` (form 3 trường).

---

## 23. Tính năng Cài đặt (Settings)

**Thư mục:** `features/settings/`.

### 23.1 Dữ liệu
- `AppSettingsEntity`: `themeMode` (Sáng/Tối/Theo hệ thống), `language` (mặc định Tiếng Việt), `NotificationSettingsEntity`, `SecuritySettingsEntity`, `CacheDetailsEntity`.
- `SettingsRepositoryImpl` — **local-only**: `SettingsLocalDataSourceImpl` lưu JSON vào `StorageService` key `app_settings` (default từ `_defaultSettingsJson`).
- `SettingsRemoteDataSourceImpl` — `throw UnimplementedError`.
- Providers: `appSettingsProvider` + `settingsStateProvider`.

### 23.2 Màn hình & widgets
- `settings_page.dart` — theme sheet, switch notifications/security, clear cache, đăng xuất, giới thiệu.
- `theme_bottom_sheet` ('Sáng'/'Tối'/'Theo hệ thống'), `settings_tile`, `settings_switch_tile`, `settings_section`, `settings_card`, `about_card` ("Durian Guardian AI", v1.0.0 Build 24).

---

## 24. Tính năng Đăng ký vườn (Register Farm)

- `register_farm_page.dart` — form trực tiếp dùng `dioApiClientProvider`:
  - `POST` payload: `farm_name`, `location`, `area_hectare`, `tree_count`, `description`...
  - Sau khi thành công → gọi `refresh` trên `dashboardDataProvider` → pop về.

---

## 25. Tính năng IoT (Cửa hàng và Quản lý thiết bị)

**Thư mục:** `features/iot/`. **Toàn bộ là UI mock, không gọi API.**

### 25.1 `iot_shop_page.dart`
- TabController, danh sách sản phẩm mock (`IoTItem`):
  - Gateway AI LoRaWAN/4G — 2.500.000đ
  - Cảm Biến Đất Đa Tầng — 850.000đ
  - Trạm Thời Tiết Realtime — 1.800.000đ
  - ... (một số sản phẩm khác)

### 25.2 `iot_management_page.dart`
- Danh sách thiết bị mock: `SEN-SOIL-01`, `SEN-WX-02`, `GW-MAIN-01`, `SEN-SOIL-03` với `status/battery/signal/moisture/last_sync`.
- Modal thêm thiết bị (nhập mã + tên).

---

## 26. Tích hợp AI Backend

> Chi tiết xem thêm: `docs/reports/AI_INTEGRATION_DIFF_REPORT.md` và `docs/reports/AI_MODEL_DEPLOYMENT_AUDIT.md`.

### 26.1 Trạng thái hiện tại (Git HEAD vs working tree)
| Thành phần | Git HEAD (đã commit) | Working tree (chưa commit) |
|---|---|---|
| `backend/app/ai/predictor.py` | `_mock_detection()` | **Model thật** |
| Model | — | EfficientNet-B0, **11 classes** |
| Checkpoint | — | `training/checkpoints/disease_detection/best_model.pt` |
| Hiệu năng model | — | Test accuracy **94.23%**, macro F1 **0.94** |
| `check_image_quality()` | hardcoded | hardcoded (chưa cải thiện) |
| `chat()` | `_mock_chat()` | `_mock_chat()` (chưa thay) |

### 26.2 Endpoint AI từ phía mobile
| Endpoint | Dùng cho | Trạng thái backend |
|---|---|---|
| `POST /ai/detect` | Phát hiện bệnh | Model thật (working tree), mock (HEAD) |
| `POST /ai/image-quality` | Kiểm tra ảnh | Còn hardcoded |
| `POST /chat` | Khuyến nghị | Còn `_mock_chat()` |

### 26.3 Rủi ro đã ghi nhận
- Working tree chạy model thật nhưng **chưa commit** — nếu mất working tree sẽ mất model.
- `check_image_quality()` chưa dùng model/vision thật.
- `chat()` vẫn trả lời mock — Recommendation trên app phụ thuộc fallback hardcode.
- Thiếu input validation phía backend.
- Severity tính theo heuristic.
- Lỗi typo nhãn class: `stem_cracking_ gummosis` (dấu cách thừa).

### 26.4 Luồng AI end-to-end trong app
```
Chụp ảnh → /ai/image-quality (kiểm tra) → /ai/detect (chẩn đoán)
        → lưu latest_scanned_disease → /chat (khuyến nghị, fallback local)
        → lưu cache scan (SharedPreferences, max 50)
```

---

## 27. Đánh giá, rủi ro và đề xuất cải tiến

### 27.1 Điểm mạnh
1. **Kiến trúc rõ ràng:** Feature-First + Clean Architecture, tách domain/data/presentation.
2. **DI nhất quán:** Riverpod bao toàn bộ, dễ override mock ↔ thật.
3. **Xử lý refresh token bài bản:** 401 → refresh → retry 1 lần; fail → xóa sạch phiên.
4. **Contract API thống nhất:** `ResponseWrapper` + sealed `Result<T>` + `AppException`.
5. **Offline/cache tốt:** cache scan (50 bản), settings local, fallback khi API lỗi.
6. **Mock determinism:** `Random(42)` cho lịch sử giúp test ổn định.
7. **UI phong phú:** gradient trạng thái nhất quán, skeleton loading, empty states.

### 27.2 Điểm yếu / rủi ro
1. **Chưa hoàn thiện ở các vùng:** IoT (mock), HistoryLocalDataSource (`UnimplementedError`), SettingsRemoteDataSource (`UnimplementedError`).
2. **AI backend chưa đồng bộ:** model thật chưa commit; quality check và chat còn mock → toàn bộ "recommendation AI" trên app thực chất là hardcode fallback.
3. **Hardcode nhạy cảm:**
   - `tree_id` giả định `'60d5ec49f1b2c56b402c56b5'` trong Recommendation.
   - `treeId` fallback `'6a6cc2ba3432b70022fba65d'` trong History.
   - `SmartTaskListCard` hardcode nội dung.
4. **Security:** base URL dev HTTP (`http://127.0.0.1:8000`) — chỉ dùng local; cần đảm bảo production dùng HTTPS (đã có cấu hình).
5. **Mock profile stats:** trả về số liệu ảo khi backend chưa cung cấp → rủi ro hiển thị dữ liệu sai.
6. **Chưa có nhận diện thất bại AI rõ:** dựa vào `passed` của image-quality nhưng message lỗi cần chuẩn hóa.
7. **i18n:** chuỗi tiếng Việt tập trung ở `core/localization` nhưng chưa thấy cơ chế đa ngôn ngữ đầy đủ (chỉ tiếng Việt).

### 27.3 Đề xuất cải tiến (ưu tiên)
1. **Commit working tree AI** (predictor thật) lên Git, thêm CI chạy test accuracy.
2. Thay `_mock_chat()` bằng LLM/template thật hoặc truy vấn knowledge-base; trước mắt giữ fallback nhưng đánh dấu rõ nguồn dữ liệu.
3. Thay `check_image_quality` hardcode bằng model light (blur/motion/brightness classifier).
4. Bỏ/chuẩn hóa các `tree_id` dummy — truyền `tree_id` thật từ màn hình chọn cây.
5. Implement `HistoryLocalDataSourceImpl` và `SettingsRemoteDataSourceImpl` hoặc xóa interface chết.
6. Thêm input validation ở backend (kích thước/loại ảnh, kích thước payload).
7. Sửa typo nhãn `stem_cracking_ gummosis` và thống nhất nhãn giữa backend model ↔ `DiseaseResponseDto`.
8. Bổ sung test widget/service cho các state phức tạp (auth guard, refresh token, cache scan).
9. Cân nhắc nén ảnh trước upload để giảm băng thông/timeout (hiện để nguyên ảnh picker).

---

## 28. Kết luận

`dga_mobile` là một ứng dụng Flutter được tổ chức tốt với kiến trúc **Feature-First + Clean Architecture**, DI bằng Riverpod, hạ tầng mạng chuẩn (Dio + interceptors + refresh token), và giao diện tiếng Việt phong phú. Phần lõi AI **phát hiện bệnh** đã có luồng end-to-end hoàn chỉnh về phía mobile và đã có model thật (EfficientNet-B0, accuracy 94.23%) trong working tree của backend — nhưng **chưa được commit**, trong khi quality-check và chat recommendation vẫn còn mock.

Ứng dụng đang ở giai đoạn **gần hoàn thiện về UI/UX và kiến trúc**, còn một số vùng dữ liệu mock (IoT, một phần history/profile) và sự chưa đồng bộ giữa mobile và backend AI. Các ưu tiên rõ ràng nhất để hoàn thiện: **commit model AI**, thay chat/quality-check bằng logic thật, loại bỏ các id dummy và implement các datasource còn trống.

---
*Báo cáo được tạo từ việc đọc toàn bộ mã nguồn (read-only) của `dga_mobile`.*
