# Clivi Management 🏗️📊  
A role-based **Construction Project Management App** built using **Flutter + Supabase**, designed to manage construction projects, site operations, staff, material stock, bills, and reports — all in one place.

---

## 🚀 Overview  
**Clivi Management** helps construction teams digitize day-to-day site activities by providing a centralized system for:

✅ Project creation & assignment  
✅ Site staff management (Admin / Site Manager / Engineer)  
✅ Material tracking (Received ✅ / Consumption ✅)  
✅ Auto-calculated remaining stock  
✅ Vendor-based material logs  
✅ Bill raising & payment tracking  
✅ Reports & dashboards for real-time monitoring  

---

## 👥 User Roles & Permissions  

### 🔑 1) Super Admin  
- Manage complete system access  
- Control admins & global settings  
- View all projects and reports  

### 🛠️ 2) Admin  
- Create projects  
- Assign projects to Site Managers / Engineers  
- Add & manage staff  
- Approve bills & manage documents  
- Generate reports (stock, vendor, site usage)

### 🏗️ 3) Site Manager / Site Engineer  
- View assigned projects  
- Update daily site stock  
- Add material **Received** and **Consumption**  
- Raise bills (Advance / Part Bill / Full Bill)  
- Upload site documents (photos, invoices, work updates)

---

## ✅ Key Features  

### 📁 Project Management  
- Create and manage multiple projects  
- Assign projects to staff  
- Store project info, location, and status

### 👷 Staff Management  
- Admin creates Site Manager / Engineer accounts  
- Role-based dashboards and permissions  
- Staff assignment and tracking

### 🧱 Material Stock Management  
Track construction materials like:  
- Cement 🧱  
- Steel 🏗️  
- Sand  
- Bricks  
- Other site materials  

✅ Two core options:  
- **Received Stock** → materials delivered to site  
- **Consumption Stock** → daily usage by site team  

📌 System automatically calculates:  
**Remaining Stock = Total Received - Total Consumed**

### 🧾 Bills & Payment Workflow  
- Site Engineer raises bill request  
- Bill type options:  
  ✅ Advance  
  ✅ Part Bill  
  ✅ Full Bill  
- Office Accountant/Admin can close bills when paid

### 📊 Reports & Dashboard  
Generate real-time insights like:  
- Total Stock vs Used Stock vs Remaining Stock  
- Vendor-wise material reports  
- Project-wise usage summary  
- Staff performance tracking  
- Bill status reports

### 📂 Document Management  
- Project document upload support  
- Admin can create folders inside a project (Blueprint segregation)  
- Example folders:  
  - Blueprints  
  - Site Photos  
  - Invoices  
  - Contracts  
  - Work Progress Docs

---

## 🧱 Tech Stack  

### 📱 Frontend  
- **Flutter (Dart)**
- Riverpod (state management)  
- GoRouter (navigation + guards)

### 🔥 Backend  
- **Supabase**
  - Auth (Email/OTP)  
  - Postgres Database  
  - RLS policies (role-based security)  
  - Storage (documents + bills + images)

---

## 📂 Project Folder Structure (Clean Architecture)

lib/
├── main.dart  
├── core/  
│   ├── config/  
│   ├── router/  
│   ├── theme/  
│   ├── widgets/  
│   ├── utils/  
│   └── errors/  
├── features/  
│   ├── auth/  
│   │   ├── data/  
│   │   ├── domain/  
│   │   └── presentation/  
│   ├── projects/  
│   ├── materials/  
│   ├── bills/  
│   ├── reports/  
│   ├── staff/  
│   └── profile/  

---

## ⚙️ Setup & Installation  

### Prerequisites
- Flutter SDK (latest stable)
- Dart SDK ^3.10.7
- A Supabase account and project
- Android Studio / Xcode (for mobile development)

### ✅ 1. Clone Repository
```bash
git clone https://github.com/kalyan1421/Clivi-Management.git
cd Clivi-Management
```

### ✅ 2. Install Dependencies
```bash
flutter pub get
```

### ✅ 3. Setup Environment Variables
1. Create the `.env` file in the `assets` folder:
```bash
touch assets/.env
```

2. Add your Supabase credentials to `assets/.env`:
```env
# Supabase Configuration
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here

# App Environment (development, staging, production)
APP_ENV=development

# Debug Mode (enables Supabase debug logging)
DEBUG_MODE=true
```

**Getting Supabase Credentials:**
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project (or create a new one)
3. Navigate to **Settings** → **API**
4. Copy the **Project URL** and **anon/public** key

⚠️ **IMPORTANT**: Never commit `.env` to version control! The `.env` file is already in `.gitignore`.

### ✅ 4. Run Database Migrations
See `supabase/SETUP_GUIDE.md` for detailed instructions on setting up the Supabase database.

**Quick Setup:**
1. Go to Supabase SQL Editor
2. Run migrations in order:
   - `supabase/migrations/001_initial_schema.sql`
   - `supabase/migrations/002_fix_rls_policies.sql`
   - `supabase/migrations/003_add_blueprints.sql`

### ✅ 5. Generate Code (if using freezed/riverpod_generator)
```bash
dart run build_runner build --delete-conflicting-outputs
```

### ✅ 6. Run the App
```bash
# Run on connected device
flutter run

# Run with specific flavor
flutter run --debug

# Run on web
flutter run -d chrome
```

---

## 🏗️ Architecture Overview

This project follows **Clean Architecture** principles with **Feature-First** organization:

```
lib/
├── main.dart                    # App entry point
├── core/                        # Shared core functionality
│   ├── config/
│   │   ├── app_constants.dart   # App-wide constants
│   │   ├── env.dart             # Environment configuration
│   │   └── supabase_client.dart # Supabase initialization
│   ├── errors/
│   │   ├── app_exceptions.dart  # Custom exception classes
│   │   └── error_handler.dart   # Global error handling
│   ├── router/
│   │   ├── app_router.dart      # GoRouter configuration
│   │   ├── route_guards.dart    # Auth & role guards
│   │   └── route_names.dart     # Route constants
│   ├── theme/
│   │   ├── app_colors.dart      # Color palette
│   │   ├── app_theme.dart       # Material theme
│   │   └── text_styles.dart     # Typography
│   ├── utils/
│   │   ├── currency_formatter.dart
│   │   ├── date_formatter.dart
│   │   └── validators.dart
│   └── widgets/                 # Reusable UI components
│       ├── app_button.dart
│       ├── custom_text_field.dart
│       ├── error_widget.dart
│       └── loading_widget.dart
├── features/                    # Feature modules
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── providers/
│   │   └── screens/
│   ├── dashboard/
│   ├── projects/
│   ├── blueprints/
│   └── ... (other features)
└── shared/                      # Shared models & utilities
    └── models/
        └── app_user.dart
```

### Key Technologies
| Technology | Purpose |
|------------|---------|
| **flutter_riverpod** | State management |
| **go_router** | Navigation with guards |
| **supabase_flutter** | Backend (Auth, DB, Storage) |
| **flutter_dotenv** | Environment configuration |
| **google_fonts** | Typography |
| **freezed** | Immutable models (optional) |
| **intl** | Date/Currency formatting |

---

## ✅ Testing Checklist

After setup, verify the following:

- [ ] App launches without errors
- [ ] Supabase connection successful (check console logs)
- [ ] Environment variables loaded correctly
- [ ] Router redirects to login when not authenticated
- [ ] Login/Signup functionality works
- [ ] Role-based routing (Super Admin/Admin/Site Manager dashboards)
- [ ] Theme applied globally (Blue primary, Orange secondary)
- [ ] No compilation errors

**Debug Commands:**
```bash
# Check for analysis issues
flutter analyze

# Run tests
flutter test

# Clean build
flutter clean && flutter pub get && flutter run
```

---

## 🔐 Security (Supabase RLS)  
This project uses **Row Level Security (RLS)** to ensure:

✅ Admin can access only their projects  
✅ Site Manager can access only assigned projects  
✅ Staff cannot edit restricted modules  
✅ Storage access controlled by role  

---

## 📌 Roadmap (Next Updates)
✅ Notifications for material updates & bill approvals  
✅ Offline mode for site updates  
✅ Auto-generated PDF reports  
✅ Multi-site project support  
✅ Attendance & daily work log module  
✅ Expense & budget tracking  

---

## 📸 Screenshots  
📌 (Add your app UI screenshots here)

---

## 🤝 Contributing  
Pull requests are welcome!  
For major changes, please open an issue first.

---

## 📄 License  
This project is private/proprietary for Clivi usage.  
(You can update license later)

---

## 👨‍💻 Developed By  
**Kalyan Kumar Bedugam**  
Flutter Developer | Full Stack | Supabase | Firebase | AI Appsumption), handle vendors & staff, and generate site reports in real-time.
