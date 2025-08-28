# Recognition & Incubation Backend Implementation Guide

## Overview
This guide explains how to implement the backend for the Recognition & Incubation form in the Cap Table tab. The system allows startups to add recognition records that are connected to facilitators via facilitator codes.

## 🗄️ Database Setup

### 1. Create the Recognition Records Table
Run the `CREATE_RECOGNITION_RECORDS_TABLE.sql` script to:
- Create the `recognition_records` table
- Set up foreign key constraints to `startups` table
- Create performance indexes
- Enable Row Level Security (RLS)
- Set up RLS policies for startups and facilitators

### 2. Table Structure
```sql
CREATE TABLE recognition_records (
    id SERIAL PRIMARY KEY,
    startup_id INTEGER NOT NULL REFERENCES startups(id),
    program_name VARCHAR(255) NOT NULL,
    facilitator_name VARCHAR(255) NOT NULL,
    facilitator_code VARCHAR(50) NOT NULL,
    incubation_type VARCHAR(100) NOT NULL,
    fee_type VARCHAR(50) NOT NULL,
    fee_amount DECIMAL(15,2),
    equity_allocated DECIMAL(5,2),
    pre_money_valuation DECIMAL(15,2),
    signed_agreement_url TEXT,
    date_added DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 3. RLS Policies
- **Startups**: Can view, insert, update, and delete their own records
- **Facilitators**: Can view records where they are the facilitator
- **Security**: Based on user authentication and role-based access

## 🔧 Backend Service

### 1. Recognition Service (`lib/recognitionService.ts`)
The service provides these key functions:

#### Core CRUD Operations
- `createRecognitionRecord()` - Add new recognition records
- `getRecognitionRecordsByStartupId()` - Get records for a specific startup
- `getRecognitionRecordsByFacilitatorCode()` - Get records for a specific facilitator
- `updateRecognitionRecord()` - Update existing records
- `deleteRecognitionRecord()` - Delete records

#### Validation & Utilities
- `validateFacilitatorCode()` - Verify facilitator code exists
- `getStartupDetailsForRecognition()` - Get startup info for a record

### 2. Key Features
- **Facilitator Code Validation**: Ensures only valid facilitator codes are accepted
- **File Upload Support**: Handles signed agreement document uploads
- **Data Integrity**: Foreign key constraints and RLS policies
- **Performance**: Indexed queries for fast data retrieval

## 🚀 Frontend Integration

### 1. CapTableTab Component Updates
The component now:
- Loads recognition records on mount
- Displays records in the "Recognition and Incubation" table
- Handles form submission with backend integration
- Validates facilitator codes before submission

### 2. Form Handling
```typescript
const handleAddRecognition = async (e: React.FormEvent<HTMLFormElement>) => {
    // 1. Extract form data
    // 2. Validate facilitator code
    // 3. Upload agreement file
    // 4. Create record via service
    // 5. Update local state
    // 6. Reset form
};
```

### 3. Data Loading
```typescript
const loadCapTableData = async () => {
    // Load recognition records along with other cap table data
    const recognitionData = await recognitionService.getRecognitionRecordsByStartupId(startup.id);
    setRecognitionRecords(recognitionData);
};
```

## 🔗 Facilitator Connection

### 1. How It Works
1. **Startup fills form** with facilitator code
2. **System validates** the facilitator code exists
3. **Record is stored** with startup ID and facilitator code
4. **Facilitator can view** records where they are the facilitator
5. **Connection established** between startup and facilitator

### 2. Data Flow
```
Startup Form → Validation → Database Storage → Facilitator Dashboard
     ↓              ↓            ↓              ↓
  Facilitator   Check Code   Store Record   View Records
     Code      Exists in     with Links     by Code
              Users Table
```

### 3. Future Integration
- Facilitator dashboard will show startups that added them
- Compliance access can be granted based on these records
- Communication channels can be established

## 🧪 Testing

### 1. Run Test Script
Execute `TEST_RECOGNITION_BACKEND.sql` to verify:
- Table creation and structure
- RLS policies and indexes
- Data insertion and retrieval
- Facilitator code validation
- Query performance

### 2. Manual Testing
1. **Add Recognition Record**: Fill out the form with valid data
2. **Validate Facilitator Code**: Try invalid codes to test validation
3. **Check Database**: Verify records are stored correctly
4. **Test RLS**: Ensure proper access control

## 📋 Implementation Steps

### Phase 1: Backend Setup ✅
- [x] Create database table
- [x] Set up RLS policies
- [x] Create recognition service
- [x] Test database operations

### Phase 2: Frontend Integration ✅
- [x] Update CapTableTab component
- [x] Integrate with recognition service
- [x] Add form handling
- [x] Load and display records

### Phase 3: Facilitator Dashboard (Future)
- [ ] Show startups that added the facilitator
- [ ] Display recognition records
- [ ] Grant compliance access
- [ ] Establish communication

## 🔒 Security Features

### 1. Row Level Security (RLS)
- Users can only access their own data
- Facilitators can only see records where they are the facilitator
- Prevents unauthorized access to startup information

### 2. Input Validation
- Facilitator code validation before storage
- Required field validation
- File upload security

### 3. Data Integrity
- Foreign key constraints
- Automatic timestamp updates
- Transaction-based operations

## 📊 Data Relationships

```
users (facilitator_code) ←→ recognition_records (facilitator_code)
startups (id) ←→ recognition_records (startup_id)
```

## 🚨 Troubleshooting

### Common Issues
1. **Facilitator Code Not Found**: Ensure the code exists in users table
2. **RLS Policy Errors**: Check user authentication and role
3. **Foreign Key Violations**: Verify startup ID exists
4. **File Upload Failures**: Check storage permissions

### Debug Queries
```sql
-- Check if facilitator code exists
SELECT * FROM users WHERE facilitator_code = 'FAC-XXXXXX';

-- Check recognition records for a startup
SELECT * FROM recognition_records WHERE startup_id = 11;

-- Check RLS policies
SELECT * FROM pg_policies WHERE tablename = 'recognition_records';
```

## 🎯 Next Steps

1. **Test the current implementation** with the test script
2. **Verify form submission** works correctly
3. **Check data persistence** in the database
4. **Prepare for facilitator dashboard integration**

## 📝 Notes

- The system is designed to be scalable and secure
- All operations are logged for debugging
- Error handling is comprehensive
- The backend is ready for future facilitator dashboard integration
- No changes are needed to the existing investor functionality

---

**Status**: Backend implementation complete, frontend integration complete
**Next**: Test and validate the complete system
