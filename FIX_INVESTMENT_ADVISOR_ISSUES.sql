-- =====================================================
-- FIX INVESTMENT ADVISOR CODE AND LOGO ISSUES
-- =====================================================

-- 1. Check if the Investment Advisor code generation trigger exists and is working
SELECT 'Checking Investment Advisor code generation trigger...' as status;

-- Check if the function exists
SELECT 
  'Function Status' as info,
  proname as function_name,
  prosrc as function_source
FROM pg_proc 
WHERE proname = 'generate_investment_advisor_code';

-- Check if the trigger exists
SELECT 
  'Trigger Status' as info,
  tgname as trigger_name,
  tgrelid::regclass as table_name,
  tgenabled as enabled
FROM pg_trigger 
WHERE tgname = 'trigger_set_investment_advisor_code';

-- 2. Recreate the Investment Advisor code generation function if needed
CREATE OR REPLACE FUNCTION generate_investment_advisor_code()
RETURNS TEXT AS $$
DECLARE
    new_code TEXT;
    code_exists BOOLEAN;
BEGIN
    LOOP
        -- Generate a code like IA-XXXXXX (6 random digits)
        new_code := 'IA-' || LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
        
        -- Check if code already exists
        SELECT EXISTS(SELECT 1 FROM users WHERE investment_advisor_code = new_code) INTO code_exists;
        
        -- If code doesn't exist, return it
        IF NOT code_exists THEN
            RETURN new_code;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 3. Recreate the trigger function
CREATE OR REPLACE FUNCTION set_investment_advisor_code()
RETURNS TRIGGER AS $$
BEGIN
    -- Only set code for Investment Advisor role
    IF NEW.role = 'Investment Advisor' AND (NEW.investment_advisor_code IS NULL OR NEW.investment_advisor_code = '') THEN
        NEW.investment_advisor_code := generate_investment_advisor_code();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Drop and recreate the trigger
DROP TRIGGER IF EXISTS trigger_set_investment_advisor_code ON users;
CREATE TRIGGER trigger_set_investment_advisor_code
    BEFORE INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION set_investment_advisor_code();

-- 5. Test the function
SELECT 'Testing Investment Advisor code generation...' as status;
SELECT generate_investment_advisor_code() as test_code_1;
SELECT generate_investment_advisor_code() as test_code_2;
SELECT generate_investment_advisor_code() as test_code_3;

-- 6. Check existing Investment Advisors and their codes
SELECT 
  'Existing Investment Advisors' as info,
  id,
  email,
  name,
  investment_advisor_code,
  logo_url,
  created_at
FROM users 
WHERE role = 'Investment Advisor'
ORDER BY created_at DESC;

-- 7. Update any Investment Advisors without codes
UPDATE users 
SET investment_advisor_code = generate_investment_advisor_code()
WHERE role = 'Investment Advisor' 
  AND (investment_advisor_code IS NULL OR investment_advisor_code = '');

-- 8. Verify the updates
SELECT 
  'Updated Investment Advisors' as info,
  id,
  email,
  name,
  investment_advisor_code,
  logo_url
FROM users 
WHERE role = 'Investment Advisor'
ORDER BY created_at DESC;

-- 9. Check if logo_url column exists and has proper data
SELECT 
  'Logo URL Column Check' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'users' 
  AND column_name = 'logo_url';

-- 10. Test the complete setup
SELECT 
  'Setup Complete' as status,
  'Investment Advisor code generation and logo support are now properly configured' as message;

