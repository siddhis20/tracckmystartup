# Storage Policies Setup Guide

## After Running the SQL Fix

Once you've run the corrected SQL script, you need to set up storage policies through the Supabase Dashboard since we can't modify the `storage.objects` table directly via SQL.

## Step-by-Step Instructions

### 1. Go to Supabase Dashboard
- Open your Supabase project dashboard
- Navigate to **Storage** in the left sidebar

### 2. Create Storage Policies
- Click on **Policies** tab in the Storage section
- Click **New Policy** for the `verification-documents` bucket

### 3. Create These Policies

#### Policy 1: Allow Uploads
- **Policy Name**: `Allow authenticated users to upload verification documents`
- **Target Roles**: `authenticated`
- **Policy Definition**:
```sql
(bucket_id = 'verification-documents' AND auth.role() = 'authenticated')
```
- **Operations**: `INSERT`

#### Policy 2: Allow Public Read Access
- **Policy Name**: `Allow public access to verification documents`
- **Target Roles**: `public`
- **Policy Definition**:
```sql
(bucket_id = 'verification-documents')
```
- **Operations**: `SELECT`

#### Policy 3: Allow Updates
- **Policy Name**: `Allow authenticated users to update verification documents`
- **Target Roles**: `authenticated`
- **Policy Definition**:
```sql
(bucket_id = 'verification-documents' AND auth.role() = 'authenticated')
```
- **Operations**: `UPDATE`

#### Policy 4: Allow Deletes
- **Policy Name**: `Allow authenticated users to delete verification documents`
- **Target Roles**: `authenticated`
- **Policy Definition**:
```sql
(bucket_id = 'verification-documents' AND auth.role() = 'authenticated')
```
- **Operations**: `DELETE`

## Alternative: Use Supabase CLI

If you have the Supabase CLI installed, you can also create these policies using:

```bash
supabase storage policy create verification-documents "Allow authenticated users to upload verification documents" --operation INSERT --target authenticated
supabase storage policy create verification-documents "Allow public access to verification documents" --operation SELECT --target public
supabase storage policy create verification-documents "Allow authenticated users to update verification documents" --operation UPDATE --target authenticated
supabase storage policy create verification-documents "Allow authenticated users to delete verification documents" --operation DELETE --target authenticated
```

## Test the Setup

After creating the policies, test the file upload functionality in your application. The errors should be resolved and files should upload successfully.

## Troubleshooting

If you still get permission errors:
1. Make sure the bucket is set to **Public**
2. Verify all four policies are created correctly
3. Check that the user is authenticated when trying to upload
4. Ensure the bucket name matches exactly: `verification-documents`

