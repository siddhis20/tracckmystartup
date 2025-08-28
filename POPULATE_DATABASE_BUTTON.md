# Database Population Instructions

## Issue Fixed
The 409 error was caused by the `new_investments` table being empty, which caused foreign key constraint violations when trying to create investment offers.

## Solution Implemented
1. **Automatic Population**: The `getNewInvestments()` function now automatically populates the database with mock data if it's empty
2. **Manual Population**: You can also manually populate the database using the SQL script

## Manual Database Population

### Option 1: Using SQL Script
Run the `POPULATE_NEW_INVESTMENTS.sql` script in your Supabase SQL editor:

```sql
-- This will populate the new_investments table with all the mock data
-- Run this in Supabase SQL Editor
```

### Option 2: Using Frontend Function
You can call the population function from the browser console:

```javascript
// Open browser console and run:
const { investmentService } = await import('./lib/database.ts');
await investmentService.populateNewInvestments();
```

### Option 3: Automatic Population
The system now automatically populates the database when:
- User visits the Investor Panel
- `getNewInvestments()` is called and finds empty table
- This happens transparently in the background

## Verification
After population, you should see:
- 18 investment opportunities in the "Discover Pitches" section
- Investment offers can be submitted without 409 errors
- Foreign key constraints are satisfied

## Data Structure
The populated data includes:
- IDs: 101-118 (matching the mock data)
- Names: QuantumLeap, AgroFuture, CyberGuard, etc.
- Investment types: Seed, SeriesA, SeriesB, PreSeed
- Sectors: DeepTech, AgriTech, Cybersecurity, etc.
- Compliance statuses: Compliant, Pending, NonCompliant
