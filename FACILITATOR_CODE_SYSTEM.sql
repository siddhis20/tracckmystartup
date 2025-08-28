-- =====================================================
-- FACILITATOR CODE SYSTEM IMPLEMENTATION
-- =====================================================
-- This script implements unique facilitator codes and compliance access

-- 1. Add facilitator_code column to users table if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'facilitator_code'
    ) THEN
        ALTER TABLE users ADD COLUMN facilitator_code VARCHAR(10) UNIQUE;
        RAISE NOTICE 'Added facilitator_code column to users table';
    ELSE
        RAISE NOTICE 'facilitator_code column already exists';
    END IF;
END $$;

-- 2. Create function to generate unique facilitator codes
CREATE OR REPLACE FUNCTION generate_facilitator_code()
RETURNS VARCHAR(10) AS $$
DECLARE
    new_code VARCHAR(10);
    code_exists BOOLEAN;
    attempts INTEGER := 0;
    max_attempts INTEGER := 100;
BEGIN
    LOOP
        -- Generate a random 6-character code
        new_code := 'FAC-' || upper(substring(md5(random()::text) from 1 for 6));
        
        -- Check if code already exists
        SELECT EXISTS(
            SELECT 1 FROM users WHERE facilitator_code = new_code
        ) INTO code_exists;
        
        -- If code doesn't exist, return it
        IF NOT code_exists THEN
            RETURN new_code;
        END IF;
        
        -- Prevent infinite loop
        attempts := attempts + 1;
        IF attempts >= max_attempts THEN
            RAISE EXCEPTION 'Could not generate unique facilitator code after % attempts', max_attempts;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 3. Create function to assign facilitator code to user
CREATE OR REPLACE FUNCTION assign_facilitator_code(p_user_id UUID)
RETURNS VARCHAR(10) AS $$
DECLARE
    new_code VARCHAR(10);
    user_role TEXT;
BEGIN
    -- Check if user is a facilitator
    SELECT role INTO user_role FROM users WHERE id = p_user_id;
    
    IF user_role != 'Startup Facilitation Center' THEN
        RAISE EXCEPTION 'User is not a facilitator';
    END IF;
    
    -- Check if user already has a code
    IF EXISTS(SELECT 1 FROM users WHERE id = p_user_id AND facilitator_code IS NOT NULL) THEN
        SELECT facilitator_code INTO new_code FROM users WHERE id = p_user_id;
        RETURN new_code;
    END IF;
    
    -- Generate and assign new code
    new_code := generate_facilitator_code();
    
    UPDATE users 
    SET facilitator_code = new_code 
    WHERE id = p_user_id;
    
    RETURN new_code;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Create function to get facilitator code by user ID
CREATE OR REPLACE FUNCTION get_facilitator_code(p_user_id UUID)
RETURNS VARCHAR(10) AS $$
DECLARE
    code VARCHAR(10);
BEGIN
    SELECT facilitator_code INTO code 
    FROM users 
    WHERE id = p_user_id;
    
    RETURN code;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Create function to get facilitator by code
CREATE OR REPLACE FUNCTION get_facilitator_by_code(p_code VARCHAR(10))
RETURNS UUID AS $$
DECLARE
    facilitator_id UUID;
BEGIN
    SELECT id INTO facilitator_id 
    FROM users 
    WHERE facilitator_code = p_code AND role = 'Startup Facilitation Center';
    
    RETURN facilitator_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Create compliance access table for view-only access
CREATE TABLE IF NOT EXISTS compliance_access (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    facilitator_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    startup_id BIGINT NOT NULL REFERENCES startups(id) ON DELETE CASCADE,
    application_id UUID NOT NULL REFERENCES opportunity_applications(id) ON DELETE CASCADE,
    access_granted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(facilitator_id, startup_id, application_id)
);

-- 7. Create function to grant compliance access
CREATE OR REPLACE FUNCTION grant_compliance_access(
    p_facilitator_id UUID,
    p_startup_id BIGINT,
    p_application_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    access_count INTEGER;
BEGIN
    -- Insert or update compliance access
    INSERT INTO compliance_access (
        facilitator_id, 
        startup_id, 
        application_id,
        expires_at
    ) VALUES (
        p_facilitator_id,
        p_startup_id,
        p_application_id,
        NOW() + INTERVAL '30 days'
    )
    ON CONFLICT (facilitator_id, startup_id, application_id)
    DO UPDATE SET 
        is_active = TRUE,
        access_granted_at = NOW(),
        expires_at = NOW() + INTERVAL '30 days';
    
    GET DIAGNOSTICS access_count = ROW_COUNT;
    
    RETURN access_count > 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Create function to check compliance access
CREATE OR REPLACE FUNCTION has_compliance_access(
    p_facilitator_id UUID,
    p_startup_id BIGINT
)
RETURNS BOOLEAN AS $$
DECLARE
    access_exists BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM compliance_access 
        WHERE facilitator_id = p_facilitator_id 
        AND startup_id = p_startup_id 
        AND is_active = TRUE 
        AND expires_at > NOW()
    ) INTO access_exists;
    
    RETURN access_exists;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Update the existing grant_facilitator_compliance_access function
CREATE OR REPLACE FUNCTION grant_facilitator_compliance_access(
    p_facilitator_id UUID,
    p_startup_id BIGINT
)
RETURNS VOID AS $$
BEGIN
    -- Grant compliance access using the new system
    PERFORM grant_compliance_access(p_facilitator_id, p_startup_id, NULL);
    
    RAISE NOTICE 'Compliance access granted for facilitator % to startup %', p_facilitator_id, p_startup_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Grant execute permissions
GRANT EXECUTE ON FUNCTION generate_facilitator_code() TO authenticated;
GRANT EXECUTE ON FUNCTION assign_facilitator_code(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_facilitator_code(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_facilitator_by_code(VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION grant_compliance_access(UUID, BIGINT, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION has_compliance_access(UUID, BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION grant_facilitator_compliance_access(UUID, BIGINT) TO authenticated;

-- 11. Assign codes to existing facilitators
DO $$
DECLARE
    facilitator_record RECORD;
BEGIN
    FOR facilitator_record IN 
        SELECT id FROM users 
        WHERE role = 'Startup Facilitation Center' 
        AND facilitator_code IS NULL
    LOOP
        PERFORM assign_facilitator_code(facilitator_record.id);
        RAISE NOTICE 'Assigned facilitator code to user %', facilitator_record.id;
    END LOOP;
END $$;

-- 12. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_facilitator_code ON users(facilitator_code);
CREATE INDEX IF NOT EXISTS idx_compliance_access_facilitator ON compliance_access(facilitator_id);
CREATE INDEX IF NOT EXISTS idx_compliance_access_startup ON compliance_access(startup_id);
CREATE INDEX IF NOT EXISTS idx_compliance_access_active ON compliance_access(is_active, expires_at);

-- 13. Show current facilitator codes
SELECT 'Current Facilitator Codes:' as info;
SELECT 
    u.id,
    u.name,
    u.email,
    u.facilitator_code,
    u.role
FROM users u
WHERE u.role = 'Startup Facilitation Center'
ORDER BY u.facilitator_code;

-- 14. Summary
SELECT 'FACILITATOR CODE SYSTEM IMPLEMENTED' as summary;
SELECT 
    'Unique code generation' as feature_1,
    'Backend storage' as feature_2,
    'Compliance access system' as feature_3,
    'Integration ready' as status;
