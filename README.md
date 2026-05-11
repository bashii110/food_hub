<div align="center">

<img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
<img src="https://img.shields.io/badge/Laravel-FF2D20?style=for-the-badge&logo=laravel&logoColor=white" />
<img src="https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white" />
<img src="https://img.shields.io/badge/Riverpod-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
<img src="https://img.shields.io/badge/Hive-FFA726?style=for-the-badge&logo=hive&logoColor=white" />

<br/><br/>

<h1>🍔 FoodHub</h1>

<p><strong>A full-stack Flutter food ordering app with a powerful Admin Panel — built for speed, simplicity, and scale.</strong></p>

<p>
  <a href="https://bashii110.github.io/food_hub/"><img src="https://img.shields.io/badge/🌐%20Live%20Demo-Click%20Here-brightgreen?style=flat-square" /></a>
  &nbsp;
  <img src="https://img.shields.io/badge/License-MIT-green.svg" />
  &nbsp;
  <img src="https://img.shields.io/badge/Status-Active%20Development-brightgreen" />
  &nbsp;
  <img src="https://img.shields.io/badge/Theme-Light%20%2F%20Dark-blueviolet" />
</p>

<br/>

```
Browse food. Place orders. Pay your way. All in one place.
```

</div>

---

## 📋 Table of Contents

- [✨ Features](#-features)
- [📱 Screenshots](#-screenshots)
- [🏗️ Architecture](#️-architecture)
- [🗂️ Project Structure](#️-project-structure)
- [📦 State Management](#-state-management)
- [🛠️ Tech Stack](#️-tech-stack)
- [🚀 Getting Started](#-getting-started)
- [⚡ Backend Setup](#-backend-setup)
- [🤝 Contributing](#-contributing)

---

## ✨ Features

### 🧑‍🍳 For Users
| Feature | Description |
|--------|-------------|
| 🔐 **Auth** | Register, login, and logout with secure sessions |
| 👤 **Profile** | View and update personal information |
| 🍕 **Browse** | Explore food products by categories |
| 🛒 **Ordering** | Place orders with real-time status tracking |
| 💳 **Payments** | JazzCash, Easypaisa, Bank Transfer, Cash on Delivery |
| 📸 **Proof Upload** | Upload payment screenshots for verification |
| 📜 **History** | Full order history with live status updates |

### 🛡️ For Admins
| Feature | Description |
|--------|-------------|
| 📊 **Dashboard** | Overview of revenue, orders, users, and products |
| 📦 **Order Management** | Verify payments, approve/reject, track status |
| 🍔 **Product CRUD** | Add, edit, delete, and manage all food items |
| 👥 **User Management** | View all users, roles, and activity |
| 📈 **Analytics** | Revenue charts and recent order summaries |
| 🖥️ **Responsive Layout** | `NavigationRail`-based admin panel for desktop & tablet |

### 🎨 Theme & UI
- ☀️ / 🌙 Full **light and dark mode** support
- Dynamic colors that adapt to the active theme
- Modern, clean UI with smooth animations
- Refreshable dashboard with live stats

---

## 📱 Screenshots

### Flutter UI

<table>
  <tr>
    <td align="center"><b>Admin Desktop View</b></td>
    <td align="center"><b>Login</b></td>
    <td align="center"><b>Register</b></td>
    <td align="center"><b>Home</b></td>
    <td align="center"><b>Cart</b></td>
    <td align="center"><b>Admin Mobile View</b></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/e1838e1c-5cb1-40d9-bcf4-d23700813263" width="140" /></td>
    <td><img src="https://github.com/user-attachments/assets/b80bb03b-8a97-410a-869e-3a16f03a7e48" width="80" /></td>
    <td><img src="https://github.com/user-attachments/assets/310abf98-8921-4558-9c6f-10ed1b227960" width="80" /></td>
    <td><img src="https://github.com/user-attachments/assets/d72da309-f0a9-4c70-84e3-b5f3d1efe8d2" width="80" /></td>
    <td><img src="https://github.com/user-attachments/assets/e7bd2668-8d40-423c-bd81-1023dc7d2284" width="80" /></td>
    <td><img src="https://github.com/user-attachments/assets/9e389dda-2318-4c74-b221-664f64f30091" width="80" /></td>
  </tr>
</table>

### Laravel Backend

<table>
  <tr>
    <td align="center"><b>Backend Panel</b></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/2eccb176-9be0-4d12-a739-85d67fa27415" width="350" /></td>
  </tr>
</table>

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                        Flutter App                           │
│                                                              │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌─────────┐  │
│  │   Auth   │   │   User   │   │  Admin   │   │  Cart   │  │
│  │  Screens │   │  Screens │   │  Screens │   │ Screen  │  │
│  └────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬────┘  │
│       └──────────────┴──────────────┴───────────────┘       │
│                              │                               │
│                   ┌──────────▼──────────┐                   │
│                   │   Riverpod Providers │                   │
│                   │  Auth · Admin · Cart │                   │
│                   │  Theme · Orders      │                   │
│                   └──────────┬──────────┘                   │
│                              │                               │
│                   ┌──────────▼──────────┐                   │
│                   │    API Service       │  (http + Hive)   │
│                   └─────────────────────┘                   │
└──────────────────────────────┬───────────────────────────────┘
                               │  HTTP / JSON
┌──────────────────────────────▼───────────────────────────────┐
│                      Laravel REST API                        │
│                                                              │
│  ┌────────────┐  ┌──────────────┐  ┌──────────────────────┐ │
│  │AuthContrl. │  │ProductContrl.│  │  OrderController     │ │
│  └────────────┘  └──────────────┘  └──────────────────────┘ │
│                                                              │
│  ┌────────────┐  ┌──────────────┐  ┌──────────────────────┐ │
│  │AdminContrl.│  │PaymentContrl.│  │  Sanctum Tokens      │ │
│  └────────────┘  └──────────────┘  └──────────────────────┘ │
│                                                              │
│              ┌─────────────────────────┐                    │
│              │     Eloquent ORM        │                    │
│              └────────────┬────────────┘                    │
└───────────────────────────┼─────────────────────────────────┘
                            │
              ┌─────────────▼─────────────┐
              │          MySQL            │
              │  users · products         │
              │  orders · payments        │
              │  categories · sessions    │
              └───────────────────────────┘
```

---

## 🗂️ Project Structure

```
lib/
├── 📂 admin_panel/          # Admin UI screens (dashboard, orders, products, users)
├── 📂 cart/                 # Cart screen and checkout logic
├── 📂 components/           # Entities, models, and utility classes
├── 📂 data/                 # API services (auth, products, orders, payments)
├── 📂 home/                 # User-facing home & browse screens
├── 📂 presentation/         # Riverpod providers + auth/payment UI
├── 📂 widgets/              # Reusable UI components
├── 📄 main.dart             # App entry point
└── 📄 app_root.dart         # Role-based routing (user vs admin)
```

---

## 📦 State Management

> All state is handled via **Riverpod** with `StateNotifierProvider` and `FutureProvider`.

| Provider | Responsibility |
|---------|---------------|
| `AuthProvider` | Login, registration, logout, current user state |
| `AdminProvider` | Dashboard stats, user/order/product management |
| `CartProvider` | Cart items, quantities, and order creation |
| `ThemeProvider` | Light/dark mode via **Hive** local storage |
| `ProductProvider` | Fetch and cache food product listings |
| `OrderProvider` | Order lifecycle — place, track, and update |

---

## 🛠️ Tech Stack

### Frontend
| Technology | Purpose |
|-----------|---------|
| **Flutter** | Cross-platform mobile & web UI |
| **Riverpod** | Reactive state management |
| **Hive** | Local storage for theme & settings |
| **http** | REST API networking |
| **cached_network_image** | Efficient image loading & caching |

### Backend
| Technology | Purpose |
|-----------|---------|
| **Laravel** | REST API framework |
| **Laravel Sanctum** | Token-based authentication |
| **Eloquent ORM** | Database abstraction |
| **MySQL** | Primary relational database |

---

## 🚀 Getting Started

### Prerequisites
- Flutter `>=3.x`
- PHP `>=8.2`
- Composer
- MySQL
- Laravel `10.x+`

### 📱 Flutter Setup

```bash
# 1. Clone the repository
git clone https://github.com/bashii110/food_hub.git
cd food_hub

# 2. Install Flutter dependencies
flutter pub get

# 3. Initialise Hive (already handled in main.dart)
await Hive.initFlutter();
await Hive.openBox('settings');

# 4. Update your API base URL in lib/data/api_client.dart
# Android emulator:  http://10.0.2.2:8000/api
# Physical device:   http://YOUR_PC_IP:8000/api

# 5. Run the app
flutter run
```

---

## ⚡ Backend Setup

```bash
# 1. Clone the Laravel backend
git clone <backend-repo-url>
cd backend

# 2. Install PHP dependencies
composer install

# 3. Set up environment
cp .env.example .env
php artisan key:generate

# 4. Configure your .env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=food_hub
DB_USERNAME=root
DB_PASSWORD=your_password

MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your@gmail.com
MAIL_PASSWORD=your_app_password

# 5. Run migrations and seed data
php artisan migrate --seed

# 6. Start the server
php artisan serve
```

---

## 💡 Developer Notes

- All revenue and numeric fields use `double.tryParse()` to prevent runtime parsing errors.
- Admin dashboard colors adapt dynamically to the active theme.
- Payment table supports multiple methods with proof upload and admin verification workflow.
- `NavigationRail` is used for a responsive admin layout on wider screens.

---

## 📌 Planned Features

- [ ] Push notifications (FCM)
- [ ] Real-time order tracking with WebSockets
- [ ] Ratings & reviews for food items
- [ ] Coupon and discount system
- [ ] HTTPS + production deployment
- [ ] iOS App Store & Google Play release

---

## 🤝 Contributing

Contributions are welcome! Here's how:

```bash
# 1. Fork the repository
# 2. Create your feature branch
git checkout -b feature/your-feature-name

# 3. Commit your changes
git commit -m "feat: describe your change"

# 4. Push and open a PR
git push origin feature/your-feature-name
```

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**Built with ❤️ by [Bashir Ahmed](https://github.com/bashii110)**

📧 buxhiisd@gmail.com

<br/>

⭐ **Star this repo** if you found it useful!

<a href="https://github.com/bashii110/food_hub">
  <img src="https://img.shields.io/badge/View%20on-GitHub-black?style=for-the-badge&logo=github" />
</a>
&nbsp;
<a href="https://bashii110.github.io/food_hub/">
  <img src="https://img.shields.io/badge/Live-Demo-brightgreen?style=for-the-badge&logo=flutter" />
</a>

</div>
