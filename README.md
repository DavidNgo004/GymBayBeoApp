# 🏋️ Gym Bay Béo — Mobile App for Smart Gym Management

Ứng dụng hỗ trợ quản lý phòng gym toàn diện: từ check-in check-out bằng QR, xem lịch tập, nhắn tin với PT cho đến quản lý gói tập và khách hàng.  
🚀 Phát triển bằng **Flutter** và **Firebase** — triển khai trên Android.

---

## ✨ Tagline
📱💪 *“Tập luyện thông minh — Quản lý dễ dàng — Nâng cao trải nghiệm khách hàng tại phòng gym.”*

---

## 👤 Thông tin dự án
- 👨‍💻 **Sinh viên thực hiện:** Ngô Ngọc Hòa *(DavidNgo004)*
- 🏫 Đồ án chuyên ngành — 2025
- 🌐 Nền tảng: Android (iOS sẽ hỗ trợ trong tương lai nếu có thể)
- 🔐 Phân quyền người dùng:
  - **Khách hàng**
  - **Huấn luyện viên (PT)**
  - **Admin (Lễ tân)**

---

## 🚀 Tính năng chính

### 🔵 Dành cho khách hàng
- Đăng ký, đăng nhập bằng **Email / Google**
- Check-in / Check-out bằng mã QR
- Quản lý thông tin cá nhân
- Xem lịch tập với PT
- Nhắn tin realtime với PT
- Mua và xem thời hạn gói tập

### 🟢 Dành cho PT (Huấn luyện viên)
- Quản lý & xem thông tin học viên
- Gửi và cập nhật lịch tập hằng ngày
- Gửi nhắc nhở và trao đổi qua chat realtime

### 🟣 Dành cho Admin / Lễ tân
- Quản lý khách hàng, PT, gói tập
- Quản lý doanh thu và báo cáo thống kê
- Duyệt và điều chỉnh đăng ký gói tập

---

## 🛠️ Công nghệ sử dụng

| Hạng mục | Công nghệ |
|---------|-----------|
| Mobile | Flutter (Dart) |
| Firebase Services | Auth, Firestore Database, Realtime Database, Messaging, Hosting |
| Lưu trữ hình ảnh | Cloudinary |
| Quét QR | Flutter packages tích hợp Camera + QR Scanner |
| Deployment | Android build |

---

## 🔒 Bảo mật
- Đã cấu hình **Firebase Security Rules**
- Tách quyền theo người dùng (khách hàng / PT / Admin)
- Chỉ cho phép truy cập đúng dữ liệu theo vai trò

---

## 📂 Kiến trúc mã nguồn
- Code tách theo **feature modules**
- Quản lý state bằng `setState` + tách logic dịch vụ (Service Layer)
- Tối ưu hóa Firestore query và realtime cập nhật khi cần

---

## 📸 Hình ảnh giao diện
> (Sẽ được cập nhật khi hoàn tất chụp màn hình)

| Màn hình | Ảnh |
|--------|-----|
| Đăng nhập | coming soon |
| Trang khách hàng | coming soon |
| Trang PT | coming soon |
| Trang Admin | coming soon |

---

## 📬 Liên hệ
📧 Email: nnhoait@gmail.com  
🔗 GitHub: https://github.com/DavidNgo004  
