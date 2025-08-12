-- =====================================================
-- STORAGE HELPER FUNCTIONS FOR STARTUP NATION APP
-- =====================================================
-- This script creates helper functions for storage policies
-- Run this in your Supabase SQL Editor (this is safe to run)

-- =====================================================
-- HELPER FUNCTIONS FOR STORAGE POLICIES
-- =====================================================

-- Function to get current user's role
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS TEXT AS $$
BEGIN
  RETURN (
    SELECT role::TEXT 
    FROM public.users 
    WHERE id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN get_user_role() = 'Admin';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is startup
CREATE OR REPLACE FUNCTION is_startup()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN get_user_role() = 'Startup';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is investor
CREATE OR REPLACE FUNCTION is_investor()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN get_user_role() = 'Investor';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is CA or CS
CREATE OR REPLACE FUNCTION is_ca_or_cs()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN get_user_role() IN ('CA', 'CS');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is facilitator
CREATE OR REPLACE FUNCTION is_facilitator()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN get_user_role() = 'Startup Facilitation Center';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Test helper functions
SELECT 
  'get_user_role' as function_name,
  get_user_role() as result
UNION ALL
SELECT 
  'is_admin' as function_name,
  is_admin()::TEXT as result
UNION ALL
SELECT 
  'is_startup' as function_name,
  is_startup()::TEXT as result
UNION ALL
SELECT 
  'is_investor' as function_name,
  is_investor()::TEXT as result
UNION ALL
SELECT 
  'is_ca_or_cs' as function_name,
  is_ca_or_cs()::TEXT as result
UNION ALL
SELECT 
  'is_facilitator' as function_name,
  is_facilitator()::TEXT as result;

-- =====================================================
-- NEXT STEPS
-- =====================================================

/*
AFTER RUNNING THIS SCRIPT:

1. Go to Supabase Dashboard > Storage > Policies
2. For each bucket, create policies using these functions:

EXAMPLE POLICIES FOR DASHBOARD:

startup-documents bucket:
- Upload: is_startup() OR is_admin()
- View: auth.role() = 'authenticated'
- Update: is_startup() OR is_admin()
- Delete: is_startup() OR is_admin()

pitch-decks bucket:
- Upload: is_startup() OR is_admin()
- View: auth.role() = 'authenticated'
- Update: is_startup() OR is_admin()
- Delete: is_startup() OR is_admin()

pitch-videos bucket:
- Upload: is_startup() OR is_admin()
- View: auth.role() = 'authenticated'
- Update: is_startup() OR is_admin()
- Delete: is_startup() OR is_admin()

financial-documents bucket:
- Upload: is_startup() OR is_ca_or_cs() OR is_admin()
- View: auth.role() = 'authenticated'
- Update: is_startup() OR is_ca_or_cs() OR is_admin()
- Delete: is_startup() OR is_ca_or_cs() OR is_admin()

employee-contracts bucket:
- Upload: is_startup() OR is_admin()
- View: is_startup() OR is_admin() OR is_ca_or_cs()
- Update: is_startup() OR is_admin()
- Delete: is_startup() OR is_admin()

verification-documents bucket:
- Upload: is_startup() OR is_ca_or_cs() OR is_admin()
- View: auth.role() = 'authenticated'
- Update: is_ca_or_cs() OR is_admin()
- Delete: is_ca_or_cs() OR is_admin()

3. Test the policies with different user roles
*/
