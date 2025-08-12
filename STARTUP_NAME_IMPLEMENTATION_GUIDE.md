# Startup Name Implementation Guide

## Overview
This guide explains the changes made to implement startup name storage directly in the users table, allowing for more efficient startup data retrieval and eliminating the need for complex founder-based lookups.

## Database Changes

### 1. SQL Script: `ADD_STARTUP_NAME_COLUMN.sql`
This script adds the `startup_name` column to the users table with the following features:

- **New Column**: `startup_name TEXT` in the users table
- **Constraint**: Ensures startup_name is only set for users with role 'Startup'
- **Index**: Creates an index for faster lookups
- **Function**: `get_startup_by_user_email()` for direct startup data retrieval
- **View**: `user_startup_info` for easy access to user-startup relationships
- **RLS Policies**: Updated to include startup_name in security policies

### 2. Test Script: `TEST_STARTUP_NAME_SETUP.sql`
Use this script to verify that all database changes were applied correctly.

## Code Changes

### 1. Auth Service (`lib/auth.ts`)

#### Updated Interfaces
```typescript
export interface SignUpData {
  email: string
  password: string
  name: string
  role: UserRole
  startupName?: string  // NEW: Optional startup name
}

export interface AuthUser {
  id: string
  email: string
  name: string
  role: UserRole
  startup_name?: string  // NEW: Startup name from database
  registration_date: string
}
```

#### Updated Functions
- **`signUp()`**: Now accepts and stores `startupName` in the users table
- **`getCurrentUser()`**: Now fetches and returns `startup_name` from the database

### 2. Registration Page (`components/RegistrationPage.tsx`)

#### New State
```typescript
const [startupName, setStartupName] = useState('');
```

#### New Form Field
- Added startup name input field that appears only when "Startup" role is selected
- Field is required for startup users

#### Updated Registration Call
```typescript
onRegister(user, role === 'Startup' ? founderDataToSubmit : [], role === 'Startup' ? startupName : undefined);
```

### 3. App Component (`App.tsx`)

#### Updated Startup Logic
- **Before**: Searched for startup by matching founder email
- **After**: Directly matches startup by name using `currentUser.startup_name`

#### Simplified Flow
```typescript
if (currentUser?.role === 'Startup') {
  // Find the user's startup by startup_name from users table
  const userStartup = startups.find(startup => 
    startup.name === currentUser.startup_name
  );
  
  if (userStartup) {
    return <StartupHealthView startup={userStartup} ... />;
  }
}
```

## New User Flow

### 1. Registration
1. User selects "Startup" role
2. User enters startup name (required)
3. User adds founder details
4. System creates user account with `startup_name` stored in users table
5. System creates startup record with the provided name

### 2. Login
1. User logs in
2. System fetches user profile including `startup_name`
3. System automatically finds startup by name
4. User goes directly to `StartupHealthView` dashboard

### 3. Data Retrieval
- **Before**: Complex lookup through founders table
- **After**: Direct lookup using `startup_name` column

## Benefits

### 1. Performance
- **Eliminates JOINs**: No need to join users → founders → startups
- **Direct Lookup**: Single query to find user's startup
- **Indexed Column**: `startup_name` is indexed for fast searches

### 2. Simplicity
- **Cleaner Code**: Removes complex founder-based logic
- **Direct Relationship**: User directly linked to startup by name
- **Easier Maintenance**: Simpler queries and relationships

### 3. Data Integrity
- **Constraint Enforcement**: Database ensures startup_name only set for Startup users
- **Consistent Naming**: Startup name stored in one place
- **Audit Trail**: Clear relationship between user and startup

## Database Schema

### Users Table
```sql
users (
  id UUID PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  role TEXT NOT NULL,
  startup_name TEXT,  -- NEW COLUMN
  registration_date DATE NOT NULL,
  -- ... other fields
)
```

### Constraints
```sql
-- Ensure startup_name is only set for Startup users
CONSTRAINT chk_startup_name_role CHECK (
  (role = 'Startup' AND startup_name IS NOT NULL) OR 
  (role != 'Startup' AND startup_name IS NULL)
)
```

### Indexes
```sql
-- Fast lookup by startup name
CREATE INDEX idx_users_startup_name ON users(startup_name);
```

## Migration Notes

### For Existing Users
- Existing startup users will need their `startup_name` populated
- You can run a migration script to set startup names based on existing founder relationships

### For New Users
- New startup registrations will automatically include startup names
- The system will work immediately for new users

## Testing

### 1. Run Database Scripts
```bash
# Execute the main script
psql -d your_database -f ADD_STARTUP_NAME_COLUMN.sql

# Test the setup
psql -d your_database -f TEST_STARTUP_NAME_SETUP.sql
```

### 2. Test Registration Flow
1. Register a new startup user
2. Verify startup_name is stored in users table
3. Verify startup record is created
4. Test login and dashboard access

### 3. Test Existing Users
1. Check if existing startup users have startup_name set
2. Update any missing startup names
3. Verify dashboard access works

## Troubleshooting

### Common Issues

#### 1. Constraint Violation
- **Error**: `new row for relation "users" violates check constraint "chk_startup_name_role"`
- **Solution**: Ensure startup users have startup_name set, non-startup users have NULL

#### 2. Missing Startup
- **Error**: "No startup associated with your account"
- **Solution**: Check if startup_name is set correctly in users table

#### 3. Performance Issues
- **Symptom**: Slow startup lookups
- **Solution**: Verify index on startup_name column exists

## Future Enhancements

### 1. Startup Name Validation
- Add validation to ensure startup names are unique
- Add format requirements for startup names

### 2. Startup Name Updates
- Allow users to update their startup name
- Add audit trail for name changes

### 3. Bulk Operations
- Add functions for bulk startup name updates
- Add migration tools for existing data
