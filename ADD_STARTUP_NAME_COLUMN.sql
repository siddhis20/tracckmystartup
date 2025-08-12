-- Add startup_name column to users table
-- This allows us to store the startup name directly with the user account

-- Add the startup_name column
ALTER TABLE users 
ADD COLUMN startup_name TEXT;

-- Add a comment to document the column purpose
COMMENT ON COLUMN users.startup_name IS 'Name of the startup associated with this user (only for users with role = Startup)';

-- Create an index on startup_name for faster lookups
CREATE INDEX idx_users_startup_name ON users(startup_name);

-- Add a check constraint to ensure startup_name is only set for Startup users
ALTER TABLE users 
ADD CONSTRAINT chk_startup_name_role 
CHECK (
  (role = 'Startup' AND startup_name IS NOT NULL) OR 
  (role != 'Startup' AND startup_name IS NULL)
);

-- Update RLS policies to include startup_name
-- This ensures users can only see their own startup name
ALTER POLICY "Users can view own profile" ON users
USING (auth.uid() = id);

-- If you have existing startup users, you might want to update them
-- Example: UPDATE users SET startup_name = 'Default Startup Name' WHERE role = 'Startup' AND startup_name IS NULL;

-- Grant necessary permissions
GRANT SELECT, UPDATE ON users TO authenticated;
GRANT SELECT ON users TO anon;

-- Create a function to get startup details by user email
CREATE OR REPLACE FUNCTION get_startup_by_user_email(user_email TEXT)
RETURNS TABLE (
  startup_id INTEGER,
  startup_name TEXT,
  sector TEXT,
  current_valuation NUMERIC,
  total_funding NUMERIC,
  total_revenue NUMERIC,
  compliance_status TEXT,
  registration_date DATE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    s.id,
    s.name,
    s.sector,
    s.current_valuation,
    s.total_funding,
    s.total_revenue,
    s.compliance_status,
    s.registration_date
  FROM startups s
  INNER JOIN users u ON u.startup_name = s.name
  WHERE u.email = user_email AND u.role = 'Startup';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION get_startup_by_user_email(TEXT) TO authenticated;

-- Create a view for startup users to see their startup info
CREATE OR REPLACE VIEW user_startup_info AS
SELECT 
  u.id as user_id,
  u.email,
  u.name as user_name,
  u.role,
  u.startup_name,
  s.id as startup_id,
  s.sector,
  s.current_valuation,
  s.total_funding,
  s.total_revenue,
  s.compliance_status,
  s.registration_date
FROM users u
LEFT JOIN startups s ON u.startup_name = s.name
WHERE u.role = 'Startup';

-- Grant select permission on the view
GRANT SELECT ON user_startup_info TO authenticated;

-- Add RLS to the view
ALTER VIEW user_startup_info SET (security_invoker = true);

-- Create policy for the view
CREATE POLICY "Users can view own startup info" ON user_startup_info
FOR SELECT USING (auth.uid() = user_id);
