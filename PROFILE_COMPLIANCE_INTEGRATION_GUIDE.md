# Profile & Compliance Integration Guide

## Overview

This guide explains how the ProfileTab and ComplianceTab components work together to provide a comprehensive company profile and compliance management system.

## Architecture

### 1. ProfileTab Component

The ProfileTab component manages company profile information including:

- **Primary Details**: Country, company type, registration date
- **Service Providers**: CA (Chartered Accountant) and CS (Company Secretary) assignments
- **Subsidiaries**: Multiple subsidiary companies with their own service providers
- **International Operations**: Countries where business is conducted without subsidiaries

### 2. ComplianceTab Component

The ComplianceTab component generates compliance tasks based on:

- Company registration dates
- Country-specific compliance rules
- Service provider assignments (CA/CS)
- Entity structure (parent company + subsidiaries)

## Key Features

### Service Provider Management

#### Service Provider Codes
- **CA Codes**: Chartered Accountant service codes (e.g., CA001, CA002)
- **CS Codes**: Company Secretary service codes (e.g., CS001, CS002)

#### Service Provider Assignment
1. **Primary Company**: Can assign CA and CS service providers
2. **Subsidiaries**: Each subsidiary can have its own CA and CS service providers
3. **Auto-fetch**: When a valid service code is entered, the system automatically fetches provider details

#### Service Provider Display
- Shows provider name and license link
- Allows changing providers in edit mode
- Displays "View License" link for verification

### Compliance Task Generation

#### Entity-based Tasks
The system generates compliance tasks for:
- **Parent Company**: Based on registration date and country
- **Subsidiaries**: Each subsidiary gets its own set of compliance tasks
- **International Operations**: May generate additional compliance requirements

#### Task Assignment
- **CA Tasks**: Assigned to the CA service provider for each entity
- **CS Tasks**: Assigned to the CS service provider for each entity
- **Verification**: Only assigned service providers can update task status

#### Compliance Status
- **Pending**: Task awaiting verification
- **Verified**: Task completed and verified
- **Rejected**: Task failed verification
- **Not Required**: Task not applicable for this entity

## Database Schema

### Service Providers Table
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

### Subsidiaries Table
```sql
ALTER TABLE subsidiaries 
ADD COLUMN ca_service_code VARCHAR(50) REFERENCES service_providers(code),
ADD COLUMN cs_service_code VARCHAR(50) REFERENCES service_providers(code);
```

### Startups Table
```sql
ALTER TABLE startups 
ADD COLUMN ca_service_code VARCHAR(50) REFERENCES service_providers(code),
ADD COLUMN cs_service_code VARCHAR(50) REFERENCES service_providers(code);
```

## Integration Flow

### 1. Profile Setup
1. User enters company details in ProfileTab
2. User assigns service providers by entering service codes
3. System validates service codes and fetches provider details
4. Profile data is saved to database

### 2. Compliance Generation
1. ComplianceTab reads profile data
2. Generates compliance tasks based on:
   - Registration dates
   - Country-specific rules
   - Company types
3. Assigns tasks to appropriate service providers

### 3. Task Management
1. Service providers log in with their service codes
2. They see only tasks assigned to them
3. They can update task status (Pending → Verified/Rejected)
4. Changes are reflected in real-time

## Service Provider Codes

### Sample CA Codes
- `CA001`: Deloitte LLP (US)
- `CA002`: KPMG UK
- `CA003`: PwC India
- `CA004`: EY Singapore
- `CA005`: BDO Germany

### Sample CS Codes
- `CS001`: Corporation Service Company (US)
- `CS002`: Companies House (UK)
- `CS003`: MCA India
- `CS004`: ACRA Singapore
- `CS005`: Handelsregister Germany

## Usage Examples

### Adding a Service Provider
1. Click "Edit Profile" in ProfileTab
2. Enter service code (e.g., "CA001") in the CA field
3. System automatically fetches provider details
4. Provider name and license link appear
5. Save changes

### Managing Subsidiary Service Providers
1. Add subsidiaries in ProfileTab
2. For each subsidiary, enter CA and CS codes
3. System validates and fetches provider details
4. Each subsidiary can have different service providers

### Compliance Task Verification
1. Service provider logs in with their code
2. Navigate to ComplianceTab
3. See tasks assigned to their service code
4. Update task status as needed
5. Changes are saved automatically

## Security Features

### Row Level Security (RLS)
- Service providers can only see their assigned tasks
- Users can only edit their own company profiles
- Admin users have full access

### Data Validation
- Service codes are validated against database
- Company types are validated for selected countries
- Registration dates are validated for format and logic

### Audit Trail
- All profile changes are logged
- Compliance status changes are tracked
- Service provider assignments are recorded

## Error Handling

### Invalid Service Codes
- System shows error message for invalid codes
- Provider details are not fetched
- User can retry with correct code

### Missing Data
- Required fields are highlighted
- Validation errors are displayed
- Save operation is blocked until resolved

### Network Issues
- Real-time updates are retried automatically
- Offline changes are queued for sync
- User is notified of connection status

## Future Enhancements

### Planned Features
1. **Bulk Service Provider Assignment**: Assign same provider to multiple entities
2. **Service Provider Dashboard**: Dedicated view for service providers
3. **Compliance Calendar**: Timeline view of upcoming compliance deadlines
4. **Document Upload**: Direct file upload for compliance documents
5. **Email Notifications**: Automated alerts for compliance deadlines

### Integration Opportunities
1. **Accounting Software**: Connect with QuickBooks, Xero, etc.
2. **Legal Platforms**: Integration with legal document management
3. **Regulatory APIs**: Direct connection to government compliance systems
4. **Audit Tools**: Integration with audit management platforms

## Troubleshooting

### Common Issues

#### Service Provider Not Found
- Verify service code is correct
- Check if provider exists in database
- Ensure provider type matches (CA vs CS)

#### Compliance Tasks Not Generated
- Verify registration dates are set
- Check country-specific compliance rules
- Ensure service providers are assigned

#### Real-time Updates Not Working
- Check network connection
- Verify Supabase configuration
- Check browser console for errors

### Debug Information
- All operations are logged to console
- Database queries can be monitored
- Real-time subscription status is tracked

## Conclusion

The ProfileTab and ComplianceTab integration provides a comprehensive solution for managing company profiles and compliance requirements. The service provider system ensures proper task assignment and verification, while the real-time updates keep all stakeholders informed of changes.

The modular design allows for easy extension and customization, while the security features ensure data integrity and proper access control.
