# Clivi Management App - Technical Documentation

This document provides a comprehensive technical overview of the Clivi Management Flutter application and its Supabase backend. It is intended for developers, architects, and project stakeholders.

---

## 1️⃣ System Overview

### Purpose
The Clivi Management application is a comprehensive tool designed for construction project management. It facilitates real-time tracking of site operations, resource management, and reporting for construction projects.

### Roles Supported
The system is built around two primary user roles with distinct responsibilities:
*   **Admin / Super Admin:** Have full oversight over all projects, users, and system-wide data. They are responsible for project creation, user management, and high-level reporting.
*   **Site Manager:** Assigned to one or more specific projects. They are responsible for the day-to-day operational logging, including labour attendance, stock consumption, and daily progress reports for their assigned projects only.

### Communication Flow
The Flutter application communicates directly with the Supabase backend via the official `supabase_flutter` client library. All data requests are authenticated and authorized in real-time by Supabase's Row Level Security (RLS) policies.

*   **API:** The backend exposes a secure RESTful API and a real-time WebSocket interface via PostgREST and Supabase Realtime.
*   **Data Access:** The Flutter app uses the Supabase client to query tables, call RPC functions (`get_dashboard_stats`), and subscribe to real-time changes.
*   **Storage:** Media files (photos, documents) are uploaded directly from the Flutter app to Supabase Storage, with access controlled by storage-specific RLS policies.

### Overall Application Flow
1.  **Authentication:** User logs in with email and password. A `user_profiles` record is automatically created on first signup, defaulting to the `site_manager` role.
2.  **Dashboard:** After login, the user sees a dashboard summarizing key metrics for the projects they have access to (all for Admins, assigned for Site Managers).
3.  **Project Selection:** The user navigates to a specific project.
4.  **Daily Operations:** The Site Manager performs daily tasks:
    *   Logs labour attendance.
    *   Records stock movement (inward/outward).
    *   Uploads daily site photos and progress notes.
    *   Manages project-specific documents (blueprints).
5.  **Admin Functions:** The Admin can:
    *   Create new projects and assign Site Managers.
    *   Manage the master list of stock items and labour.
    *   View consolidated reports across all projects.
    *   Manage user roles and profiles.

---

## 2️⃣ Authentication & User Profile Architecture

### 2.1 Supabase Auth Flow
The system leverages Supabase's built-in authentication service.

*   **`auth.users` Table:** This is the core table managed by Supabase Auth, storing user identities (email, phone, password hash, etc.). The application code does **not** have direct API access to this table.
*   **Login:** The Flutter app uses `supabase.auth.signInWithPassword()` to authenticate the user. Supabase returns a JWT (JSON Web Token) upon successful login.
*   **Session Handling:** The `supabase_flutter` library securely persists the JWT on the device. All subsequent API requests from the client automatically include this token in the Authorization header. Supabase validates the token and makes the user's `uid` and `role` available within RLS policies and database functions.

### 2.2 `user_profiles` Table
A public `user_profiles` table is maintained to store application-specific user data that is not present in `auth.users`.

*   **Purpose:** The primary purpose of this table is to store the user's **role** (`admin`, `site_manager`), which is essential for authorization. It also holds metadata like `full_name`, `phone`, and `avatar_url`.
*   **Relationship with `auth.users`:**
    *   It has a one-to-one relationship with `auth.users`, using the user's `id` (a UUID) as both the Primary Key and a Foreign Key referencing `auth.users(id)`.
    *   A database trigger (`on_auth_user_created` executing the `handle_new_user` function) automatically creates a corresponding profile in `user_profiles` whenever a new user signs up in `auth.users`. This ensures data consistency.

---

## 3️⃣ Role & Permission Model

The application uses a simple but effective role-based access control (RBAC) system, enforced at the database level by RLS.

### Super Admin
*   **Responsibilities:** System ownership. Can manage all data, including other Admins. This role is for initial setup and emergency administrative tasks.
*   **Data Ownership:** Owns all data in the system.
*   **Flutter UI Visibility:** Sees all projects, all users, all reports. Has access to system settings and user role management.
*   **Backend Enforcement:** RLS policies often check `role = 'super_admin'` for destructive operations like deleting a project or another user's profile.

### Admin
*   **Responsibilities:** Manages the overall business operations. Creates projects, assigns Site Managers, and views cross-project analytics.
*   **Data Ownership:** Has read/write access to most business data across all projects. Cannot delete other Admins.
*   **Flutter UI Visibility:** Similar to Super Admin but may have fewer system-level configuration options. Can view and manage all projects.
*   **Backend Enforcement:** Most RLS policies use the helper function `is_admin_or_super()` to grant access. This function checks if the current user's role in `user_profiles` is `admin` or `super_admin`.

### Site Manager
*   **Responsibilities:** On-the-ground project execution and reporting. Manages daily logs for their assigned projects.
*   **Data Ownership:** Can only create, view, and update data related to projects they are explicitly assigned to in the `project_assignments` table. They cannot see or interact with data from other projects.
*   **Flutter UI Visibility:** The UI is filtered to show only assigned projects. They cannot see user management or system-wide settings.
*   **Backend Enforcement:** RLS policies for all project-related tables (e.g., `labour`, `stock_items`, `daily_reports`) contain a crucial `WHERE` clause that checks for the user's assignment: `EXISTS (SELECT 1 FROM project_assignments WHERE project_id = ... AND user_id = auth.uid())`. This is the cornerstone of the security model.

---

## 4️⃣ Database Schema – Table-by-Table Documentation

This section details the final, consolidated schema of the core tables.

---
### Table: `user_profiles`

*   **Purpose:** Stores application-specific data for a user, most importantly their role.
*   **What this table represents in the Flutter app:** The user's profile screen, user selection dropdowns for Admins.

**Columns**
| Column | Type | Description | Used In Flutter Screen |
|---|---|---|---|
| `id` | `UUID` | PK, FK to `auth.users.id`. | (Internal) |
| `role` | `TEXT` | `super_admin`, `admin`, or `site_manager`. | (Authorization logic) |
| `full_name` | `TEXT` | User's display name. | Profile Screen, User Lists |
| `phone` | `TEXT` | User's contact number. | Profile Screen |
| `avatar_url` | `TEXT` | URL to profile picture in Supabase Storage. | App Header, Profile Screen |
| `email` | `TEXT` | User's email, synced from `auth.users`. | Profile Screen, User Lists |
| `company_id`| `UUID` | For future multi-tenancy support. | (Not currently used) |
| `created_at`| `TIMESTAMPTZ` | Timestamp of profile creation. | (Internal) |
| `updated_at`| `TIMESTAMPTZ` | Timestamp of last profile update. | (Internal) |

**Relationships**
*   **Parent:** `auth.users` (via `id`).

**RLS Policy Summary**
*   **SELECT:** Users can see their own profile. Admins/Super Admins can see all profiles.
*   **INSERT:** A user can insert their own profile (on signup). Admins can insert new profiles.
*   **UPDATE:** Users can update their own profile. Admins can update any profile.
*   **DELETE:** Only Super Admins can delete profiles.

**Flutter Usage**
*   The app fetches the current user's profile on startup to determine their role and display their name/avatar.
*   Admins use a dedicated screen to list and manage all `user_profiles`.

---
### Table: `projects`

*   **Purpose:** Defines a single construction project. This is the central object that most other data links to.
*   **What this table represents in the Flutter app:** A project card on the dashboard; the main project details screen.

**Columns**
| Column | Type | Description | Used In Flutter Screen |
|---|---|---|---|
| `id` | `UUID` | PK. | (Internal) |
| `name` | `TEXT` | The official name of the project. | Project List, Project Header |
| `description`| `TEXT` | A detailed description of the project. | Project Details |
| `location` | `TEXT` | Physical address or location of the site. | Project Details |
| `status` | `TEXT` | `planning`, `in_progress`, `on_hold`, `completed`, `cancelled`. | Project Card, Project Status Indicator |
| `start_date`| `DATE` | The official start date of the project. | Project Details |
| `end_date` | `DATE` | The planned end date of the project. | Project Details |
| `budget` | `DECIMAL` | The total budget allocated for the project. | Project Details (Admin) |
| `client_name`| `TEXT` | Name of the client for whom the project is being built. | Project Details |
| `project_type`|`TEXT`| `Residential`, `Commercial`, `Infrastructure`, `Industrial`. | Project Details, Filters |
| `progress` | `INT` | Completion percentage (0-100). | Project Dashboard, Progress Bar |
| `created_by`| `UUID` | FK to `user_profiles.id` of the admin who created it. | (Internal) |
| `deleted_at`| `TIMESTAMPTZ`| For soft-delete functionality. Null if active. | (Authorization logic) |
| `created_at`| `TIMESTAMPTZ` | Timestamp of creation. | (Internal) |
| `updated_at`| `TIMESTAMPTZ` | Timestamp of last update. | (Internal) |

**Relationships**
*   **Parent:** `user_profiles` (via `created_by`).
*   **Children:** `project_assignments`, `stock_items`, `labour`, `blueprints`, `daily_reports`, etc., all link back to this table via `project_id`.

**RLS Policy Summary**
*   **SELECT:** Admins see all non-deleted projects. Site Managers see only their assigned, non-deleted projects.
*   **INSERT:** Only Admins can create projects.
*   **UPDATE:** Only Admins can update projects.
*   **DELETE:** Only Super Admins can (soft) delete projects.

**Flutter Usage**
*   The main screen lists all projects visible to the user.
*   Tapping a project navigates to a detail screen where all related data (stock, labor, etc.) is fetched using the project's `id`.

---
### Table: `project_assignments`

*   **Purpose:** Links a user (`site_manager`) to a `project`, granting them access.
*   **What this table represents in the Flutter app:** The core of the permission model for Site Managers.

**Columns**
| Column | Type | Description | Used In Flutter Screen |
|---|---|---|---|
| `id` | `UUID` | PK. | (Internal) |
| `project_id`| `UUID` | FK to `projects.id`. | (Internal) |
| `user_id` | `UUID` | FK to `user_profiles.id`. | (Internal) |
| `assigned_role`| `TEXT` | `manager`, `member`, `viewer`. Defines the level of access. | (Authorization logic) |
| `assigned_at` | `TIMESTAMPTZ`| When the assignment was made. | Admin UI |
| `assigned_by` | `UUID` | FK to the admin's `user_profiles.id`. | (Internal) |

**Relationships**
*   **Parents:** `projects` (via `project_id`), `user_profiles` (via `user_id`).

**RLS Policy Summary**
*   **SELECT:** Users can see their own assignments. Admins can see all assignments.
*   **INSERT/UPDATE/DELETE:** Only Admins can manage assignments.

**Flutter Usage**
*   Admins manage assignments from a Project Settings screen.
*   The app does not typically query this table directly. Instead, RLS policies on *other tables* query it implicitly to determine access rights.

---
### Table: `stock_items`
*   **Purpose:** Defines the master list of materials available for a project. It acts as a central inventory.
*   **What this table represents in the Flutter app:** The main stock/inventory list screen for a project.

**Columns**
| Column | Type | Description | Used In Flutter Screen |
|---|---|---|---|
| `id` | `UUID` | PK. | (Internal) |
| `name` | `TEXT` | Name of the material (e.g., "Cement Bag"). | Stock List |
| `category` | `TEXT` | Category of material (e.g., "Civil", "Electrical"). | Stock List Filters |
| `unit` | `TEXT` | Unit of measurement (e.g., "bags", "kg", "nos"). | Stock List |
| `quantity` | `DECIMAL` | Current calculated quantity in stock. | Stock List |
| `min_quantity`| `DECIMAL` | Minimum required stock level. | (For future alerts) |
| `low_stock_threshold`|`DECIMAL`| Threshold for low stock warnings. | Dashboard Widgets |
| `project_id`| `UUID` | FK to `projects.id`. | (Internal) |
| `created_by`| `UUID` | FK to `auth.users.id`. | (Internal) |

**Relationships**
*   **Parent:** `projects` (via `project_id`).
*   **Children:** `material_logs` links to this table via `item_id`.

**RLS Policy Summary**
*   **SELECT:** Admins see all stock. Site Managers see stock for assigned projects.
*   **INSERT/UPDATE/DELETE:** Admins and assigned Site Managers have full control over stock items for their projects.

**Flutter Usage**
*   A dedicated screen within a project shows a list of all `stock_items`.
*   The `quantity` is updated via triggers or functions when a new entry is made in `material_logs`.

---
### Table: `material_logs`
*   **Purpose:** Records every transaction for a stock item (material moving in or out). This provides an auditable history of stock movement.
*   **What this table represents in the Flutter app:** The history/log view for a single material.

**Columns**
| Column | Type | Description | Used In Flutter Screen |
|---|---|---|---|
| `id` | `UUID` | PK. | (Internal) |
| `project_id`| `UUID` | FK to `projects.id`. | (Internal) |
| `item_id` | `UUID` | FK to `stock_items.id`. | (Internal) |
| `log_type` | `TEXT` | `inward` (received) or `outward` (consumed). | Log Entry Form |
| `quantity` | `DECIMAL`| The amount of material moved. | Log Entry Form |
| `activity` | `TEXT` | Short description of the activity (e.g., "Foundation Work"). | Log History |
| `challan_url`| `TEXT` | Link to delivery receipt/challan in Storage. | Log Entry Form |
| `logged_by` | `UUID` | FK to `auth.users.id` of the user who logged the entry. | Log History |
| `logged_at` | `TIMESTAMPTZ`| The date and time of the transaction. | Log Entry Form |
| `notes` | `TEXT` | Additional notes about the transaction. | Log Entry Form |

**Relationships**
*   **Parents:** `projects` (via `project_id`), `stock_items` (via `item_id`).

**RLS Policy Summary**
*   **SELECT:** Admins see all logs. Site Managers see logs for their assigned projects.
*   **INSERT:** Admins and assigned Site Managers can add new logs.
*   **UPDATE/DELETE:** Admins and assigned Site Managers can modify/delete logs.

**Flutter Usage**
*   Site Managers use a form to create a new `material_logs` entry when stock is received or used.
*   A "History" button on the `stock_items` screen lists all `material_logs` for that item.

---
### Table: `labour`
*   **Purpose:** A master list of all laborers associated with a project, including their skills and wage details.
*   **What this table represents in the Flutter app:** The "Manage Labour" screen.

**Columns**
| Column | Type | Description | Used In Flutter Screen |
|---|---|---|---|
| `id` | `UUID` | PK. | (Internal) |
| `name` | `TEXT` | Full name of the laborer. | Labour List |
| `phone` | `TEXT` | Contact number. | Labour Details |
| `skill_type`| `TEXT` | Skill category (e.g., "Mason", "Electrician"). | Labour List, Filters |
| `daily_wage`| `DECIMAL`| The agreed-upon daily wage. | Labour Details |
| `project_id`| `UUID` | FK to the project they are primarily associated with. | (Internal) |
| `status` | `TEXT` | `active` or `inactive`. | Labour List |
| `created_by`| `UUID` | FK to `auth.users.id`. | (Internal) |

**Relationships**
*   **Parent:** `projects` (via `project_id`).
*   **Child:** `labour_attendance` links via `labour_id`.

**RLS Policy Summary**
*   **SELECT/INSERT/UPDATE/DELETE:** Admins have full access. Site Managers have full access but only for their assigned projects.

**Flutter Usage**
*   Admins or Site Managers add/edit laborers from a dedicated screen within a project.
*   The list of active laborers is used to populate the attendance marking screen.

---
### Table: `labour_attendance`
*   **Purpose:** Tracks the daily attendance of each laborer on a specific date.
*   **What this table represents in the Flutter app:** The daily attendance marking sheet.

**Columns**
| Column | Type | Description | Used In Flutter Screen |
|---|---|---|---|
| `id` | `UUID` | PK. | (Internal) |
| `labour_id` | `UUID` | FK to `labour.id`. | (Internal) |
| `project_id`| `UUID` | FK to `projects.id`. | (Internal) |
| `date` | `DATE` | The specific date of the attendance record. | Attendance Sheet Header |
| `status` | `TEXT` | `present`, `absent`, or `half_day`. | Attendance Radio Buttons |
| `hours_worked`| `DECIMAL`| Number of hours worked (if applicable). | Attendance Form |
| `notes` | `TEXT` | Any notes for the day (e.g., "Overtime"). | Attendance Form |
| `recorded_by`| `UUID` | FK to `auth.users.id`. | (Internal) |
| `UNIQUE(labour_id, date)` | | Ensures only one record per laborer per day. | (DB Constraint) |

**Relationships**
*   **Parents:** `labour` (via `labour_id`), `projects` (via `project_id`).

**RLS Policy Summary**
*   **SELECT/INSERT/UPDATE/DELETE:** Admins have full access. Site Managers have full access for their assigned projects.

**Flutter Usage**
*   The app displays a list of laborers for the selected project and date. The Site Manager marks the status for each one.
*   This data is used to calculate labor costs for reports.

---
### Table: `daily_reports` (`daily_site_logs`)
*   **Purpose:** A summary of the day's activities, issues, and plans for a project.
*   **What this table represents in the Flutter app:** The "Daily Site Log" or "Daily Progress Report (DPR)" form.

**Columns**
| Column | Type | Description | Used In Flutter Screen |
|---|---|---|---|
| `id` | `UUID` | PK. | (Internal) |
| `project_id`| `UUID` | FK to `projects.id`. | (Internal) |
| `report_date`| `DATE` | The date the report is for. | Report Header |
| `weather` | `TEXT` | Weather conditions (e.g., "Sunny", "Rainy"). | Report Form |
| `work_summary`| `TEXT` | Detailed summary of work completed. | Report Form |
| `issues` | `TEXT` | Any problems or blockers encountered. | Report Form |
| `tomorrow_plan`| `TEXT` | The plan for the next working day. | Report Form |
| `labour_count`| `INTEGER`| Total number of laborers present. | Report Form |
| `created_by`| `UUID` | FK to `user_profiles.id`. | (Internal) |
| `UNIQUE(project_id, report_date)`| | Ensures one report per project per day. | (DB Constraint) |

**Relationships**
*   **Parent:** `projects` (via `project_id`).

**RLS Policy Summary**
*   **SELECT/INSERT/UPDATE/DELETE:** Admins and assigned Site Managers have full access.

**Flutter Usage**
*   Site Managers fill out and submit this form at the end of each day.
*   Admins can view a list of all daily reports for any project to monitor progress.

---
### Table: `blueprints` (`documents`)
*   **Purpose:** Stores metadata for project-related files like drawings, plans, and other documents.
*   **What this table represents in the Flutter app:** The "Documents" or "Blueprints" section.

**Columns**
| Column | Type | Description | Used In Flutter Screen |
|---|---|---|---|
| `id` | `UUID` | PK. | (Internal) |
| `project_id`| `UUID` | FK to `projects.id`. | (Internal) |
| `folder_name`| `TEXT` | A logical folder for grouping files (e.g., "Structural", "Electrical").| Document List UI |
| `file_name` | `TEXT` | The name of the uploaded file. | Document List UI |
| `file_path` | `TEXT` | The full path in Supabase Storage. | (Internal, for downloads) |
| `is_admin_only`|`BOOLEAN`| If true, only visible to Admins. | (Authorization Logic) |
| `uploader_id`| `UUID` | FK to `auth.users.id` of the user who uploaded the file. | Document Details |
| `deleted_at`| `TIMESTAMPTZ`| For soft-delete functionality. | (Authorization logic) |

**Relationships**
*   **Parent:** `projects` (via `project_id`).

**RLS Policy Summary**
*   **SELECT:** Admins see all non-deleted files. Site Managers see non-deleted, non-admin-only files for their assigned projects.
*   **INSERT/UPDATE/DELETE:** Only Admins can manage blueprint records and the underlying files in storage.

**Flutter Usage**
*   Users can browse files grouped by `folder_name`.
*   Tapping a file downloads it from Supabase Storage using the `file_path`.
*   Admins/Site Managers can upload new files.

---

*Note on `bills`, `machinery`, `vendors`: The initial schema contains tables for `bills` and `machinery` with RLS policies similar to the other tables. A dedicated `vendors` table is missing; `bills.vendor_name` is used instead. These are documented in less detail as they appear less central from the migration history.*

---

## 6️⃣ Project Lifecycle (Flutter Perspective)

### 6.1 Admin Creates Project
1.  **Flutter UI:** The Admin fills out a form in the Flutter app with the project's `name`, `client_name`, `location`, `budget`, etc.
2.  **Validation:** The app performs basic client-side validation (e.g., required fields).
3.  **Database Insert:** The app calls `supabase.from('projects').insert({...})`.
    *   The RLS policy `"Admins can create projects"` is triggered. It checks if the user's role is `admin` or `super_admin`.
    *   If the check passes, the new project record is inserted into the `projects` table.

### 6.2 Assign Site Manager
1.  **Flutter UI:** From the project settings screen, the Admin selects a user (from a list populated by `user_profiles` where `role = 'site_manager'`) to assign to the current project.
2.  **Database Insert:** The app calls `supabase.from('project_assignments').insert({ project_id: ..., user_id: ... })`.
    *   The RLS policy `"Admins can manage assignments"` is triggered, which verifies the current user is an Admin.
    *   The insert creates the link between the user and the project.
3.  **RLS Dependency:** This `project_assignments` record is now the key that will grant the Site Manager access to all other data related to this `project_id`.
4.  **Common Failure Reasons:** An insert can fail if the Admin's token has expired, or if a unique constraint violation occurs (trying to assign the same user to the same project twice).

### 6.3 Site Manager Project Access
1.  **Flutter UI:** When the Site Manager logs in, their home screen calls `supabase.from('projects').select('*')`.
2.  **Backend Restriction:**
    *   The RLS policy `"Site managers can view assigned projects"` is executed for this `SELECT` query.
    *   The policy performs a subquery on `project_assignments` to find which projects the current user (`auth.uid()`) is linked to.
    *   The database returns **only the project rows** that match the assignment.
    *   The same logic applies to every subsequent query for stock, labour, etc., ensuring perfect data isolation.

---

## 7️⃣ Stock Management Module

### 7.1 Stock Master (Admin)
The Admin is responsible for the initial setup of the stock master (`stock_items`) for a project. This involves creating entries for every type of material that will be used (e.g., "Cement", "Steel Rebar", "Bricks"). This can be done via a dedicated "Manage Stock" screen in the Flutter app accessible to Admins.

### 7.2 Daily Stock Logs (Site Manager)
The Site Manager is responsible for logging all material movements using the `material_logs` table.
*   **Inward:** When new material arrives on site, the Site Manager creates an `inward` log. This transaction will (via a database trigger or app logic) increase the `quantity` in the corresponding `stock_items` record.
*   **Outward:** When material is consumed for construction, the Site Manager creates an `outward` log. This decreases the `quantity` in `stock_items`.

### 7.3 Balance Calculation Logic
The "current quantity" of a stock item (`stock_items.quantity`) is the canonical value. It is calculated and updated as follows:
`new_quantity = previous_quantity + inward_log_quantity - outward_log_quantity`
This calculation should be handled robustly, ideally within a database transaction or trigger when a `material_logs` entry is created, to prevent race conditions.

### 7.4 Flutter UI Considerations
*   The UI should present a clear form for logging inward/outward stock, including fields for quantity, challan/receipt photo upload, and notes.
*   The main stock list (`stock_items`) should clearly display the `name`, `unit`, and current `quantity`.
*   A "History" view for each stock item should list all its `material_logs` chronologically.

### 7.5 Missing Schema or Improvements
The logic for automatically updating `stock_items.quantity` from `material_logs` is not explicitly defined as a trigger in the provided migrations. This should be implemented as a database trigger to ensure data integrity and prevent the Flutter app from having to perform this calculation.

---

## 8️⃣ Labour Management Module

### 8.1 Labour Profile Creation
Admins or Site Managers create profiles for each laborer in the `labour` table, including their name, skill, and daily wage. This is done per project.

### 8.2 Daily Attendance Logging
1.  The Site Manager selects a date in the Flutter app.
2.  The app fetches all `active` laborers from the `labour` table for the current project.
3.  For each laborer, the Site Manager marks their status (`present`, `absent`, `half_day`).
4.  The app inserts or updates a record in the `labour_attendance` table for that `labour_id` and `date`. The `UNIQUE(labour_id, date)` constraint prevents duplicate entries.

### 8.3 Wage & Cost Calculation
Labour costs can be calculated for any period by querying the `labour_attendance` table:
`total_cost = SUM(l.daily_wage * attendance_multiplier)`
Where `attendance_multiplier` is `1` for 'present', `0.5` for 'half_day', and `0` for 'absent'. This calculation can be done in the Flutter app for reporting or in a database RPC function for more complex analytics.

### 8.4 Flutter Validation Rules
*   The attendance form should default to the current date.
*   The app should prevent marking attendance for future dates.
*   Once attendance is submitted, it might be locked for editing by Site Managers after a certain period (e.g., 24 hours) to ensure data integrity, though this rule is not currently in the schema.

---

## 9️⃣ Daily Logs & Media Uploads

### Daily Activity Logs
The `daily_reports` table captures the end-of-day summary. The Flutter app presents a simple form with text fields for `work_summary`, `issues`, and `tomorrow_plan`. Site Managers are expected to fill this out daily.

### Photo & Document Uploads
The system uses Supabase Storage for all file uploads.
1.  **Blueprints/Documents:** Files are uploaded to the `blueprints` bucket. The path in the bucket is structured as `{project_id}/{folder_name}/{file_name}`. A corresponding metadata record is created in the `public.blueprints` table.
2.  **Receipts/Bills:** Files are uploaded to a `bills` or `receipts` bucket, likely following a path structure like `{project_id}/{bill_id}/{file_name}`.
3.  **Access Control:** Access to these files is controlled by Storage RLS policies. These policies use helper functions like `is_assigned_to_project_from_path` to parse the `project_id` from the file path and check if the requesting user is assigned to that project. This is a very secure and efficient pattern.

### Time-based Edit Restrictions
The current schema does not enforce time-based editing restrictions (e.g., preventing a Site Manager from editing a daily log after 24 hours). This would be a valuable addition to ensure the immutability of historical records. It can be implemented with an RLS policy on `UPDATE` that checks `created_at < NOW() - INTERVAL '24 hours'`.

### Review & Audit Flow
The `operation_logs` table provides a comprehensive audit trail. It automatically logs key activities like project creation, status changes, and blueprint uploads. The Flutter app can display this as an "Activity Feed" for Admins to monitor system-wide actions.

---

## 🔟 Row Level Security (RLS) – Deep Dive

### Why RLS is Critical
RLS is the security backbone of this application. It ensures that a user can **only** see the data they are authorized to see, even if the Flutter client code is compromised or a malicious request is attempted. It moves the security logic from the client to the database, which is the single source of truth.

### Admin vs. Site Manager Enforcement
*   **Admin:** RLS policies for Admins are straightforward. They typically start with `USING (public.is_admin_or_super())`, granting wide access. The `is_admin_or_super()` function is a `SECURITY DEFINER` function, meaning it runs with the permissions of the function owner, bypassing RLS to safely check the `role` in `user_profiles` without causing infinite recursion.
*   **Site Manager:** RLS policies for Site Managers are based on project membership. The core logic is almost always: `USING (public.is_assigned_to_project(project_id))`. This function checks if an entry exists in `project_assignments` linking the current user (`auth.uid()`) to the `project_id` of the row being accessed.

### Project-based Access using `EXISTS()`
The pattern `EXISTS (SELECT 1 FROM project_assignments WHERE ...)` is highly efficient. The database can use indexes on `project_assignments` to very quickly determine if a user has access, without needing to perform a full join.

### Common Supabase RLS Mistakes (and how this schema avoids them)
*   **RLS Recursion:** A common mistake is a policy on `user_profiles` that itself needs to read `user_profiles` to check a role. The schema correctly avoids this by using `SECURITY DEFINER` helper functions (`is_admin_or_super`, `get_my_role`), which can bypass RLS for the specific task of checking the role.
*   **Leaking Data in Functions:** All RPC functions (`get_dashboard_stats`, etc.) are designed to respect user roles by filtering data based on the user's accessible projects internally.

### How Flutter Errors Usually Appear
If RLS denies a request:
*   A `SELECT` query will simply return an empty list, as if the data doesn't exist.
*   An `INSERT`, `UPDATE`, or `DELETE` will throw a `PostgrestException` with a "new row violates row-level security policy" or "permission denied" message. The Flutter app should handle these exceptions gracefully, informing the user that they don't have permission for the action.

---

## 1️⃣1️⃣ Missing / Broken / Risky Items

### Problem 1: Inconsistent RPC Function Logic
*   **Problem:** The RPC function `get_project_stats` in migration `016_update_projects.sql` attempts to query a column `entry_type` on the `stock_items` table. This column does not exist. The intended logic was likely to query the `material_logs` table and use its `log_type` column ('inward'/'outward').
*   **Impact on Flutter App:** Calling this RPC function will fail with a SQL error. The project stats dashboard widget will be broken.
*   **Recommended Fix:** The function should be rewritten to `SUM` quantities from the `material_logs` table grouped by `log_type`.

### Problem 2: Missing `vendors` Table
*   **Problem:** The schema uses a simple `TEXT` field (`bills.vendor_name`) for vendors. There is no dedicated `vendors` table.
*   **Impact on Flutter App:** This prevents tracking vendor history, contact information, or outstanding payments across multiple bills. It also allows for data entry errors (e.g., "Vendor A" vs. "vendor a").
*   **Recommended Fix:** Create a `vendors` table with `id`, `name`, `contact_person`, `phone`, etc. Replace `bills.vendor_name` with a `vendor_id UUID` Foreign Key to the new `vendors` table.

### Problem 3: Stock Quantity Calculation is Not Atomic
*   **Problem:** The migrations do not define a database trigger to automatically update `stock_items.quantity` when a log is added to `material_logs`.
*   **Impact on Flutter App:** This puts the responsibility on the Flutter client to perform this critical calculation. If two users perform stock operations simultaneously, a race condition could lead to an incorrect final quantity.
*   **Recommended Fix:** Create a database trigger on the `material_logs` table. After an `INSERT`, this trigger should lock the corresponding row in `stock_items` and update its `quantity` column based on the `log_type` and `quantity` of the new log.

### Problem 4: No Time-Based Edit Locks on Logs
*   **Problem:** There are no RLS policies preventing a Site Manager from modifying or deleting old `labour_attendance` or `daily_reports` records.
*   **Impact on Flutter App:** This can compromise the integrity of historical project data. A user could change a report from weeks ago, affecting historical cost analysis.
*   **Recommended Fix:** Add an `UPDATE` policy to these tables that prevents changes if the record is older than a set period (e.g., 24 or 48 hours), except for Admins. Example policy clause: `USING (created_at > now() - interval '24 hours' OR public.is_admin_or_super())`.

---

## 1️⃣2️⃣ Recommended Final ER Architecture

For a cleaner, more scalable architecture, the following is recommended:

*   **Clear Table Ownership:**
    *   **Admin-Owned:** `projects`, `user_profiles`, `project_assignments`. These are system-level tables.
    *   **Project-Owned:** All other tables (`stock_items`, `labour`, `daily_reports`, etc.) should be seen as belonging to a project, enforced by the mandatory `project_id` foreign key.
*   **Data Boundaries:** The RLS policies correctly establish strong data boundaries. A Site Manager's entire world exists within the set of `project_id`s they are assigned to. This is a solid foundation for scaling.
*   **Introduce `vendors` and `companies`:**
    *   Add a `vendors` table as mentioned in the previous section.
    *   Activate the `company_id` in `user_profiles` and create a `companies` table. This would allow the entire application to be sold as a multi-tenant SaaS solution in the future, where each client company has its own isolated set of users and projects.
*   **Mermaid ERD Description (Conceptual):**
    ```mermaid
    erDiagram
        auth.users ||--o{ user_profiles : "has one"
        user_profiles ||--|{ projects : "creates"
        user_profiles ||--o{ project_assignments : "is assigned"
        projects ||--|{ project_assignments : "has"
        projects ||--|{ stock_items : "has"
        projects ||--|{ labour : "has"
        projects ||--|{ daily_reports : "has"
        projects ||--|{ blueprints : "has"
        stock_items ||--|{ material_logs : "has logs"
        labour ||--|{ labour_attendance : "has logs"
    ```

---

## 1️⃣3️⃣ Flutter Development Guidelines

### Structuring Flutter Data Access
*   **Repository Pattern:** Use the Repository Pattern to abstract data sources. Create a `ProjectRepository`, `StockRepository`, etc. These repositories will contain the Supabase query logic.
*   **State Management:** Use a robust state management solution (like Riverpod or Bloc) to manage the application state, fetch data from repositories, and provide it to the UI.
*   **Data Models:** Create Dart classes for each database table (e.g., `Project`, `StockItem`) with `fromJson` and `toJson` methods for easy serialization.

### Best Practices for Supabase Queries
*   **Select Specific Columns:** Always specify the columns you need: `supabase.from('projects').select('id, name, status')`. Avoid `select('*')` in production code.
*   **Use RPC for Complex Logic:** For dashboards or complex calculations, use the existing RPC functions (`get_dashboard_stats`). This is much faster than making multiple separate queries from Flutter.
*   **Real-time:** Use `supabase.from('...').stream(...)` for data that needs to be updated live in the UI, such as the status of a project or the current stock quantity.

### Error Handling Patterns
*   Wrap all Supabase calls in `try...catch` blocks.
*   Specifically catch `PostgrestException` to handle database-related errors (e.g., RLS violations, network issues).
*   Provide user-friendly error messages. If an update fails due to an RLS policy, tell the user "You do not have permission to perform this action" instead of showing a raw database error.

### Security Do’s & Don’ts
*   **DO** rely on RLS for all data security.
*   **DON'T** ever embed a service role key or any other secret in the Flutter application. Use only the `anon_key`.
*   **DO** validate user input on the client side for better UX, but remember that the ultimate security validation happens in the database via RLS and `CHECK` constraints.
*   **DON'T** expose sensitive data in RPC functions that don't check the user's role. All functions should respect the permission model.

---

## 1️⃣4️⃣ Appendix

### Naming Conventions
*   **Tables:** `snake_case`, plural (e.g., `projects`, `stock_items`).
*   **Columns:** `snake_case` (e.g., `project_id`, `created_at`).
*   **Functions:** `snake_case` (e.g., `get_my_role`, `is_assigned_to_project`).
*   **Policies:** Quoted descriptive names (e.g., `"Admins can view all projects"`).

### Indexing Strategy
The schema uses a solid indexing strategy:
*   **Primary Keys:** All tables have UUID primary keys.
*   **Foreign Keys:** Indexes are automatically created for foreign key columns (`project_id`, `user_id`).
*   **RLS Performance:** Composite indexes are created on columns frequently used in RLS policies (e.g., `idx_project_assignments_user_project_role`).
*   **Query Performance:** Indexes are added for columns used in `WHERE` clauses, `ORDER BY` clauses, and for cursor pagination (e.g., `idx_projects_cursor` on `created_at`).

### Audit & Backup Ideas
*   **Audit:** The `operation_logs` table provides a good application-level audit trail. For a lower-level audit, Supabase offers tools like `pgAudit`.
*   **Backup:** Regular, automated database backups should be configured from the Supabase dashboard. It is critical to test the restoration process periodically.

### Future Extensibility Tips
*   **Multi-Tenancy:** The `company_id` in `user_profiles` is the first step. To make the app fully multi-tenant, this `company_id` should be added to the `projects` table, and all RLS policies would need an additional check for `company_id`.
*   **Notifications:** A `notifications` table could be added. Triggers on other tables (e.g., when `stock_items.quantity` falls below `low_stock_threshold`) could insert records into this table to create an in-app notification system.
*   **Reporting Module:** For more advanced reporting, consider integrating a dedicated reporting tool or using Supabase RPC functions that aggregate data into complex JSON objects suitable for charting libraries.
