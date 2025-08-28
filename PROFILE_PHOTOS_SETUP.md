# 🖼️ Profile Photos Storage Setup Guide

## 🚨 **Current Issue**
The `profile-photos` storage bucket doesn't exist in Supabase, causing profile photo uploads to fail.

## ✅ **Temporary Solution (Working Now)**
Profile photos are currently being uploaded to the `verification-documents` bucket. This works but isn't ideal for organization.

## 🎯 **Permanent Solution (Recommended)**

### **Step 1: Create Profile Photos Bucket in Supabase Dashboard**

1. Go to your Supabase Dashboard
2. Navigate to **Storage** → **Buckets**
3. Click **Create a new bucket**
4. Fill in the details:
   - **Name**: `profile-photos`
   - **Public bucket**: ✅ Checked
   - **File size limit**: `5MB`
   - **Allowed MIME types**: `image/jpeg, image/jpg, image/png, image/gif, image/webp`

### **Step 2: Set Up Storage Policies**

Run this SQL in your Supabase SQL Editor:

```sql
-- Enable RLS on storage.objects if not already enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Users can upload their own profile photos
CREATE POLICY "Users can upload their own profile photos" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'profile-photos' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Anyone can view profile photos (public)
CREATE POLICY "Anyone can view profile photos" ON storage.objects
FOR SELECT USING (bucket_id = 'profile-photos');

-- Users can update their own profile photos
CREATE POLICY "Users can update their own profile photos" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'profile-photos' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can delete their own profile photos
CREATE POLICY "Users can delete their own profile photos" ON storage.objects
FOR DELETE USING (
  bucket_id = 'profile-photos' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);
```

### **Step 3: Update Code to Use New Bucket**

After creating the bucket, update these files:

#### **ProfileService.ts**
```typescript
// Change this line:
const result = await storageService.uploadFile(file, 'verification-documents', fileName);

// To this:
const result = await storageService.uploadFile(file, 'profile-photos', fileName);
```

#### **Delete method**
```typescript
// Change this line:
const result = await storageService.deleteFile('verification-documents', filePath);

// To this:
const result = await storageService.deleteFile('profile-photos', filePath);
```

## 🔄 **Current Status**
- ✅ Profile photo uploads work (using verification-documents bucket)
- ✅ Real-time database updates implemented
- ✅ Automatic old photo cleanup implemented
- ⏳ Dedicated profile-photos bucket needs to be created

## 📁 **File Structure**
```
verification-documents/
├── user-id-1/
│   ├── profile-photo-1234567890.jpg
│   ├── government-id_1234567890.pdf
│   └── ca-license_1234567890.pdf
└── user-id-2/
    ├── profile-photo-1234567891.png
    └── government-id_1234567891.pdf
```

## 🎉 **Benefits of Dedicated Bucket**
1. **Better Organization**: Separate profile photos from verification documents
2. **Different Policies**: Can have different size limits and MIME types
3. **Easier Management**: Cleaner storage structure
4. **Better Performance**: Smaller bucket for faster queries

## 🚀 **Next Steps**
1. Create the `profile-photos` bucket in Supabase Dashboard
2. Run the SQL policies
3. Update the code to use the new bucket
4. Test profile photo uploads
5. Verify real-time updates work correctly
