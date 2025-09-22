# Document Verification Integration Example

## 🎯 **Quick Integration Guide**

This shows how to integrate document verification status into existing components.

## 📋 **Step 1: Add Import to ComplianceTab.tsx**

```typescript
// Add this import at the top of ComplianceTab.tsx
import DocumentVerificationBadge from '../DocumentVerificationStatus';
```

## 📋 **Step 2: Update Document Display**

Find the document display section in ComplianceTab.tsx and add verification status:

```typescript
// Before (existing code):
<div className="flex items-center justify-between">
    <div className="flex items-center">
        <FileText className="w-4 h-4 text-gray-400 mr-2" />
        <span className="text-sm text-gray-900">{upload.fileName}</span>
    </div>
    <div className="flex items-center gap-2">
        <Button variant="secondary" size="sm" onClick={() => window.open(upload.fileUrl, '_blank')}>
            <Eye className="w-4 h-4" />
        </Button>
        <Button variant="secondary" size="sm" onClick={() => handleDeleteUpload(upload.id)}>
            <Trash2 className="w-4 h-4" />
        </Button>
    </div>
</div>

// After (with verification status):
<div className="flex items-center justify-between">
    <div className="flex items-center">
        <FileText className="w-4 h-4 text-gray-400 mr-2" />
        <span className="text-sm text-gray-900">{upload.fileName}</span>
        <DocumentVerificationBadge documentId={upload.id} className="ml-2" />
    </div>
    <div className="flex items-center gap-2">
        <Button variant="secondary" size="sm" onClick={() => window.open(upload.fileUrl, '_blank')}>
            <Eye className="w-4 h-4" />
        </Button>
        <Button variant="secondary" size="sm" onClick={() => handleDeleteUpload(upload.id)}>
            <Trash2 className="w-4 h-4" />
        </Button>
    </div>
</div>
```

## 📋 **Step 3: Add to IP/Trademark Section**

In `IPTrademarkSection.tsx`, add the same import and update document display:

```typescript
// Add import
import DocumentVerificationBadge from '../DocumentVerificationStatus';

// Update document display
<div className="flex items-center justify-between">
    <div className="flex items-center">
        <FileText className="w-4 h-4 text-gray-400 mr-2" />
        <span className="text-sm text-gray-900">{document.fileName}</span>
        <DocumentVerificationBadge documentId={document.id} className="ml-2" />
    </div>
    <div className="flex items-center gap-2">
        <Button variant="secondary" size="sm" onClick={() => window.open(document.fileUrl, '_blank')}>
            <Eye className="w-4 h-4" />
        </Button>
        <Button variant="secondary" size="sm" onClick={() => handleDeleteDocument(document.id)}>
            <Trash2 className="w-4 h-4" />
        </Button>
    </div>
</div>
```

## 📋 **Step 4: Add to Admin Panel**

In `AdminView.tsx`, add a new tab for document verification:

```typescript
// Add import
import DocumentVerificationManager from '../DocumentVerificationManager';

// Add to AdminTab type
type AdminTab = 'dashboard' | 'users' | 'startups' | 'verification' | 'investment' | 'validation' | 'document-verification';

// Add to tab navigation
<button
    onClick={() => setActiveTab('document-verification')}
    className={`px-4 py-2 rounded-lg font-medium transition-colors ${
        activeTab === 'document-verification'
            ? 'bg-blue-100 text-blue-700'
            : 'text-gray-600 hover:text-gray-900'
    }`}
>
    Document Verification
</button>

// Add to tab content
{activeTab === 'document-verification' && (
    <DocumentVerificationManager 
        userRole={userRole} 
        userEmail={userEmail}
        onVerificationUpdate={() => {
            // Refresh data if needed
        }}
    />
)}
```

## 📋 **Step 5: Test the Integration**

### **Test Steps:**
1. **Upload a document** in Compliance tab
2. **Check verification status** shows as "Pending"
3. **Go to Admin panel** → Document Verification tab
4. **Verify the document** as Admin/CA/CS
5. **Return to Compliance tab** and see status updated to "Verified"

### **Expected Results:**
- ✅ **Pending documents** show yellow "Pending" badge
- ✅ **Verified documents** show green "Verified" badge
- ✅ **Rejected documents** show red "Rejected" badge
- ✅ **Status updates** in real-time across all tabs
- ✅ **Role-based access** to verification features

## 🎯 **Quick Test Script**

```sql
-- Test document verification system
-- Run this in Supabase SQL Editor after setup

-- 1. Check if tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE '%document_verification%';

-- 2. Check verification rules
SELECT * FROM public.document_verification_rules;

-- 3. Check if any documents exist
SELECT COUNT(*) as total_documents FROM public.compliance_uploads;

-- 4. Create a test verification (replace with actual document ID)
-- INSERT INTO public.document_verifications (
--     document_id,
--     document_type,
--     verification_status,
--     verified_by,
--     verified_at,
--     verification_notes
-- ) VALUES (
--     'your-document-id-here',
--     'compliance_document',
--     'verified',
--     'admin@example.com',
--     NOW(),
--     'Test verification'
-- );
```

## 🚀 **Benefits After Integration**

### **For Users:**
- ✅ **Clear visibility** of document verification status
- ✅ **Transparent process** with status updates
- ✅ **Confidence** in document authenticity

### **For Admins/CA/CS:**
- ✅ **Centralized management** of all document verifications
- ✅ **Efficient workflow** for document review
- ✅ **Audit trail** for compliance purposes

### **For System:**
- ✅ **Complete tracking** of document lifecycle
- ✅ **Security** through verification process
- ✅ **Compliance** with regulatory requirements

This integration provides a complete document verification system that enhances security and transparency across the entire application!

