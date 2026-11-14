# CINEORA - Nền tảng Xem Phim Trực Tuyến iOS & Android Chuyên Nghiệp

> **Slogan:** *"Your Cinema. Everywhere."*  
> **Phiên bản:** 1.0.0 (Production-Ready Architecture)  
> **Thị trường mục tiêu:** Việt Nam & Quốc tế  
> **Chính sách nội dung:** 100% nội dung được cấp phép hoặc thuộc phạm vi công cộng (Public Domain).

---

## 1. Giới thiệu tổng quan

**CINEORA** là nền tảng streaming phim điện ảnh và truyền hình chất lượng cao được thiết kế cho hệ sinh thái **iOS & Android**, xây dựng theo tiêu chuẩn kiến trúc hiện đại:
- **Mobile Client:** Flutter với Material 3 Dark Cinema Theme (#090909, #151515, #E50914), State Management bằng Riverpod, Điều hướng GoRouter, Video Player tích hợp AVPlayer (iOS) và Media3 ExoPlayer (Android) với hỗ trợ HLS, DRM FairPlay/Widevine, Adaptive Bitrate, Phụ đề đa ngôn ngữ và Âm thanh vòm.
- **Backend API:** NestJS (TypeScript) theo chuẩn RESTful `/api/v1`, OpenAPI Swagger UI, PostgreSQL 16 kết hợp Prisma ORM, Redis 7 (Cache & Session Store), cơ chế xác thực JWT kép (Refresh Token Rotation) và mã hóa mật khẩu Argon2id.
- **Streaming Engine:** Kiến trúc Content Provider Adapter tách biệt logic phân phối và cấp quyền xem. Quy trình Playback Authorization kiểm tra bản quyền khu vực (Vietnam priority), kiểm tra gói thành viên, giới hạn luồng phát đồng thời và phát hành URL có chữ ký HMAC kèm thời hạn.

---

## 2. Cấu trúc thư mục dự án

```text
cineora/
├── assets/
│   └── branding/                       # Bộ tài sản nhận diện thương hiệu SVG vector
│       ├── cineora-logo-horizontal.svg # Logo ngang
│       ├── cineora-logo-vertical.svg   # Logo dọc
│       ├── cineora-app-icon.svg        # Biểu tượng ứng dụng (App Icon)
│       ├── cineora-splash.svg          # Màn hình chờ (Splash Screen)
│       ├── cineora-logo-dark.svg       # Logo nền tối
│       ├── cineora-logo-light.svg      # Logo nền sáng
│       └── cineora-logo-mono.svg       # Logo đơn sắc
├── backend/                            # NestJS Backend API Core
│   ├── prisma/                         # Prisma Schema (18 bảng) & Seed script
│   ├── src/
│   │   ├── auth/                       # Xác thực (Argon2id + JWT + Refresh Rotation)
│   │   ├── movies/                     # Quản lý kho phim & lọc nâng cao
│   │   ├── search/                     # Tìm kiếm không dấu tiếng Việt & gợi ý
│   │   ├── providers/                  # Content Provider Adapter Pattern
│   │   ├── playback/                   # Cấp quyền phát video, chữ ký URL, Heartbeat
│   │   ├── favorites/                  # Danh sách phim yêu thích
│   │   ├── watch-history/              # Tiếp tục xem & lưu tiến trình
│   │   ├── subscriptions/              # Gói thành viên & xác thực biên lai IAP
│   │   ├── users/                      # Hồ sơ & xóa tài khoản (App Store Guideline)
│   │   └── admin/                      # Quản trị nội dung & Audit Logs (RBAC)
│   ├── Dockerfile                      # Multi-stage Docker production image
│   └── package.json
├── mobile/                             # Flutter Mobile App (iOS & Android)
│   ├── lib/
│   │   ├── core/                       # Theme Dark Cinema, Router, Network, Storage
│   │   ├── data/                       # Models & Repositories
│   │   ├── features/                   # Splash, Home, Discovery, Detail, Player, Auth...
│   │   └── shared/                     # Widgets dùng chung (Image Cache, Scaffold)
│   ├── ios/                            # Cấu hình iOS, Info.plist & PrivacyInfo.xcprivacy
│   ├── android/                        # Cấu hình Android, Manifest & Gradle
│   └── pubspec.yaml
├── docs/                               # Tài liệu thiết kế & kỹ thuật chi tiết
│   ├── architecture/ARCHITECTURE.md    # Sơ đồ kiến trúc & luồng phát video
│   ├── database/DATABASE_DESIGN.md     # Đặc tả ERD và 18 bảng dữ liệu
│   ├── api/API_SPECIFICATION.md        # Đặc tả REST API & Swagger endpoints
│   ├── design/DESIGN_SYSTEM.md         # Quy chuẩn thiết kế giao diện & màu sắc
│   └── roadmap/DEVELOPMENT_ROADMAP.md  # Kế hoạch phát triển & Tiêu chí nghiệm thu
├── docker-compose.yml                  # Môi trường chạy PostgreSQL 16 + Redis 7 + Backend
└── README.md
```

---

## 3. Hướng dẫn khởi chạy môi trường Backend

### Cách 1: Khởi chạy nhanh bằng Docker Compose

Yêu cầu: Đã cài đặt Docker và Docker Compose.

```bash
# 1. Khởi động toàn bộ cụm dịch vụ (PostgreSQL, Redis, NestJS Backend)
docker compose up -d

# 2. Kiểm tra trạng thái các container
docker compose ps
```

Khi chạy thành công:
- **API Base URL:** `http://localhost:3000/api/v1`
- **Swagger Documentation:** `http://localhost:3000/api/docs`

---

### Cách 2: Khởi chạy Local Development (Node.js & PostgreSQL)

1. Cài đặt các gói thư viện:
```bash
cd backend
npm install
```

2. Cấu hình biến môi trường:
Tạo file `.env` từ `.env.example` và điều chỉnh chuỗi kết nối:
```env
PORT=3000
DATABASE_URL="postgresql://postgres:postgrespassword@localhost:5432/cineora?schema=public"
REDIS_HOST=localhost
REDIS_PORT=6379
JWT_ACCESS_SECRET="cineora_jwt_access_secret_production_ready_token_2026_key"
PLAYBACK_SIGNING_KEY="cineora_playback_hmac_sha256_signing_key_secure_vault"
```

3. Sinh Prisma Client & Đẩy Migration:
```bash
npx prisma generate
npx prisma migrate dev --name init
```

4. Nạp dữ liệu mẫu (Seed Data):
```bash
npm run prisma:seed
```

Tài khoản thử nghiệm mặc định được nạp sẵn:
- **Super Admin:** `admin@cineora.tv` / `AdminPass123!`
- **Người dùng:** `user@cineora.tv` / `UserPass123!`

5. Chạy Backend ở chế độ phát triển:
```bash
npm run start:dev
```

6. Chạy bộ kiểm thử (Unit Tests):
```bash
npm test
```

---

## 4. Hướng dẫn khởi chạy ứng dụng Mobile (Flutter)

1. Cài đặt các gói phụ thuộc Flutter:
```bash
cd mobile
flutter pub get
```

2. Chạy ứng dụng trên máy ảo hoặc thiết bị thực tế:
```bash
# Chạy trên Android Emulator
flutter run -d emulator-5554

# Chạy trên iOS Simulator (macOS)
flutter run -d "iPhone 15 Pro"
```

3. Chạy kiểm thử tự động của Mobile:
```bash
flutter test
```

4. Lệnh đóng gói phát hành (Release Build):
```bash
# Android App Bundle (Phát hành Google Play)
flutter build appbundle --release

# iOS Archive (Phát hành App Store)
flutter build ipa --release
```

---

## 5. Quy trình Kiểm tra Playback & Bản quyền (Verification)

1. **Xác thực quyền phát (`/playback/authorize`):**
   - Ứng dụng gửi `episodeId` và `deviceId`.
   - Backend xác thực người dùng, kiểm tra giới hạn luồng phát đồng thời (1 thiết bị cho gói Free, 2-4 thiết bị cho gói Premium).
   - Kiểm tra chính sách địa lý (Region Policy): Nội dung `VN_ONLY` chỉ cho phép IP từ Việt Nam.
   - Kiểm tra thời hạn cấp phép của video source.
2. **Ký URL phát video:**
   - Provider Adapter (`PublicDomainAdapter` / `CineoraCdnAdapter`) tạo URL HLS `.m3u8` có kèm token mã hóa HMAC-SHA256 với thời gian hết hạn cố định (2 giờ).
3. **Phát video & Lưu tiến trình:**
   - Ứng dụng phát video mượt mà, định kỳ mỗi 10 giây gửi Heartbeat về `/playback/heartbeat` để cập nhật vị trí xem chính xác vào bảng `watch_history`.
   - Khi vị trí xem đạt trên 90% thời lượng, hệ thống tự động ghi nhận hoàn thành phim.

---

## 6. Tuân thủ Quy định Phát hành (Store Compliance)

- **Apple App Store:**
  - Hỗ trợ đầy đủ chức năng xóa tài khoản vĩnh viễn trong Cài đặt (`DELETE /api/v1/users/me`), tuân thủ nghiêm ngặt **Guideline 5.1.1(v)**.
  - Tích hợp file khai báo bảo mật dữ liệu bắt buộc: `PrivacyInfo.xcprivacy`.
  - Cổng thanh toán nội dung số In-App Purchase được thiết kế tuân thủ StoreKit, ở trạng thái chờ kích hoạt tài khoản định danh thương mại.
- **Google Play:**
  - Tuân thủ chính sách Data Safety và Google Play Billing API.
