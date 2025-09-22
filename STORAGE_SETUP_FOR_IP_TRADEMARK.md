# Storage Setup for IP/Trademark Documents

## What You Need to Do

The IP/trademark feature requires a Supabase storage bucket called `compliance-documents` to store uploaded files (PDFs, images, documents, etc.). Here are the exact steps:

## Option 1: Using Supabase Dashboard (Recommended)

### Step 1: Access Supabase Dashboard
1. Go to [supabase.com](https://supabase.com) and log in
2. Select your project
3. Click on **Storage** in the left sidebar

### Step 2: Create the Storage Bucket
1. Click **"Create a new bucket"**
2. Fill in the details:
   - **Name**: `compliance-documents`
   - **Public bucket**: ✅ **Yes** (check this box)
   - **File size limit**: `50` MB
   - **Allowed MIME types**: Leave empty (allows all types) OR add:
     ```
     application/pdf,image/jpeg,image/png,image/gif,application/msword,application/vnd.openxmlformats-officedocument.wordprocessingml.document,application/vnd.ms-excel,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
     ```
3. Click **"Create bucket"**

### Step 3: Set Storage Policies (Optional but Recommended)
1. Go to **Storage** → **Policies**
2. Find the `compliance-documents` bucket
3. Click **"New Policy"**
4. Create a policy with these settings:
   - **Policy name**: `Public Access`
   - **Allowed operation**: `All`
   - **Target roles**: `public`
   - **Policy definition**:
     ```sql
     bucket_id = 'compliance-documents'
     ```
5. Click **"Save policy"**

## Option 2: Using SQL Script (Advanced)

If you prefer to use SQL, run this script in your Supabase SQL Editor:

```sql
-- Create storage bucket for compliance documents
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'compliance-documents',
    'compliance-documents',
    true,
    52428800, -- 50MB limit
    ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/gif', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet']
)
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Create simple public access policy
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
CREATE POLICY "Public Access" ON storage.objects
    FOR ALL USING (bucket_id = 'compliance-documents');
```

## Option 3: Use Existing Script

I noticed you already have storage setup scripts. You can use the existing `QUICK_STORAGE_FIX.sql` file:

1. Open your Supabase project
2. Go to **SQL Editor**
3. Copy and paste the contents of `QUICK_STORAGE_FIX.sql`
4. Click **"Run"**

## Verify the Setup

After creating the bucket, verify it works:

1. Go to **Storage** → **Buckets**
2. You should see `compliance-documents` in the list
3. Click on it to see it's empty (which is normal)
4. The bucket should show as **Public**

## What This Enables

Once the storage bucket is set up, the IP/trademark feature will be able to:

- ✅ Upload documents (PDFs, images, Word docs, etc.)
- ✅ Store files securely in Supabase storage
- ✅ Generate public URLs for document access
- ✅ Download and view uploaded documents
- ✅ Delete documents when needed

## File Organization

The system will automatically organize files like this:
```
compliance-documents/
└── ip-trademark-documents/
    ├── record-id-1_timestamp.pdf
    ├── record-id-2_timestamp.jpg
    └── record-id-3_timestamp.docx
```

## Troubleshooting

### If you get "Bucket not found" errors:
1. Double-check the bucket name is exactly `compliance-documents`
2. Ensure the bucket is marked as **Public**
3. Verify the storage policies are set correctly

### If file uploads fail:
1. Check the file size (should be under 50MB)
2. Verify the file type is allowed
3. Make sure you have proper permissions

### If you can't see uploaded files:
1. Check that the bucket is public
2. Verify the storage policies allow public access
3. Check the browser console for any error messages

## Security Notes

- The bucket is set to **public** for simplicity, but you can make it private and use more complex policies if needed
- Files are organized by record ID and timestamp to prevent conflicts
- The system automatically generates unique filenames
- All uploads are logged with user information

## Next Steps

After setting up the storage bucket:

1. ✅ Run the database setup: `CREATE_IP_TRADEMARK_TABLE.sql`
2. ✅ Set up the storage bucket (this guide)
3. ✅ Test the IP/trademark feature in the compliance tab
4. ✅ Upload a test document to verify everything works

That's it! Once the storage bucket is configured, your IP/trademark feature will be fully functional.

