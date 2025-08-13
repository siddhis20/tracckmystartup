-- Test Cap Table Database Connection and Tables
-- Run this in your Supabase SQL editor to check if tables exist

-- Check if tables exist
SELECT 
    table_name,
    CASE 
        WHEN table_name IS NOT NULL THEN 'EXISTS'
        ELSE 'MISSING'
    END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
    AND table_name IN (
        'investment_records',
        'founders', 
        'fundraising_details',
        'valuation_history',
        'equity_holdings'
    );

-- Check table structures
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name IN (
        'investment_records',
        'founders', 
        'fundraising_details',
        'valuation_history',
        'equity_holdings'
    )
ORDER BY table_name, ordinal_position;

-- Test RLS policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE schemaname = 'public' 
    AND tablename IN (
        'investment_records',
        'founders', 
        'fundraising_details',
        'valuation_history',
        'equity_holdings'
    );

-- Test RPC functions
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND routine_name IN (
        'get_investment_summary',
        'get_valuation_history',
        'get_equity_distribution',
        'get_fundraising_status'
    );
