-- =====================================================
-- FIX COMPLIANCE STATUS COLUMN
-- =====================================================
-- This script ensures the compliance_status column exists in startups table
-- Run this in your Supabase SQL Editor

-- =====================================================
-- STEP 1: CHECK CURRENT COLUMNS
-- =====================================================

-- Check what columns exist in startups table
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'startups' 
AND column_name LIKE '%compliance%'
ORDER BY ordinal_position;

-- =====================================================
-- STEP 2: ADD COMPLIANCE STATUS COLUMN IF MISSING
-- =====================================================

-- Add compliance_status column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'startups' AND column_name = 'compliance_status'
    ) THEN
        ALTER TABLE public.startups ADD COLUMN compliance_status VARCHAR(20) DEFAULT 'Pending';
        RAISE NOTICE 'Added compliance_status column to startups table';
    ELSE
        RAISE NOTICE 'compliance_status column already exists';
    END IF;
END $$;

-- =====================================================
-- STEP 3: UPDATE EXISTING RECORDS
-- =====================================================

-- Update existing startups to have a compliance status if they don't have one
UPDATE public.startups 
SET compliance_status = 'Pending' 
WHERE compliance_status IS NULL;

-- =====================================================
-- STEP 4: VERIFY THE FIX
-- =====================================================

-- Check the final state
SELECT 
    id,
    name,
    compliance_status,
    created_at
FROM public.startups 
ORDER BY created_at DESC
LIMIT 10;

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

SELECT '✅ Compliance Status Column Fixed!' as status;


