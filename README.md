# FoodHub - Flutter Food Ordering App
Check Live:  https://bashii110.github.io/food_hub/


**FoodHub** is a Flutter-based mobile application for food ordering and delivery management. It supports **user registration, login, profile management, browsing products, order management, and payment handling**. The app also has a complete **Admin Panel** to manage orders, products, users, and dashboard analytics.

---

## 📱 Features

### User Features
- User registration, login, and logout
- Profile management (view and update)
- Browse food products by categories
- Place orders with multiple payment methods
- Upload payment proof for verification
- View order history and status updates
- Smooth and responsive UI with light/dark theme support

### Admin Features
- Admin login and dashboard
- Overview of total orders, revenue, users, and products
- Manage orders, including verifying payments and tracking status
- Manage products (CRUD operations)
- Manage users (view all users, roles, and activity)
- Dashboard analytics with revenue charts and recent orders
- Responsive admin layout for desktop and tablets

### Payment Features
- Multiple payment options (JazzCash, Easypaisa, Bank Transfer, Cash on Delivery)
- Upload payment proof and view verification status
- Admin verification with approval/rejection

### Theme & UI
- Supports **light and dark mode**
- All colors are dynamic and follow the app theme
- Modern UI with `NavigationRail` for admin panel and responsive layouts
- Refreshable dashboard with real-time stats

---

## 🛠 Tech Stack

- **Frontend:** Flutter, Riverpod (state management)
- **Backend:** Laravel (REST API)
- **Database:** MySQL
- **Local Storage:** Hive (for theme and settings)
- **Networking:** `http` and custom API client
- **State Management:** Riverpod (`StateNotifierProvider`, `FutureProvider`)
- **Other Packages:** 
  - `flutter_riverpod`
  - `hive_flutter`
  - `cached_network_image`

---

### Flutter UI
<img width="350" height="220" alt="admin dashboard" src="https://github.com/user-attachments/assets/e1838e1c-5cb1-40d9-bcf4-d23700813263" />
<img src="https://github.com/user-attachments/assets/b80bb03b-8a97-410a-869e-3a16f03a7e48" width="100" height="300" />
<img src="https://github.com/user-attachments/assets/310abf98-8921-4558-9c6f-10ed1b227960" width="100" />
<img src="https://github.com/user-attachments/assets/d72da309-f0a9-4c70-84e3-b5f3d1efe8d2" width="100" />
<img src="https://github.com/user-attachments/assets/e7bd2668-8d40-423c-bd81-1023dc7d2284" width="100" />
<img src="https://github.com/user-attachments/assets/9e389dda-2318-4c74-b221-664f64f30091" width="100" />


### Backend With Laravel: 
<img width="350" height="220" alt="backend" src="https://github.com/user-attachments/assets/2eccb176-9be0-4d12-a739-85d67fa27415" />



## 🔧 Installation

1. **Clone the repository:**

```bash
git clone https://github.com/bashii110/food_hub.git
cd food_hub

Install dependencies:

flutter pub get


Set up Hive (local storage for theme):

await Hive.initFlutter();
await Hive.openBox('settings');


Run the app:

flutter run

⚡ Backend Setup

Clone your backend repo (Laravel):

git clone <backend-repo-url>
cd backend


Install PHP dependencies:

composer install


Copy .env.example to .env and configure your database:

cp .env.example .env


Generate app key:

php artisan key:generate


Run migrations and seeders:

php artisan migrate --seed


Run backend server:

php artisan serve

🗂 Project Structure
lib/
├── admin_panel/          # Admin UI screens
├── cart/                 # Cart screen and logic
├── components/           # Entities, models, utilities
├── data/                 # Services (API, auth, products, orders)
├── home/                 # User home screens
├── presentation/         # Providers and UI for auth/payment
├── widgets/              # Reusable widgets
├── main.dart             # Entry point
├── app_root.dart         # Authentication-based routing

📈 State Management

AuthProvider: Handles login, registration, logout, and current user state

AdminProvider: Fetches admin dashboard stats and user/order/product management

CartProvider: Manages cart items and order creation

ThemeProvider: Manages light/dark theme using Hive storage

Product & Order Providers: Handles fetching and updating products/orders via API

💡 Notes

All revenue and numeric fields are safely parsed using double.tryParse() to avoid runtime errors.

Admin dashboard dynamically adjusts colors based on theme.

Payment table in backend supports multiple methods and proof verification.

🖼 Screenshots

Add your screenshots here if available.

🔗 License

This project is open-source under the MIT License.

🤝 Contributing

Fork the repository

Create a new branch (git checkout -b feature/your-feature)

Commit your changes (git commit -m 'Add some feature')

Push to the branch (git push origin feature/your-feature)

Open a Pull Request

⚙️ Contact

Developer: Bashir Ahmed

GitHub: https://github.com/bashii110

Email: buxhiisd@gmail.com


---

If you want, I can also **add a “Backend API Endpoints” section** in this README, listing all Laravel routes like `/auth/login`, `/products`, `/orders`, etc., so your repo becomes fully self-documented for frontend-backend integration.  

Do you want me to do that?
