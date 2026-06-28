# CaloAI – Nhận diện thức ăn & tính calo bằng AI

Ứng dụng tương đương CalAI, dùng **Google Gemini 1.5 Flash** (miễn phí hoàn toàn).

---

## 📁 Cấu trúc project

```
lib/
├── main.dart                    # Entry point
├── theme/
│   └── app_theme.dart           # Dark theme (màu sắc, font)
├── models/
│   ├── food_result.dart         # Kết quả AI trả về
│   └── meal_entry.dart          # Bữa ăn đã ghi lại
├── services/
│   ├── gemini_service.dart      # Gọi Gemini API (FREE)
│   └── storage_service.dart     # Lưu dữ liệu local
├── providers/
│   └── app_provider.dart        # State management (Provider)
├── screens/
│   ├── main_screen.dart         # Bottom nav host + FAB camera
│   ├── today_screen.dart        # Trang chủ – ring calo + bữa ăn hôm nay
│   ├── camera_screen.dart       # Chụp ảnh / chọn từ thư viện
│   ├── result_screen.dart       # Kết quả phân tích AI
│   ├── history_screen.dart      # Lịch sử tất cả bữa ăn
│   └── profile_screen.dart      # Cài đặt mục tiêu calo/macro
└── widgets/
    ├── calorie_ring.dart         # Vòng tròn calo animation
    ├── macro_bar.dart            # Thanh tiến trình protein/carbs/fat
    └── meal_card.dart            # Card bữa ăn (swipe to delete)
```

---

## 🔑 Bước 1 – Lấy API Key miễn phí

1. Vào https://aistudio.google.com/app/apikey
2. Đăng nhập Google → nhấn **"Create API key"**
3. Copy key, mở file `lib/services/gemini_service.dart`
4. Thay `'YOUR_GEMINI_API_KEY_HERE'` bằng key của bạn

**Giới hạn free tier:**
- 15 requests/phút
- 1.500 requests/ngày  
- 1 triệu token/phút
→ Đủ dùng cá nhân thoải mái.

---

## 🚀 Bước 2 – Cài đặt & chạy

```bash
# 1. Clone hoặc copy project vào máy

# 2. Cài dependencies
flutter pub get

# 3. Chạy app
flutter run

# Build release Android
flutter build apk --release

# Build release iOS
flutter build ios --release
```

### Yêu cầu
- Flutter SDK >= 3.2.0
- Android: minSdkVersion 21 (Android 5.0+)
- iOS: Deployment target 12.0+

---

## ✨ Tính năng

| Tính năng | Mô tả |
|---|---|
| 📸 Chụp ảnh / chọn gallery | Hỗ trợ cả camera và thư viện |
| 🤖 AI nhận diện món ăn | Gemini Vision – chính xác cao |
| 🔢 Tính calo tự động | Protein, Carbs, Chất béo |
| 📊 Vòng tròn calo ngày | Animation đẹp mắt |
| 📝 Nhật ký bữa ăn | Lưu lịch sử, swipe xóa |
| 🎯 Mục tiêu tùy chỉnh | Calo + macro cá nhân |
| 🌙 Dark theme | Giao diện tối như CalAI |
| 📱 Offline storage | Dữ liệu lưu trên máy |

---

## 🎨 Design

- **Background:** `#0A0A0F` (gần đen)
- **Surface:** `#16161E`
- **Accent (Purple):** `#7C5CFC` 
- **Green:** `#4ADE80`
- **Protein:** Purple · **Carbs:** Green · **Fat:** Amber

---

## 🔧 Tùy chỉnh nhanh

### Đổi ngôn ngữ nhận diện
Trong `gemini_service.dart`, sửa dòng trong `_prompt`:
```
"name": "Tên món ăn chính bằng tiếng Việt",
```
→ Đổi thành English nếu muốn tên tiếng Anh.

### Đổi mục tiêu calo mặc định
Trong `storage_service.dart`:
```dart
return prefs.getInt(_calorieGoalKey) ?? 2000; // ← sửa 2000
```

### Đổi màu accent
Trong `app_theme.dart`:
```dart
static const Color accent = Color(0xFF7C5CFC); // ← sửa màu
```

---

## ⚠️ Lưu ý

- **Độ chính xác:** AI ước tính ~85% chính xác, phụ thuộc ảnh rõ không
- **Khẩu phần:** Đặt vật tham chiếu (bàn tay, đũa) để AI ước lượng tốt hơn
- **Dữ liệu:** Tất cả lưu trên máy, không upload lên server (ngoài ảnh gửi Gemini)
- **Internet:** Cần kết nối để gọi Gemini API

---

## 📦 Dependencies

```yaml
image_picker: ^1.1.2        # Camera & gallery
http: ^1.2.2                 # HTTP requests đến Gemini
provider: ^6.1.2             # State management
shared_preferences: ^2.3.2   # Local storage
fl_chart: ^0.68.0            # Charts (future use)
intl: ^0.19.0                # Date formatting
uuid: ^4.5.1                 # Unique meal IDs
path_provider: ^2.1.3        # File paths
```

---

*Made with ❤️ – Powered by Google Gemini AI (Free)*
