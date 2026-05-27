# Clivi Management - User Manual

**Version 1.0.0**
Construction project management made simple and efficient.

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [User Roles](#user-roles)
3. [Navigation](#navigation)
4. [Dashboard](#dashboard)
5. [Projects](#projects)
6. [Materials & Stock](#materials--stock)
7. [Machinery](#machinery)
8. [Labour & Attendance](#labour--attendance)
9. [Blueprints](#blueprints)
10. [Bills](#bills)
11. [Reports & Insights](#reports--insights)
12. [Vendor Analytics](#vendor-analytics)
13. [Profile & Account](#profile--account)

---

## Getting Started

### Login

1. Open the app in your browser or on your device.
2. Enter your **email** and **password** on the login screen.
3. You will be redirected to your role-specific dashboard.

### Forgot Password

1. On the login screen, tap **Forgot Password**.
2. Enter your registered email address.
3. Check your email for the password reset link.

---

## User Roles

Clivi Management has three user roles. Each role has different access levels:

| Feature | Super Admin | Admin | Site Manager |
|---------|:-----------:|:-----:|:------------:|
| View Dashboard | Yes | Yes | Yes |
| Create/Edit Projects | Yes | Yes | No |
| Delete Projects | Yes | Yes | No |
| Assign Site Managers | Yes | Yes | No |
| Receive Materials | Yes | Yes | Yes |
| Consume Materials | Yes | Yes | Yes |
| Log Machinery | Yes | Yes | Yes |
| Manage Labour | Yes | Yes | Yes |
| Mark Attendance | Yes | Yes | Yes |
| Upload Blueprints | Yes | Yes | Yes |
| Create Bills | No | No | Yes |
| Approve Bills | Yes | Yes | No |
| View Reports | Yes | Yes | No |
| Vendor Analytics | Yes | Yes | No |
| Manage Master Data | Yes | Yes | No |
| Manage Site Managers | Yes | Yes | No |

---

## Navigation

### Desktop (Web)

On desktop, you will see a **dark sidebar** on the left with these items:

- **Home** — Your dashboard with KPI stats, quick actions, active projects, and recent activity
- **Projects** — List of all projects (admin) or assigned projects (site manager)
- **Bills** — View, create, and manage bills
- **Reports** — Financial insights and analytics (admin only)
- **Profile** — Your profile, account settings, and quick links

The sidebar stays visible on every page. The currently active section is highlighted with a blue accent bar.

### Mobile

On mobile, a **bottom navigation bar** appears on the 5 main screens listed above. When you navigate into a sub-page (e.g., a project detail), the bottom bar hides and you use the back button to return.

---

## Dashboard

The dashboard is your home screen. It shows:

### KPI Stats (4 cards)

- **Active Projects** — Number of currently running projects. Tap to view the full list.
- **Total Workers** — Count of all workers across projects.
- **Low Stock Items** — Items below their stock threshold.
- **Blueprints** — Total uploaded blueprint documents.

### Quick Actions (4 tiles)

Shortcuts to frequently used sections:

- **Vendors** — Jump to the vendor/supplier master list
- **Machinery** — Jump to the machinery master list
- **Managers** — Jump to site manager management
- **Materials** — Jump to the material master list

### Active Projects

A list of your currently active projects showing name, type, location, and completion progress. Tap **View All** to see the full project list.

### Recent Activity

A timeline of the latest operations across all projects (material receipts, project updates, labour changes, etc.).

---

## Projects

### Viewing Projects

1. Go to **Projects** from the sidebar.
2. Use the **search bar** to find a project by name.
3. Use the **filter button** (funnel icon) to filter by status: Planning, In Progress, On Hold, Completed, Cancelled.
4. On desktop, projects display in a 2-3 column grid. On mobile, they appear as a scrollable list.

Each project card shows:
- Status badge (In Progress, Completed, etc.)
- Project type badge (Residential, Commercial, etc.)
- Project name and client name
- Location and start date
- Number of assigned managers
- Budget amount
- Completion progress bar with percentage

### Creating a Project (Admin only)

1. On the Projects page, tap the **+ New Project** button.
2. Fill in the form:
   - **Project Name** (required)
   - **Client Name**
   - **Start Date** (required)
   - **Location**
   - **Budget**
   - **Project Type** (Residential, Commercial, Infrastructure, Industrial)
   - **Description**
3. Optionally assign **Site Managers** to the project.
4. Tap **Create Project** to save.

### Project Detail

Tap any project card to view its detail page. Here you can:

- See the assigned site managers
- View and update the project status (Admin: tap the status badge)
- Update completion percentage (Admin: tap the progress bar)
- Edit project details (Admin: tap the edit icon)
- Delete the project (Admin: tap the delete icon)

### Project Modules

From the project detail page, navigate to three modules:

1. **Blueprints** — Upload and view project drawings/documents
2. **Operations** — Access Materials, Machinery, and Labour tracking
3. **Reports / Insights** — View project-specific financial reports

---

## Materials & Stock

### Receiving Materials (Inward)

1. Open a project → **Operations** → **Materials** tab.
2. Tap the **+ Receive** button.
3. For each material entry, fill in:
   - **Material Name** — Select from the master list or type to search
   - **Grade / Type** — Auto-populated based on selected material
   - **Quantity** — Amount received
   - **Unit** — Bags, CFT, Cum, Kg, Liters, Ton, or Units
   - **Vendor / Supplier** — Select from the list (filtered by material)
   - **Payment Type** — Cash, Online, Cheque, or Credit
   - **Bill Amount** — Total cost for this entry
4. Add multiple entries using the **+ Add Row** button.
5. Tap **Save** to record all entries.

### Consuming Materials (Outward)

1. Open a project → **Operations** → **Materials** tab.
2. Tap the **Consume** button.
3. Select the material and enter the quantity consumed.
4. Save the consumption record.

### Stock Ledger

1. Open a project → **Operations** → **Materials** → **Stock** tab.
2. View each material's:
   - **Total Received** — Cumulative inward quantity
   - **Total Consumed** — Cumulative outward quantity
   - **Balance** — Current stock on hand
   - **Low Stock Alert** — Red "LOW" badge if stock is below threshold
3. The consumption progress bar shows how much of the received quantity has been used.

### Material Master List (Admin only)

Access from the dashboard **Quick Actions** → **Materials** or from the sidebar → **Home** → **Material Master List**.

- View all materials across projects
- Add new materials to the master list
- Add grades/types for each material

### Receipt Details

When viewing material logs, tap a receipt to see:
- Receipt number, date, and vendor
- Invoice details
- Itemized list with quantity, rate, GST, and total per item
- Grand total summary

---

## Machinery

### Logging Machinery Usage

1. Open a project → **Operations** → **Machinery** tab.
2. Tap **+ Log** to record machinery usage.
3. Enter:
   - **Machinery** — Select from the master list
   - **Hours** — Duration of usage
   - **Date** — When the machinery was used
   - **Notes** — Optional remarks
4. Save the log entry.

### Machinery Master List (Admin only)

Access from the dashboard **Quick Actions** → **Machinery**.

- View all machinery/equipment
- Add new machinery to the master list
- Track usage across projects

---

## Labour & Attendance

### Labour Roster

1. Open a project → **Operations** → **Labour** tab.
2. View all workers assigned to the project.
3. Tap **+ Add Worker** to assign a new worker from the master list.

### Marking Attendance

1. Open a project → Go to **Attendance**.
2. Select the **date** using the calendar button.
3. For each worker, toggle their status: **Present**, **Absent**, or **Leave**.
4. Tap **Save** to record attendance for all workers.

### Labour Master List (Admin only)

Access from the sidebar → **Home** → **Managers** → navigate to labour section.

- View all workers in the system
- Add new workers with name, skill type, daily wage, and phone number
- Edit or delete workers (with confirmation)

---

## Blueprints

### Uploading Blueprints

1. Open a project → **Blueprints**.
2. Tap the **Upload** button.
3. Select a PDF or image file from your device.
4. The file uploads to the project's blueprint storage.

### Viewing Blueprints

1. Browse blueprint files in the project folder.
2. Tap any file to open the built-in viewer.
3. PDF files open in a full-screen viewer with zoom and page navigation.

### Deleting Blueprints (Admin only)

1. Long-press or tap the delete button on a blueprint card.
2. Confirm the deletion in the dialog.

---

## Bills

### Viewing Bills

1. Go to **Bills** from the sidebar.
2. Use the **Pending** / **Completed** tabs to switch between unpaid and paid bills.
3. Use the **Date filter** chip to filter bills by a specific date.

Each bill card shows:
- Date and amount
- Bill title
- Raised by (who created the bill)
- Status chips (Pending/Completed + payment status)
- Actions menu (edit, delete) for authorized users

### Creating a Bill (Site Manager)

1. On the Bills page, tap **+ New Bill**.
2. Fill in:
   - **Project** — Select the project this bill is for
   - **Type** — Expense or Income
   - **Title / Description**
   - **Amount (₹)**
   - **Date**
   - **Vendor Name** (optional)
   - **Payment Type** — Cash, Online, Cheque, or Credit
   - **Receipt** — Upload a PDF (optional)
3. Tap **Submit** to create the bill.

### Approving Bills (Admin)

1. On the Bills page, tap the **Approvals** button.
2. Alternatively, tap any pending bill card to open the approval sheet.
3. Set the **Payment Decision**: Pending, Will Pay, Half Paid, or Paid.
4. Toggle **Mark as Completed** to move the bill to the Completed tab.
5. Tap **Save Update**.

### Editing a Bill

1. Tap the three-dot menu (⋯) on any bill card.
2. Select **Edit**.
3. Modify the fields in the bottom sheet form.
4. Tap **Save Changes**.

### Deleting a Bill (Admin)

1. Tap the three-dot menu (⋯) on any bill card.
2. Select **Delete**.
3. Confirm the deletion in the dialog.

---

## Reports & Insights

Access from the sidebar → **Reports** (Admin only).

### Financial Health

- **Total Expenses** — Overall spending with growth percentage vs. last period.
- **Line Chart** — Monthly expense trend over time.

### Resource Split

- **Donut Chart** — Breakdown of spending by category:
  - Labour costs
  - Material costs
  - Machinery costs
- Each category shows its percentage of total spending.

### Time Period Filter

Switch between **Weekly**, **Monthly**, **Quarterly**, and **Yearly** views using the segmented control at the top.

### Vendor Filter

Filter reports by a specific vendor/supplier using the dropdown.

### Operations Reports

Detailed breakdowns of:
- **Material by Vendor & Project** — Which vendors supplied which materials to which projects
- **Machinery by Project** — Usage hours per machine per project
- **Labour by Project** — Workers and daily wages per project

### Export to PDF

Tap the **Export** button to generate a PDF report with all financial summaries and monthly breakdowns.

### Vendor Analytics

Tap the **Vendor Analytics** card (or access from within Reports) to see:
- Material supplier comparison by quantity or amount
- Bar chart of top 5 vendors
- Date range filtering
- Material type tabs (Steel, Cement)
- Supply details per vendor with project-level breakdown

---

## Profile & Account

Access from the sidebar → **Profile**.

### Your Profile

The profile page shows:
- **Hero Banner** — Your avatar, name, email, role badge, and join date
- **Contact Information** — Email, phone, position, and address
- **Quick Links** — Navigate to Projects, Bills, Reports, and Site Managers
- **Account Settings** — Edit profile, change password, sign out
- **App Info** — App version and description

### Editing Your Profile

1. Tap the **edit icon** on the hero banner, or go to **Account** → **Edit Profile**.
2. Update your:
   - Full Name
   - Phone Number
   - Position
   - Address
3. Tap **Save Changes**.

### Changing Password

1. Go to **Account** → **Change Password**.
2. This redirects to the password reset flow via email.

### Signing Out

1. Go to **Account** → **Sign Out**.
2. You will be redirected to the login page.

---

## Tips & Best Practices

- **Pull to refresh** — On any list screen, pull down to refresh data.
- **Search** — Use the search bar on the Projects page to quickly find projects.
- **Filters** — Use status filters and date filters to narrow down bills and reports.
- **Keyboard shortcuts** — On desktop, use Tab to move between form fields and Enter to submit.
- **Offline** — The app caches data locally. If you lose connection, previously loaded data remains visible.
- **Low stock alerts** — Check the Stock Ledger regularly for materials marked as "LOW".
- **Export reports** — Use the PDF export feature before meetings to share project insights.

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Can't log in | Check email/password. Use "Forgot Password" to reset. |
| Page not found | Use the "Go Home" button on the error page. |
| Data not updating | Pull to refresh, or navigate away and come back. |
| Blank screen | Check your internet connection and refresh the page. |
| Permission denied | You may not have the required role. Contact your admin. |
| Bill not visible | Check if you're on the correct tab (Pending vs Completed). |

---

## Support

For issues or feedback, contact your system administrator or visit the project repository.

---

*Clivi Management v1.0.0 — Built with Flutter*
