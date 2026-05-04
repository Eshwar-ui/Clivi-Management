# 🚀 Supabase Setup Guide for Clivi Management

This guide walks you through setting up the Supabase backend for the Clivi Management app.

## Prerequisites

- [Supabase Account](https://supabase.com)
- Project created in Supabase Dashboard

---

## Step 1: Get Your Supabase Credentials

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Navigate to **Settings → API**
4. Copy:
   - **Project URL** (e.g., `https://xxxxx.supabase.co`)
   - **anon public** key (NOT the service_role key)

---

## Step 2: Create `.env` File

In the `civil_management` folder, create a `.env` file:

```env
# Supabase Configuration
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here

# App Configuration
DEBUG_MODE=true
APP_ENV=development
```

⚠️ **IMPORTANT**: Never commit `.env` to version control!

---

## Step 3: Run Database Migrations

1. Go to **Supabase Dashboard → SQL Editor**
2. Run migrations in order:

### Migration 1: Initial Schema
- Open: `supabase/migrations/001_initial_schema.sql`
- Copy and paste into SQL Editor
- Click **Run**

### Migration 2: Fix RLS Policies (IMPORTANT!)
- Open: `supabase/migrations/002_fix_rls_policies.sql`
- Copy and paste into SQL Editor
- Click **Run**

> ⚠️ **You MUST run both migrations!** Migration 2 fixes an infinite recursion bug in RLS policies.

This will create:
- ✅ `user_profiles` table
- ✅ `projects` table
- ✅ `project_assignments` table
- ✅ `stock_items` table
- ✅ `labour` table
- ✅ `labour_attendance` table
- ✅ `machinery` table
- ✅ `bills` table
- ✅ `blueprints` table
- ✅ `daily_reports` table
- ✅ All RLS policies
- ✅ Storage buckets
- ✅ Auto-create profile trigger

---

## Step 4: Enable Email Auth

1. Go to **Authentication → Providers**
2. Ensure **Email** is enabled
3. Configure email settings:
   - ✅ Enable email confirmations (recommended)
   - ✅ Set site URL (for password reset links)

---

## Step 5: Create First Super Admin

### Option A: Via Supabase Dashboard

1. Go to **Authentication → Users**
2. Click **Add User** → **Create New User**
3. Enter email and password
4. User will be created with a profile (default role: `site_manager`)

### Option B: Via SQL Editor

After creating the user via Auth dashboard, run:

```sql
-- Replace 'USER_ID_HERE' with actual UUID from Auth → Users
UPDATE public.user_profiles 
SET role = 'super_admin', full_name = 'Super Admin'
WHERE id = 'USER_ID_HERE';
```

### Option C: Via App Signup + SQL Update

1. Use the app's signup feature
2. Verify email
3. Run the SQL above to promote to super_admin

---

## Step 6: Create Test Users (Optional)

For testing, create users with different roles:

```sql
-- After creating users via Auth, update their roles:

-- Admin user
UPDATE public.user_profiles 
SET role = 'admin', full_name = 'Admin User'
WHERE id = 'ADMIN_USER_ID';

-- Site Manager user  
UPDATE public.user_profiles 
SET role = 'site_manager', full_name = 'Site Manager'
WHERE id = 'SITE_MANAGER_USER_ID';
```

---

## Step 7: Verify Setup

### Check Tables
Go to **Table Editor** and verify all tables exist:
- [ ] user_profiles
- [ ] projects
- [ ] project_assignments
- [ ] stock_items
- [ ] labour
- [ ] labour_attendance
- [ ] machinery
- [ ] bills
- [ ] blueprints
- [ ] daily_reports

### Check RLS
Go to **Authentication → Policies** and verify:
- [ ] RLS is enabled on all tables
- [ ] Policies are created

### Check Storage
Go to **Storage** and verify buckets:
- [ ] avatars (public)
- [ ] blueprints (private)
- [ ] receipts (private)

---

## Step 8: Run the App

```bash
cd civil_management
flutter pub get
flutter run
```

---

## Troubleshooting

### "SUPABASE_URL not found"
- Ensure `.env` file exists in project root
- Check `.env` is listed in `pubspec.yaml` assets

### "Permission denied" errors
- Check RLS policies are correct
- Verify user role in `user_profiles` table

### Profile not created on signup
- Check the `on_auth_user_created` trigger exists
- Run the trigger creation SQL again if missing

### Login works but no role redirect
- Ensure `user_profiles` table has a row for the user
- Check the `role` column value is valid

---

## Role Hierarchy

| Role | Permissions |
|------|-------------|
| `super_admin` | Full system access, manage all users |
| `admin` | Manage projects, stock, labour, bills |
| `site_manager` | View/manage assigned projects only |

---

## RLS Policy Summary

### user_profiles
- Users can read/update their own profile
- Admins/Super Admins can read all profiles
- Super Admins can update any profile (including role)

### projects
- Admins/Super Admins can CRUD all projects
- Site Managers can only read assigned projects

### Other tables
- Follow similar patterns based on role and project assignment

---

## Support

If you encounter issues:
1. Check Supabase logs: **Logs → Postgres**
2. Verify auth status: **Authentication → Users**
3. Test RLS policies in SQL Editor

---

## Quick Reference

| Environment Variable | Description |
|---------------------|-------------|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Public anonymous key |
| `DEBUG_MODE` | Enable Supabase debug logging |
| `APP_ENV` | development / staging / production |
