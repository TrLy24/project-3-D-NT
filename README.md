# Smart Expense Tracker & Invoice Analysis (Offline OCR)
Ứng dụng theo dõi chi phí và phân tích hóa đơn thông minh bằng OCR trên nền tảng **Flutter 3.x** và **Dart 3** (Tuân thủ nghiêm ngặt 100% Null Safety, Clean Architecture & TDD).

---

## 1. Giới thiệu dự án
Ứng dụng hỗ trợ người dùng quản lý tài chính cá nhân toàn diện:
- **Offline OCR (<100ms)**: Nhận diện chữ trực tiếp trên thiết bị bằng `google_mlkit_text_recognition` kết hợp bộ mẫu hóa đơn ngân hàng/bán lẻ phổ biến tại Việt Nam.
- **Bộ máy bóc tách Heuristic Regex nội bộ**: Tự động trích xuất chính xác **Tổng tiền (VND)**, **Ngày giao dịch (DD/MM/YYYY)** và **Tên đơn vị/người bán**, phân loại tự động danh mục chi tiêu.
- **Biểu đồ CustomPainter thuần (Không dùng thư viện bên thứ 3)**: Tự xây dựng giải thuật hình học/lượng giác để vẽ trực tiếp biểu đồ Tròn (Pie Chart), Bánh vòng (Donut Chart) và Cột hàng tuần (Weekly Bar Chart) kèm hiệu ứng tương tác chạm (Touch highlight, Tooltip).
- **Cơ sở dữ liệu cục bộ SQLite**: Lưu trữ ngoại tuyến an toàn, quản lý CRUD giao dịch, lưu ảnh thu nhỏ hóa đơn vào bộ nhớ cục bộ ứng dụng.
- **Trợ lý Tài chính (Offline Heuristic Engine)**: Phân tích cơ cấu tiêu dùng, xếp hạng sức khỏe tài chính và đề xuất hạn mức chi tiêu tuần tới.

### Trợ lý AI
Trợ lý hiện chạy phân tích ngoại tuyến trên thiết bị và không yêu cầu Gemini API
key. Khi mở tính năng, ứng dụng cũng xóa key Gemini cũ đã lưu trên thiết bị.
Muốn bật Gemini mà không phát hành key trong ứng dụng, cần cấu hình backend riêng.

---

## 2. Cấu trúc thư mục mã nguồn
```
lib/
├── core/
│   └── app_theme.dart               # Hệ thống màu sắc, kiểu chữ và Design Tokens
├── models/
│   ├── category_model.dart          # Định nghĩa danh mục & giải thuật đoán danh mục
│   ├── ocr_result.dart              # Cấu trúc dữ liệu bóc tách từ OCR
│   └── transaction_model.dart       # Thực thể giao dịch, ánh xạ SQLite & định dạng tiền VND
├── services/
│   ├── database_service.dart        # Dịch vụ SQLite đa nền tảng (Mobile, Desktop, Web)
│   ├── gemini_ai_service.dart       # Kết nối Gemini 1.5 Flash REST API & Fallback Engine
│   ├── ocr_service.dart             # Google ML Kit Text Recognition ngoại tuyến + bộ preset demo
│   └── regex_extractor.dart         # Thuật toán Heuristic Regex nhận diện số tiền, ngày tháng, merchant
├── providers/
│   ├── ai_advisor_provider.dart     # Quản lý trạng thái phân tích tài chính AI
│   ├── expense_provider.dart        # Quản lý giao dịch, bộ lọc thời gian & tính toán số liệu biểu đồ
│   └── scanner_provider.dart        # Quản lý luồng camera, trạng thái flash, đo độ trễ OCR
├── widgets/
│   ├── charts/
│   │   ├── custom_bar_chart.dart    # Biểu đồ cột 7 ngày vẽ bằng CustomPainter (Toán học tọa độ Y)
│   │   └── custom_pie_chart.dart    # Biểu đồ Pie/Donut vẽ bằng CustomPainter (Toán học lượng giác Arc)
│   ├── camera_overlay.dart          # Khung ngắm quét camera với hiệu ứng laser chuyển động
│   └── transaction_card.dart        # Thẻ giao dịch với màu danh mục và thao tác vuốt xóa
├── screens/
│   ├── ai_assistant_screen.dart     # Màn hình trợ lý tài chính Gemini AI
│   ├── edit_transaction_screen.dart # Màn hình xem lại, chỉnh sửa thủ công và lưu giao dịch
│   ├── home_screen.dart             # Bảng điều khiển tổng quan chi tiêu & biểu đồ tuần
│   ├── main_navigation_screen.dart  # Điều hướng Bottom Navigation Bar & nút quét nổi
│   ├── scanner_screen.dart          # Màn hình camera trực tiếp, preset demo & thư viện ảnh
│   └── statistics_screen.dart       # Màn hình phân tích chuyên sâu với Donut & Pie Chart
└── main.dart                        # Điểm khởi chạy ứng dụng với MultiProvider
```

---

## 3. Hướng dẫn cài đặt & Biên dịch

### Yêu cầu môi trường
- Flutter SDK 3.x trở lên
- Dart SDK 3.x (Null safety)
- Trình duyệt Chrome / Edge (nếu chạy Web) hoặc Android Studio / Thiết bị Android (nếu chạy Mobile)

### Cài đặt dependencies
```bash
flutter pub get
```

### Chạy kiểm thử chất lượng (TDD)
```bash
# Kiểm tra phân tích tĩnh (đảm bảo 0 issues)
flutter analyze

# Chạy toàn bộ bộ kiểm thử Unit Test & Widget Test
flutter test

# Chạy riêng Unit Test cho Heuristic Regex Extractor
flutter test test/unit/regex_extractor_test.dart

# Chạy riêng Widget Test cho CustomPainter Charts
flutter test test/widget/custom_chart_widget_test.dart
```

### Chạy ứng dụng trên môi trường phát triển
```bash
# Khởi chạy trên Web Chrome
flutter run -d chrome

# Khởi chạy trên thiết bị di động Android
flutter run -d android
```

### Biên dịch bản phát hành (Production AOT Release)
```bash
# Biên dịch Web Release (để deploy lên Vercel / GitHub Pages)
flutter build web --release

# Biên dịch tệp APK Release chuẩn AOT
flutter build apk --release
```
Tệp APK sau khi biên dịch sẽ nằm tại: `build/app/outputs/flutter-apk/app-release.apk`.

### Ký APK phát hành
Để tạo APK phát hành có chữ ký riêng, tạo keystore và file `android/key.properties`
trên máy của bạn (không đưa hai file này lên GitHub). Cấu hình `key.properties`
cần có `storeFile`, `storePassword`, `keyAlias`, và `keyPassword`; đường dẫn
`storeFile` tính từ thư mục `android/app/`. Khi có cấu hình này, Gradle dùng keystore
riêng cho bản release. Nếu chưa có cấu hình, bản release dùng debug key và chỉ
dành cho kiểm thử, không phát hành lên cửa hàng.

---

## 4. Đặc tả kiểm thử TDD
Dự án được phát triển theo quy trình **Test-Driven Development (TDD)**:
1. **Unit Test Heuristic Regex (`regex_extractor_test.dart`)**:
   - Biên lai chuyển khoản ngân hàng (Vietcombank VCB Digibank, MB Bank).
   - Thông báo ví điện tử (Ví MoMo, ShopeePay).
   - Hóa đơn siêu thị nhiều mặt hàng (WinMart, Bách Hóa Xanh).
   - Hóa đơn F&B (Highlands Coffee).
   - Trường hợp chữ mờ, nhiễu khoảng trắng (`250 000 d`), định dạng tắt (`85k`), định dạng ngày khác biệt (`DD/MM/YYYY`, `DD-MM-YYYY`, `YYYY-MM-DD`).
2. **Widget Test CustomPainter (`custom_chart_widget_test.dart`)**:
   - Kiểm thử cây Widget dựng đúng `CustomPaint` canvas.
   - Kiểm thử render lại chính xác tỷ lệ góc và tọa độ khi dữ liệu chi tiêu thay đổi.
   - Kiểm thử tương tác chạm trên biểu đồ cột và lát cắt bánh vòng.
