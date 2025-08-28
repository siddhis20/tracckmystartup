# Facilitator Code System Implementation Guide

## Overview

This guide explains how to implement the unique facilitator code system that:
1. **Generates unique facilitator codes** (e.g., "FAC-D4E5F6")
2. **Stores them in the backend** for each facilitator
3. **Uses them in all requests/offers** in the code section
4. **Connects the compliance tab** for view-only access when diligence is approved
5. **Maintains all existing working logic**

## Step 1: Run the Database Setup

### Execute the SQL Script

1. **Open your Supabase Dashboard**
2. **Go to SQL Editor**
3. **Copy and paste the contents of `FACILITATOR_CODE_SYSTEM.sql`**
4. **Click Run**

### What This Creates

- **`facilitator_code` column** in users table
- **Unique code generation functions**
- **Compliance access system**
- **All necessary RPC functions**

## Step 2: Add Facilitator Code Display to Header

### Update the Header Component

Add the `FacilitatorCodeDisplay` component to your header:

```tsx
import { FacilitatorCodeDisplay } from './components/FacilitatorCodeDisplay';

// In your header component
<div className="flex items-center gap-4">
    <FacilitatorCodeDisplay className="bg-blue-100 text-blue-800 px-3 py-1 rounded-md text-sm font-medium" />
    {/* Other header elements */}
</div>
```

### Expected Result

The header should show:
```
Facilitator Code: FAC-D4E5F6
```

## Step 3: Update Offers to Use Real Facilitator Codes

### Current Status

The offers currently show fallback codes like `FAC-27EC1C`. To use real facilitator codes:

1. **Import the service**:
```tsx
import { getFacilitatorCode } from '../lib/facilitatorCodeService';
```

2. **Update the code generation** in `CapTableTab.tsx`:
```tsx
// Replace the fallback code generation with real facilitator codes
const facilitatorCode = await getFacilitatorCode(app.incubation_opportunities?.facilitator_id) || 
                       `FAC-${app.id.slice(-6).toUpperCase()}`;
```

## Step 4: Connect Compliance Access

### When Diligence is Approved

The system automatically:
1. **Grants compliance access** to the facilitator
2. **Creates a record** in the `compliance_access` table
3. **Sets expiration** to 30 days from approval

### View-Only Access

Facilitators can now:
1. **View the compliance tab** for startups they have access to
2. **Access is time-limited** (30 days)
3. **Access is application-specific**

## Step 5: Update Facilitator Panel

### Add "View Diligence" Button

In the facilitator panel, add a button that:
1. **Checks if facilitator has access** using `hasComplianceAccess()`
2. **Shows "View Diligence"** if access is granted
3. **Opens compliance tab** in view-only mode

### Example Implementation

```tsx
import { hasComplianceAccess } from '../lib/facilitatorCodeService';

// In your facilitator panel component
const [hasAccess, setHasAccess] = useState(false);

useEffect(() => {
    const checkAccess = async () => {
        if (user?.id && startup?.id) {
            const access = await hasComplianceAccess(user.id, startup.id);
            setHasAccess(access);
        }
    };
    checkAccess();
}, [user?.id, startup?.id]);

// In your JSX
{hasAccess && (
    <Button onClick={() => handleViewDiligence(startup.id)}>
        View Diligence
    </Button>
)}
```

## Database Schema

### Users Table
```sql
ALTER TABLE users ADD COLUMN facilitator_code VARCHAR(10) UNIQUE;
```

### Compliance Access Table
```sql
CREATE TABLE compliance_access (
    id UUID PRIMARY KEY,
    facilitator_id UUID REFERENCES users(id),
    startup_id BIGINT REFERENCES startups(id),
    application_id UUID REFERENCES opportunity_applications(id),
    access_granted_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE
);
```

## RPC Functions Available

### Code Management
- `generate_facilitator_code()` - Generate unique code
- `assign_facilitator_code(user_id)` - Assign code to user
- `get_facilitator_code(user_id)` - Get code by user ID
- `get_facilitator_by_code(code)` - Get user by code

### Compliance Access
- `grant_compliance_access(facilitator_id, startup_id, application_id)` - Grant access
- `has_compliance_access(facilitator_id, startup_id)` - Check access
- `grant_facilitator_compliance_access(facilitator_id, startup_id)` - Legacy function

## Testing

### 1. Check Facilitator Codes
```sql
SELECT name, email, facilitator_code FROM users WHERE role = 'Startup Facilitation Center';
```

### 2. Test Code Generation
```sql
SELECT assign_facilitator_code('your-user-id');
```

### 3. Test Compliance Access
```sql
SELECT has_compliance_access('facilitator-id', startup-id);
```

## Integration Points

### 1. Header Display
- Shows facilitator code for logged-in facilitators
- Styled as shown in the image

### 2. Offer Codes
- Real facilitator codes in offer listings
- Fallback to application-based codes if needed

### 3. Compliance Access
- Automatic access grant when diligence approved
- Time-limited access (30 days)
- View-only mode for facilitators

### 4. Facilitator Panel
- "View Diligence" button for approved access
- Direct link to compliance tab

## Security Features

1. **Unique codes** - No duplicate facilitator codes
2. **Time-limited access** - Compliance access expires
3. **Application-specific** - Access tied to specific applications
4. **View-only mode** - Facilitators cannot edit compliance data
5. **Audit trail** - All access is logged with timestamps

## Next Steps

1. **Run the SQL script** to set up the database
2. **Add the header component** to display facilitator codes
3. **Update offer generation** to use real codes
4. **Implement compliance access** in facilitator panel
5. **Test the complete flow** from diligence approval to compliance viewing

This system maintains all existing functionality while adding the unique facilitator code system and compliance access features.
