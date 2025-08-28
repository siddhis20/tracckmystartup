# CA/CS Code Validation Test Guide

## Overview
This document describes how to test the new CA/CS code validation functionality in the startup dashboard profile section.

## What Was Implemented

### 1. Backend Validation
- Added `validateServiceCodes()` function in `profileService.ts`
- Validates CA/CS codes against the `service_providers` table
- Checks both main startup and subsidiary service codes
- Returns detailed error messages for invalid codes

### 2. Frontend Validation
- Real-time validation as users type CA/CS codes
- Visual feedback with colored borders and icons:
  - 🟢 Green border + checkmark for valid codes
  - 🔴 Red border + X for invalid codes
  - 🔵 Blue spinner for loading/validating
- Prevents form submission if any CA/CS codes are invalid

### 3. Enhanced User Experience
- Immediate feedback when codes are entered
- Clear error messages explaining what's wrong
- Form cannot be saved until all codes are valid

## How to Test

### Prerequisites
1. Ensure the `service_providers` table exists in your database
2. Make sure you have some sample CA/CS codes in the table

### Test Steps

#### 1. Test Valid CA/CS Codes
1. Go to Startup Dashboard → Profile Tab
2. Click "Edit Profile"
3. Enter a valid CA code (e.g., "CA001", "CA002")
4. Enter a valid CS code (e.g., "CS001", "CS002")
5. Verify:
   - Green borders appear around valid codes
   - Checkmark icons are shown
   - No validation errors appear

#### 2. Test Invalid CA/CS Codes
1. Enter an invalid CA code (e.g., "INVALID")
2. Enter an invalid CS code (e.g., "WRONG")
3. Verify:
   - Red borders appear around invalid codes
   - X icons are shown
   - Error messages appear below the fields
   - Form cannot be saved

#### 3. Test Subsidiary Validation
1. Set number of subsidiaries to 1 or more
2. Enter invalid CA/CS codes in subsidiary fields
3. Verify:
   - Subsidiary fields show validation errors
   - Error messages include subsidiary number
   - Form cannot be saved

#### 4. Test Form Submission Prevention
1. Enter invalid codes in any field
2. Try to click "Save Profile"
3. Verify:
   - Form does not submit
   - Validation errors are displayed
   - User is scrolled to top to see errors

#### 5. Test Real-time Validation
1. Type a valid code (e.g., "CA001")
2. Verify loading spinner appears
3. Verify green checkmark appears when validation succeeds
4. Change to invalid code
5. Verify red X appears immediately

## Sample Valid Codes
Based on the database setup, these codes should work:
- **CA Codes**: CA001, CA002, CA003, CA004, CA005
- **CS Codes**: CS001, CS002, CS003, CS004, CS005

## Sample Invalid Codes
These codes should trigger validation errors:
- **Invalid CA**: INVALID, WRONG, TEST123
- **Invalid CS**: BADCODE, ERROR, FAKE

## Expected Behavior

### Valid Codes
- ✅ Green border
- ✅ Checkmark icon
- ✅ No error messages
- ✅ Form can be saved

### Invalid Codes
- ❌ Red border
- ❌ X icon
- ❌ Error message below field
- ❌ Form cannot be saved

### Loading State
- 🔄 Blue spinner
- 🔄 "Validating..." state
- 🔄 Disabled input during validation

## Error Messages
- **Invalid CA Code**: "Invalid CA code: [CODE]. Please enter a valid CA service provider code."
- **Invalid CS Code**: "Invalid CS code: [CODE]. Please enter a valid CS service provider code."
- **Subsidiary Errors**: "Subsidiary [N]: Invalid [CA/CS] code "[CODE]". Please enter a valid service provider code."
- **Network Errors**: "Error validating [CA/CS] code. Please try again."

## Database Requirements
The validation depends on the `service_providers` table with this structure:
```sql
CREATE TABLE service_providers (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(10) NOT NULL CHECK (type IN ('ca', 'cs')),
    license_url TEXT,
    country VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## Troubleshooting

### Common Issues
1. **No validation happening**: Check if `service_providers` table exists and has data
2. **Validation errors not showing**: Check browser console for JavaScript errors
3. **Form still submitting**: Ensure validation is properly integrated in `handleSave`

### Debug Steps
1. Check browser console for validation logs
2. Verify database connection and table structure
3. Test with known valid/invalid codes
4. Check network requests for validation calls

## Summary
The new validation system provides:
- **Immediate feedback** for users entering CA/CS codes
- **Prevents invalid data** from being saved
- **Clear error messages** explaining what's wrong
- **Professional appearance** with visual indicators
- **Real-time validation** without page refreshes

This ensures data integrity and improves user experience in the startup profile management system.
