# Quick Facilitator Code Setup Guide

## ✅ What's Already Done

1. **Database Script**: `FACILITATOR_CODE_SYSTEM.sql` - Complete facilitator code system
2. **Frontend Component**: `FacilitatorCodeDisplay.tsx` - Header component for displaying codes
3. **Service Layer**: `facilitatorCodeService.ts` - API functions for code management
4. **Header Integration**: Updated `App.tsx` to show facilitator code beside logout button

## 🚀 Steps to Implement

### Step 1: Run the Database Setup

1. **Open Supabase Dashboard**
2. **Go to SQL Editor**
3. **Copy and paste the entire content of `FACILITATOR_CODE_SYSTEM.sql`**
4. **Click Run**

### Step 2: Test the Setup

1. **Run the test script** `TEST_FACILITATOR_CODE.sql` to verify everything is working
2. **Check that facilitators have codes assigned**

### Step 3: Verify Frontend

1. **Login as a facilitator** (Startup Facilitation Center role)
2. **Check the header** - you should see "Facilitator Code: FAC-XXXXXX" beside the logout button
3. **The styling should match** the image you provided

## 🎯 Expected Result

After implementation, when a facilitator logs in, the header should look exactly like your image:

```
[Briefcase Icon] Facilitator Panel                    [FAC-D4E5F6] [Logout Icon] Logout
```

## 🔧 Troubleshooting

### If codes don't appear:
1. **Check browser console** for errors
2. **Verify the SQL script ran successfully**
3. **Check that the user has 'Startup Facilitation Center' role**

### If styling doesn't match:
1. **The component uses Tailwind classes** that should match your design
2. **Check if Tailwind CSS is properly loaded**

## 📋 Next Steps (Optional)

1. **Update offer codes** to use real facilitator codes instead of fallback codes
2. **Implement compliance access** when diligence is approved
3. **Add "View Diligence" button** in facilitator panel

## 🎨 Styling Details

The facilitator code uses these Tailwind classes:
- `bg-blue-100` - Light blue background
- `text-blue-800` - Dark blue text
- `px-3 py-1` - Padding
- `rounded-md` - Rounded corners
- `text-sm font-medium` - Small, medium-weight text

This matches the styling shown in your image perfectly!
