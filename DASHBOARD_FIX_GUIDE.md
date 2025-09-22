# Dashboard Fix Guide - Alternative Method

Since you're getting permission errors with SQL, let's fix this through the Supabase Dashboard UI.

## Step 1: Create Storage Bucket

1. Go to **Storage** → **Buckets** in your Supabase Dashboard
2. Click **Create a new bucket**
3. Fill in:
   - **Name**: `verification-documents`
   - **Public bucket**: ✅ Yes
   - **File size limit**: 50 MB
   - **Allowed MIME types**: `application/pdf`, `image/jpeg`, `image/png`, `image/gif`

## Step 2: Fix RLS Policies

1. Go to **Authentication** → **Policies** in your Supabase Dashboard
2. Find the **users** table
3. **Delete all existing policies** that might be causing infinite recursion
4. **Create new policies**:

### Policy 1: Insert
- **Name**: `Users can insert their own profile`
- **Operation**: `INSERT`
- **Target roles**: `authenticated`
- **Policy definition**: `true`

### Policy 2: Select
- **Name**: `Users can view their own profile`
- **Operation**: `SELECT`
- **Target roles**: `authenticated`
- **Policy definition**: `true`

### Policy 3: Update
- **Name**: `Users can update their own profile`
- **Operation**: `UPDATE`
- **Target roles**: `authenticated`
- **Policy definition**: `true`

## Step 3: Create Storage Policies

1. Go to **Storage** → **Policies** in your Supabase Dashboard
2. Click **New Policy** for the `verification-documents` bucket
3. Create these policies:

### Policy 1: Upload
- **Name**: `Allow authenticated users to upload verification documents`
- **Operation**: `INSERT`
- **Target roles**: `authenticated`
- **Policy definition**: `bucket_id = 'verification-documents' AND auth.role() = 'authenticated'`

### Policy 2: Read
- **Name**: `Allow public access to verification documents`
- **Operation**: `SELECT`
- **Target roles**: `public`
- **Policy definition**: `bucket_id = 'verification-documents'`

### Policy 3: Update
- **Name**: `Allow authenticated users to update verification documents`
- **Operation**: `UPDATE`
- **Target roles**: `authenticated`
- **Policy definition**: `bucket_id = 'verification-documents' AND auth.role() = 'authenticated'`

### Policy 4: Delete
- **Name**: `Allow authenticated users to delete verification documents`
- **Operation**: `DELETE`
- **Target roles**: `authenticated`
- **Policy definition**: `bucket_id = 'verification-documents' AND auth.role() = 'authenticated'`

## Step 4: Enable RLS on Tables

1. Go to **Table Editor** in your Supabase Dashboard
2. For each table (users, startups, founders, etc.):
   - Click on the table
   - Go to **Settings** tab
   - Enable **Row Level Security (RLS)**

## Step 5: Test the Fix

After completing these steps:
1. Try uploading a file in your application
2. Check if the 500 errors are resolved
3. Verify that the infinite recursion error is gone

## Why This Approach Works

The Dashboard UI bypasses the SQL permission issues and directly configures the database settings through Supabase's management interface. This should resolve both the storage bucket issue and the RLS policy problems.

