# Supabase Dashboard Storage Policies Implementation

## 🚨 **IMPORTANT: Don't Use Direct SQL for Storage Policies**

The error you encountered (`must be owner of table objects`) occurs because you're trying to modify the `storage.objects` table directly. In Supabase, storage policies should be created through the dashboard interface.

## ✅ **Correct Method: Use Supabase Dashboard**

### Step 1: Access Storage Policies in Dashboard
1. Go to your Supabase project dashboard
2. Navigate to **Storage** in the left sidebar
3. Click on **Policies** tab
4. You'll see all your buckets listed

### Step 2: Create Policies for Each Bucket

For each bucket, you need to create policies through the dashboard interface:

#### **1. startup-documents Bucket**
1. Click on **startup-documents** bucket
2. Click **New Policy**
3. Choose **Create a policy from scratch**
4. Configure as follows:

**Policy Name:** `startup-documents-upload`
**Allowed operation:** INSERT
**Policy definition:**
```sql
(auth.role() = 'authenticated' AND 
 (SELECT role FROM public.users WHERE id = auth.uid()) IN ('Startup', 'Admin'))
```

**Policy Name:** `startup-documents-view`
**Allowed operation:** SELECT
**Policy definition:**
```sql
auth.role() = 'authenticated'
```

**Policy Name:** `startup-documents-update`
**Allowed operation:** UPDATE
**Policy definition:**
```sql
(auth.role() = 'authenticated' AND 
 (SELECT role FROM public.users WHERE id = auth.uid()) IN ('Startup', 'Admin'))
```

**Policy Name:** `startup-documents-delete`
**Allowed operation:** DELETE
**Policy definition:**
```sql
(auth.role() = 'authenticated' AND 
 (SELECT role FROM public.users WHERE id = auth.uid()) IN ('Startup', 'Admin'))
```

#### **2. pitch-decks Bucket**
Same structure as startup-documents.

#### **3. pitch-videos Bucket**
Same structure as startup-documents.

#### **4. financial-documents Bucket**
**Policy Name:** `financial-documents-upload`
**Allowed operation:** INSERT
**Policy definition:**
```sql
(auth.role() = 'authenticated' AND 
 (SELECT role FROM public.users WHERE id = auth.uid()) IN ('Startup', 'CA', 'CS', 'Admin'))
```

**Policy Name:** `financial-documents-view`
**Allowed operation:** SELECT
**Policy definition:**
```sql
auth.role() = 'authenticated'
```

**Policy Name:** `financial-documents-update`
**Allowed operation:** UPDATE
**Policy definition:**
```sql
(auth.role() = 'authenticated' AND 
 (SELECT role FROM public.users WHERE id = auth.uid()) IN ('Startup', 'CA', 'CS', 'Admin'))
```

**Policy Name:** `financial-documents-delete`
**Allowed operation:** DELETE
**Policy definition:**
```sql
(auth.role() = 'authenticated' AND 
 (SELECT role FROM public.users WHERE id = auth.uid()) IN ('Startup', 'CA', 'CS', 'Admin'))
```

#### **5. employee-contracts Bucket**
**Policy Name:** `employee-contracts-upload`
**Allowed operation:** INSERT
**Policy definition:**
```sql
(auth.role() = 'authenticated' AND 
 (SELECT role FROM public.users WHERE id = auth.uid()) IN ('Startup', 'Admin'))
```

**Policy Name:** `employee-contracts-view`
**Allowed operation:** SELECT
**Policy definition:**
```sql
(auth.role() = 'authenticated' AND 
 (SELECT role FROM public.users WHERE id = auth.uid()) IN ('Startup', 'Admin', 'CA', 'CS'))
```

**Policy Name:** `employee-contracts-update`
**Allowed operation:** UPDATE
**Policy definition:**
```sql
(auth.role() = 'authenticated' AND 
 (SELECT role FROM public.users WHERE id = auth.uid()) IN ('Startup', 'Admin'))
```

**Policy Name:** `employee-contracts-delete`
**Allowed operation:** DELETE
**Policy definition:**
```sql
(auth.role() = 'authenticated' AND 
 (SELECT role FROM public.users WHERE id = auth.uid()) IN ('Startup', 'Admin'))
```

#### **6. verification-documents Bucket**
**Policy Name:** `verification-documents-upload`
**Allowed operation:** INSERT
**Policy definition:**
```sql
(auth.role() = 'authenticated' AND 
 (SELECT role FROM public.users WHERE id = auth.uid()) IN ('Startup', 'CA', 'CS', 'Admin'))
```

**Policy Name:** `verification-documents-view`
**Allowed operation:** SELECT
**Policy definition:**
```sql
auth.role() = 'authenticated'
```

**Policy Name:** `verification-documents-update`
**Allowed operation:** UPDATE
**Policy definition:**
```sql
(auth.role() = 'authenticated' AND 
 (SELECT role FROM public.users WHERE id = auth.uid()) IN ('CA', 'CS', 'Admin'))
```

**Policy Name:** `verification-documents-delete`
**Allowed operation:** DELETE
**Policy definition:**
```sql
(auth.role() = 'authenticated' AND 
 (SELECT role FROM public.users WHERE id = auth.uid()) IN ('CA', 'CS', 'Admin'))
```

## 🔄 **Alternative Method: Use SQL Functions Only**

If you prefer to use SQL, you can create helper functions and then use them in the dashboard policies:

### Step 1: Create Helper Functions (SQL Editor)
```sql
-- Function to get current user's role
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS TEXT AS $$
BEGIN
  RETURN (
    SELECT role::TEXT 
    FROM public.users 
    WHERE id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN get_user_role() = 'Admin';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is startup
CREATE OR REPLACE FUNCTION is_startup()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN get_user_role() = 'Startup';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is CA or CS
CREATE OR REPLACE FUNCTION is_ca_or_cs()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN get_user_role() IN ('CA', 'CS');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### Step 2: Use Functions in Dashboard Policies
Then in the dashboard, you can use these functions:

**Example for startup-documents-upload:**
```sql
is_startup() OR is_admin()
```

## 📋 **Quick Setup Template**

For each bucket, create these 4 policies:

1. **Upload Policy:** `is_startup() OR is_admin()` (adjust roles as needed)
2. **View Policy:** `auth.role() = 'authenticated'` (or restrict as needed)
3. **Update Policy:** `is_startup() OR is_admin()` (adjust roles as needed)
4. **Delete Policy:** `is_startup() OR is_admin()` (adjust roles as needed)

## ✅ **Verification**

After creating all policies:
1. Go to **Storage > Policies**
2. You should see policies listed for each bucket
3. Test file uploads/downloads with different user roles

## 🚨 **Important Notes**

- **Don't try to modify `storage.objects` table directly**
- **Use the Supabase dashboard interface for storage policies**
- **The helper functions approach is more maintainable**
- **Test thoroughly with different user roles**

This approach will work without the permission errors you encountered.
