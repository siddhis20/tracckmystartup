# Document Upload Fixes for Investment Advisor Registration

## Issues Identified and Fixed

### 1. Missing Logo Upload Field
**Problem**: Investment Advisors were not seeing the "Upload Logo" field in the registration form.

**Fix Applied**:
- Added logo upload field specifically for Investment Advisor role
- Added validation to require logo upload for Investment Advisors
- Updated file handling to support logo uploads

### 2. Incorrect Document Label
**Problem**: The second document field was labeled "Document" instead of "Proof of Firm Registration" for Investment Advisors.

**Fix Applied**:
- Updated `getRoleSpecificDocumentType()` function to return "Proof of Firm Registration" for Investment Advisor role
- This ensures the correct label is displayed in the UI

## Files Modified

### 1. `components/DocumentUploadStep.tsx`
**Changes Made**:
- Added `logo` field to `uploadedFiles` state
- Updated `getRoleSpecificDocumentType()` to return "Proof of Firm Registration" for Investment Advisor
- Added logo upload field in the UI (only visible for Investment Advisor role)
- Added validation to require logo upload for Investment Advisors
- Added file type restrictions for logo uploads (JPG, PNG, SVG)

**Key Code Changes**:
```typescript
// Added logo to state
const [uploadedFiles, setUploadedFiles] = useState<{
  govId: File | null;
  roleSpecific: File | null;
  logo?: File | null; // Added this
}>({
  govId: null,
  roleSpecific: null,
  logo: null // Added this
});

// Updated document type function
case 'Investment Advisor': return 'Proof of Firm Registration';

// Added logo upload field
{userData.role === 'Investment Advisor' && (
  <div>
    <label className="block text-sm font-medium text-slate-700 mb-2">
      Upload Logo
    </label>
    <Input
      type="file"
      accept=".jpg,.jpeg,.png,.svg"
      onChange={(e) => handleFileChange(e, 'logo')}
      required
    />
    {/* ... */}
  </div>
)}
```

### 2. `components/TwoStepRegistration.tsx`
**Changes Made**:
- Added logo upload handling in the document upload process
- Updated user profile creation to include logo URL
- Added logo URL to the AuthUser object creation

**Key Code Changes**:
```typescript
// Added logo upload handling
if (documents.logo && userData.role === 'Investment Advisor') {
  const result = await storageService.uploadVerificationDocument(
    documents.logo, 
    userData.email, 
    'company-logo'
  );
  if (result.success && result.url) {
    logoUrl = result.url;
  }
}

// Added logo URL to user profile
if (userData.role === 'Investment Advisor' && logoUrl) {
  updateData.logo_url = logoUrl;
}
```

### 3. `lib/auth.ts`
**Changes Made**:
- Added Investment Advisor specific fields to the AuthUser interface
- Added `logo_url`, `proof_of_business_url`, `financial_advisor_license_url`, and `investment_advisor_code` fields

**Key Code Changes**:
```typescript
export interface AuthUser {
  // ... existing fields ...
  // Investment Advisor specific fields
  investment_advisor_code?: string
  logo_url?: string
  proof_of_business_url?: string
  financial_advisor_license_url?: string
}
```

## Registration Flow for Investment Advisors

### Document Requirements
1. **Government ID** (required for all users)
2. **Proof of Firm Registration** (required for Investment Advisors)
3. **Company Logo** (required for Investment Advisors)
4. **Investment Advisor Code** (optional field for linking to existing advisor)

### File Type Restrictions
- **Government ID**: PDF, JPG, JPEG, PNG
- **Proof of Firm Registration**: PDF, JPG, JPEG, PNG
- **Company Logo**: JPG, JPEG, PNG, SVG

### Validation Rules
- All three documents are required for Investment Advisor registration
- Logo must be in image format (JPG, PNG, or SVG)
- Investment Advisor code is optional but will be validated if provided

## UI Changes

### Document Upload Section
- **Government ID**: "Government ID (Passport, Driver's License, etc.)"
- **Proof of Firm Registration**: "Proof of Firm Registration" (instead of generic "Document")
- **Company Logo**: "Upload Logo" (only visible for Investment Advisor role)

### Investment Advisor Code Section
- Optional field for entering an existing Investment Advisor code
- Only visible for Investor and Startup roles
- Allows users to associate themselves with an existing Investment Advisor

## Testing Recommendations

### 1. Investment Advisor Registration
1. Register a new user with "Investment Advisor" role
2. Verify all three document fields are visible and required
3. Test with different file types for logo upload
4. Verify the logo is properly uploaded and stored
5. Check that the Investment Advisor code is auto-generated

### 2. Other User Roles
1. Register users with other roles (Investor, Startup, etc.)
2. Verify that logo upload field is not visible for non-Investment Advisor roles
3. Verify that Investment Advisor code field is visible for Investor and Startup roles
4. Test that document labels are correct for each role

### 3. File Upload Validation
1. Test with valid file types for each document
2. Test with invalid file types to ensure proper error handling
3. Verify file size limits are respected
4. Test with missing required documents

## Database Integration

The logo upload integrates with the existing storage system:
- Logo files are uploaded to the same storage bucket as other verification documents
- Logo URL is stored in the `users.logo_url` column
- Logo is displayed in the Investment Advisor dashboard header
- Logo is used in the "supported by Track My Startup" branding

## Next Steps

1. **Test the updated registration flow** with Investment Advisor role
2. **Verify logo display** in the Investment Advisor dashboard
3. **Test file upload validation** with various file types
4. **Ensure proper error handling** for missing or invalid files
5. **Verify database storage** of logo URLs and document references

The fixes ensure that Investment Advisors have a complete registration experience with proper document requirements and logo upload functionality.

