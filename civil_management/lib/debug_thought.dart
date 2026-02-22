import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart'; // Just for Supabase init if needed, though pure dart is better but we rely on flutter env.

// NOTE: This is intended to be run by the user or via a quick integration in main.dart
// But since we can't easily run a standalone dart script with flutter dependencies without setup,
// I'll create a simple main-like entry point that can be swapped or triggered.

// Actually, I will make this a small test utility that the user can run using `flutter test`?
// No, getting credentials is hard.

// I'll rely on the fact that I can't easily run it.
// I will instead provide a SQL script that the user can run in Supabase SQL Editor which is infallible.

/*
SQL SCRIPT CONTENT for User:

SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name IN ('material_logs', 'stock_items')
ORDER BY table_name, column_name;
*/

// BUT I want to potentially fix it in code if I can.
// I can force a query to fail with specific error?

// Let's assume the user IS applying the migration.
// If it fails, maybe there's a type error.
// Code: `double.parse(entry.billAmountController.text)`
// If text is "100", double is 100.0.
// `billAmount` in DB is DECIMAL. JSON encoding handles this.

// Wait. `StockRepository.logMaterialInward`:
/*
    await _client.from('material_logs').insert({
      ...
      'bill_amount': billAmount,
      ...
    });
*/

// If `billAmount` is null? (required in dart).
// If `paymentType` is null? (required in dart).
// If `stockItemGrade` is null (allowed).

// I suspect the error might be `supplier_id`.
// If I pass a STRING (Vendor Name) that is NOT a UUID, and my `_getOrCreateSupplier` fails to create it?
// `_getOrCreateSupplier` in `StockRepository`:
/*
    try {
      final newSupplier = await _client.from('suppliers').insert({...}).select('id').single();
      return newSupplier['id'];
    } catch(e) {
      return null;
    }
*/
// If it returns null, we send `null` to `supplier_id`.
// But if `supplierId` param passed to `logMaterialInward` was a name, and we failed to resolve it, we send null. This is OK.

// BUT, what if `_getOrCreateSupplier` logic is flawed?
// `await _client.from('suppliers').select('id').eq('name', nameOrId).maybeSingle();`
// If RLS prevents reading suppliers?
// Policy: "Site managers can view suppliers" WHERE `public.get_my_role() = 'site_manager' AND is_active = true`.
// If the user has role 'site_manager', they can see.
// If creating new supplier:
// Policy: "Site managers can add suppliers" WITH CHECK `public.get_my_role() = 'site_manager'`.
// If `get_my_role()` fails or user doesn't have role yet?
// Wait, user is logged in.

// Let's look at the `400 Bad Request` again.
// It happens on `material_logs` insert.
// OR it happens on `stock_items` insert (inside `_getOrCreateStockItem`).
// `get_or_create_stock_item` RPC.
// In `StockRepository`:
/*
    try {
      final response = await _client.rpc('get_or_create_stock_item', ...);
      return response as String;
    } catch (e) {
       // Fallback
       ...
       final newItem = await _client.from('stock_items').insert({...});
    }
*/
// The RPC `get_or_create_stock_item` expects `p_grade`.
// My migration `030` defines it: `p_grade TEXT`.
// My migration `030` defines table `stock_items` WITHOUT `grade`.
// **Wait!** In `030_material_operations.sql`:
/*
  CREATE OR REPLACE FUNCTION public.get_or_create_stock_item(
    p_project_id UUID,
    p_name TEXT,
    p_grade TEXT,
    p_unit TEXT
  ) RETURNS UUID AS $$
  ...
    INSERT INTO public.stock_items (..., grade, ...)
  ...
*/
// Function tries to insert `grade`.
// Table `stock_items` was NOT altered in `030` to add `grade`!
// (I checked `030` content earlier: it calls `ALTER TABLE public.stock_items ALTER COLUMN project_id SET NOT NULL;` but does NOT add `grade`).
// `011_material_logs.sql` created `stock_items` without `grade`.
// So `stock_items` DOES NOT HAVE `grade` until Migration 031 is applied.

// If the user tries `logMaterialInward`:
// 1. Calls `_getOrCreateStockItem`.
// 2. Calls RPC `get_or_create_stock_item`.
// 3. RPC tries `INSERT INTO public.stock_items (..., grade, ...)`.
// 4. FAILS because `grade` column does not exist on `stock_items`.
// 5. Exception caught in Dart?
// 6. `catch (e)` block -> Fallback client-side logic.
// 7. `await _client.from('stock_items').insert({ ... 'grade': grade ... })`.
// 8. FAILS because of missing column `grade`.
// 9. Returns 400 Bad Request.

// So verifying that `stock_items` has `grade` is key.
// And `material_logs` having `grade`, `payment_type`, `bill_amount`.

// The user is seeing 400. This confirms missing columns.
// Why did the user say it failed?
// 1. Didn't run migration.
// 2. Ran it, but maybe Supabase cached the schema?
// 3. Or maybe the `031` migration was applied BUT the trigger/function inside `030` is "stale" or referencing old cache? No, Postgres functions plan on execution.

// If I really want to be sure, I should tell the user to run the migration again, explicitly.
// Or I can update `StockRepository` to handle the failure gracefully? No, we need the schema.

// I will try to remove `grade` from the insert if it fails? No.

// I suspect the user just hasn't applied the migration successfully.
// I will notify the user with a very clear instruction and a "check" step.
// I will also modify `StockRepository` to Log the error details better if possible.
// `PostgrestException` has `message`, `details`, `hint`, `code`.
// The flutter error log shows just `400`.
// I will modify `StockRepository` to catch and rethrow with more info.
