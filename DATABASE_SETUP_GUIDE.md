# Database Setup Guide for Dynamic Compliance System

## 🚨 Current Issue
You're getting a 400 error because the compliance database tables haven't been created yet. This guide will help you set them up correctly.

## 📋 Step-by-Step Setup Instructions

### Step 1: Access Supabase Dashboard
1. Go to your Supabase project dashboard
2. Navigate to the **SQL Editor** in the left sidebar

### Step 2: Run the Database Setup Script
1. Open the `COMPLIANCE_DATABASE_SETUP.sql` file
2. Copy the entire content
3. Paste it into the SQL Editor in Supabase
4. Click **Run** to execute the script

### Step 3: Verify Tables Were Created
1. Go to **Table Editor** in the left sidebar
2. You should see these new tables:
   - `compliance_checks`
   - `compliance_uploads`

### Step 4: Check Storage Bucket
1. Go to **Storage** in the left sidebar
2. You should see a bucket called `compliance-documents`

### Step 5: Verify RLS Policies
1. Go to **Authentication** → **Policies**
2. Check that RLS policies were created for both tables

## 🔍 Troubleshooting

### If Tables Don't Appear:
1. **Check for SQL errors**: Look at the SQL Editor output for any error messages
2. **Common issues**:
   - Syntax errors in the SQL script
   - Permission issues
   - Existing table conflicts

### If You Get Permission Errors:
1. **Check RLS policies**: Make sure they were created correctly
2. **Verify authentication**: Ensure you're logged in
3. **Check API keys**: Verify your Supabase keys are correct

### If Storage Bucket Doesn't Exist:
1. **Manual creation**: Go to Storage and create a bucket called `compliance-documents`
2. **Set it as public**: Make sure the bucket is set to public access

## 🧪 Testing the Setup

### Option 1: Use the Test Script
1. Open `test-database-setup.js`
2. Replace `your-anon-key-here` with your actual Supabase anon key
3. Run the script in your browser console
4. Check the output for any issues

### Option 2: Manual Testing
1. Go to **Table Editor**
2. Click on `compliance_checks` table
3. Try to insert a test record
4. If successful, the table is working

## 📝 Expected Database Schema

### compliance_checks Table
```sql
- id (UUID, Primary Key)
- startup_id (Integer, Foreign Key)
- task_id (Text)
- entity_identifier (Text)
- entity_display_name (Text)
- year (Integer)
- task_name (Text)
- ca_required (Boolean)
- cs_required (Boolean)
- ca_status (Text: 'Pending', 'Verified', 'Rejected', 'Not Required')
- cs_status (Text: 'Pending', 'Verified', 'Rejected', 'Not Required')
- ca_updated_by (Text)
- cs_updated_by (Text)
- ca_updated_at (Timestamp)
- cs_updated_at (Timestamp)
- created_at (Timestamp)
- updated_at (Timestamp)
```

### compliance_uploads Table
```sql
- id (UUID, Primary Key)
- startup_id (Integer, Foreign Key)
- task_id (Text)
- file_name (Text)
- file_url (Text)
- uploaded_by (Text)
- file_size (Integer)
- file_type (Text)
- uploaded_at (Timestamp)
- created_at (Timestamp)
```

## 🔄 After Setup

### 1. Refresh Your Application
- The compliance tab should now work without 400 errors
- You should see the "No compliance tasks generated" message instead of errors

### 2. Test Profile Updates
- Go to Profile tab
- Update country, company type, or registration date
- Check if compliance tasks are generated

### 3. Test Upload Functionality
- Try uploading a document
- Check if it appears in the compliance tab

## 🆘 Still Having Issues?

### Check These Common Problems:

1. **SQL Script Didn't Run Completely**
   - Look for error messages in SQL Editor
   - Run the script in smaller chunks if needed

2. **RLS Policies Blocking Access**
   - Check if you're authenticated
   - Verify your user role has the right permissions

3. **Storage Bucket Issues**
   - Make sure the bucket exists and is public
   - Check storage policies

4. **API Key Issues**
   - Verify your Supabase URL and anon key
   - Check if keys are correct in your environment

### Get Help:
1. Check the Supabase logs for detailed error messages
2. Look at the browser console for specific error details
3. Verify each step in this guide was completed successfully

## ✅ Success Indicators

When everything is working correctly, you should see:
- ✅ No 400 errors in the browser console
- ✅ "No compliance tasks generated" message in Compliance tab
- ✅ Profile changes trigger compliance task generation
- ✅ Upload buttons are active and functional
- ✅ CA/CS users can update verification status

## 🎯 Next Steps

Once the database is set up:
1. Test the complete workflow
2. Add some test data
3. Verify real-time updates work
4. Test with different user roles

The system should now be fully functional with dynamic compliance task generation based on your profile settings!


