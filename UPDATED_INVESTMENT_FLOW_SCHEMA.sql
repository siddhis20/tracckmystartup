-- Updated Investment Flow Schema with Scouting Fees
-- This schema supports the new investment flow where:
-- 1. Investor pays startup scouting fee when making offer
-- 2. Startup pays investor scouting fee when accepting offer
-- 3. Contact details visibility based on investment advisor assignment

-- Note: This schema builds upon the existing database structure that was already executed
-- and adds the missing functions and configurations needed for the new investment flow

-- 1. Update investment_offers table to include scouting fees and new statuses (if not already done)
ALTER TABLE public.investment_offers 
ADD COLUMN IF NOT EXISTS startup_scouting_fee_paid BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS startup_scouting_fee_amount DECIMAL(15,2),
ADD COLUMN IF NOT EXISTS investor_scouting_fee_paid BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS investor_scouting_fee_amount DECIMAL(15,2),
ADD COLUMN IF NOT EXISTS startup_id INTEGER REFERENCES public.startups(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS investor_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS startup_payment_id TEXT,
ADD COLUMN IF NOT EXISTS investor_payment_id TEXT,
ADD COLUMN IF NOT EXISTS contact_details_revealed BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS contact_details_revealed_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS investor_advisor_approval_status TEXT DEFAULT 'not_required',
ADD COLUMN IF NOT EXISTS investor_advisor_approval_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS startup_advisor_approval_status TEXT DEFAULT 'not_required',
ADD COLUMN IF NOT EXISTS startup_advisor_approval_at TIMESTAMP WITH TIME ZONE;

-- 2. Update offer_status enum to include new statuses (if not already done)
DO $$ 
BEGIN
    -- Add new status values if they don't exist
    IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'offer_accepted' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'offer_status')) THEN
        ALTER TYPE offer_status ADD VALUE 'offer_accepted';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'startup_fee_paid' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'offer_status')) THEN
        ALTER TYPE offer_status ADD VALUE 'startup_fee_paid';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'investor_fee_paid' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'offer_status')) THEN
        ALTER TYPE offer_status ADD VALUE 'investor_fee_paid';
    END IF;
    
    -- Add new approval statuses
    IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'pending_investor_advisor_approval' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'offer_status')) THEN
        ALTER TYPE offer_status ADD VALUE 'pending_investor_advisor_approval';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'pending_startup_advisor_approval' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'offer_status')) THEN
        ALTER TYPE offer_status ADD VALUE 'pending_startup_advisor_approval';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'investor_advisor_approved' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'offer_status')) THEN
        ALTER TYPE offer_status ADD VALUE 'investor_advisor_approved';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'startup_advisor_approved' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'offer_status')) THEN
        ALTER TYPE offer_status ADD VALUE 'startup_advisor_approved';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'investor_advisor_rejected' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'offer_status')) THEN
        ALTER TYPE offer_status ADD VALUE 'investor_advisor_rejected';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'startup_advisor_rejected' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'offer_status')) THEN
        ALTER TYPE offer_status ADD VALUE 'startup_advisor_rejected';
    END IF;
END $$;

-- 3. Create scouting_fee_configurations table for admin settings (if not already done)
CREATE TABLE IF NOT EXISTS public.scouting_fee_configurations (
    id SERIAL PRIMARY KEY,
    country TEXT NOT NULL,
    user_type TEXT NOT NULL CHECK (user_type IN ('Investor', 'Startup')),
    amount_raised_min DECIMAL(15,2) DEFAULT 0,
    amount_raised_max DECIMAL(15,2),
    startup_scouting_fee_percentage DECIMAL(5,2) DEFAULT 0,
    startup_scouting_fee_fixed DECIMAL(15,2) DEFAULT 0,
    investor_scouting_fee_percentage DECIMAL(5,2) DEFAULT 0,
    investor_scouting_fee_fixed DECIMAL(15,2) DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(country, user_type, amount_raised_min, amount_raised_max)
);

-- 4. Create payment_records table to track scouting fee payments (if not already done)
CREATE TABLE IF NOT EXISTS public.payment_records (
    id SERIAL PRIMARY KEY,
    offer_id INTEGER NOT NULL REFERENCES public.investment_offers(id) ON DELETE CASCADE,
    payer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    payer_type TEXT NOT NULL CHECK (payer_type IN ('Investor', 'Startup')),
    payment_type TEXT NOT NULL CHECK (payment_type IN ('startup_scouting_fee', 'investor_scouting_fee')),
    amount DECIMAL(15,2) NOT NULL,
    currency TEXT DEFAULT 'USD',
    payment_method TEXT,
    payment_id TEXT UNIQUE,
    payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'completed', 'failed', 'refunded')),
    payment_provider TEXT,
    payment_provider_reference TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Create contact_details_access table to track who can see contact details (if not already done)
CREATE TABLE IF NOT EXISTS public.contact_details_access (
    id SERIAL PRIMARY KEY,
    offer_id INTEGER NOT NULL REFERENCES public.investment_offers(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    user_type TEXT NOT NULL CHECK (user_type IN ('Investor', 'Startup', 'Investment Advisor')),
    access_granted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    access_revoked_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE
);

-- 6. Create investment_ledger table for comprehensive tracking (if not already done)
CREATE TABLE IF NOT EXISTS public.investment_ledger (
    id SERIAL PRIMARY KEY,
    offer_id INTEGER NOT NULL REFERENCES public.investment_offers(id) ON DELETE CASCADE,
    activity_type TEXT NOT NULL CHECK (activity_type IN ('offer_made', 'startup_fee_paid', 'offer_accepted', 'offer_rejected', 'investor_fee_paid', 'contact_revealed')),
    amount DECIMAL(15,2),
    currency TEXT DEFAULT 'USD',
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Enable RLS on new tables (if not already done)
ALTER TABLE public.scouting_fee_configurations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contact_details_access ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.investment_ledger ENABLE ROW LEVEL SECURITY;

-- 8. Create policies for scouting_fee_configurations (if not already done)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'scouting_fee_config_select_all') THEN
        CREATE POLICY scouting_fee_config_select_all ON public.scouting_fee_configurations
            FOR SELECT
            TO authenticated
            USING (true);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'scouting_fee_config_admin_all') THEN
        CREATE POLICY scouting_fee_config_admin_all ON public.scouting_fee_configurations
            FOR ALL
            TO authenticated
            USING (
                EXISTS (
                    SELECT 1 FROM public.users 
                    WHERE id = auth.uid() 
                    AND role = 'Admin'
                )
            );
    END IF;
END $$;

-- 9. Create policies for payment_records (if not already done)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'payment_records_select_own') THEN
        CREATE POLICY payment_records_select_own ON public.payment_records
            FOR SELECT
            TO authenticated
            USING (payer_id = auth.uid());
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'payment_records_insert_own') THEN
        CREATE POLICY payment_records_insert_own ON public.payment_records
            FOR INSERT
            TO authenticated
            WITH CHECK (payer_id = auth.uid());
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'payment_records_admin_all') THEN
        CREATE POLICY payment_records_admin_all ON public.payment_records
            FOR ALL
            TO authenticated
            USING (
                EXISTS (
                    SELECT 1 FROM public.users 
                    WHERE id = auth.uid() 
                    AND role = 'Admin'
                )
            );
    END IF;
END $$;

-- 10. Create policies for contact_details_access (if not already done)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'contact_access_select_own') THEN
        CREATE POLICY contact_access_select_own ON public.contact_details_access
            FOR SELECT
            TO authenticated
            USING (user_id = auth.uid());
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'contact_access_admin_all') THEN
        CREATE POLICY contact_access_admin_all ON public.contact_details_access
            FOR ALL
            TO authenticated
            USING (
                EXISTS (
                    SELECT 1 FROM public.users 
                    WHERE id = auth.uid() 
                    AND role = 'Admin'
                )
            );
    END IF;
END $$;

-- 11. Create policies for investment_ledger (if not already done)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'investment_ledger_select_policy') THEN
        CREATE POLICY investment_ledger_select_policy ON public.investment_ledger
            FOR SELECT
            TO authenticated
            USING (
                EXISTS (
                    SELECT 1 FROM public.investment_offers io 
                    WHERE io.id = investment_ledger.offer_id 
                    AND (
                        io.investor_email = (SELECT email FROM public.users WHERE id = auth.uid())
                        OR EXISTS (
                            SELECT 1 FROM public.startups s 
                            JOIN public.users u ON u.id = s.user_id 
                            WHERE s.id = io.startup_id 
                            AND u.id = auth.uid()
                        )
                        OR EXISTS (
                            SELECT 1 FROM public.users 
                            WHERE id = auth.uid() 
                            AND role IN ('Admin', 'Investment Advisor')
                        )
                    )
                )
            );
    END IF;
END $$;

-- 12. Create indexes for performance (if not already done)
CREATE INDEX IF NOT EXISTS idx_investment_offers_startup_id ON public.investment_offers(startup_id);
CREATE INDEX IF NOT EXISTS idx_investment_offers_investor_id ON public.investment_offers(investor_id);
CREATE INDEX IF NOT EXISTS idx_investment_offers_status ON public.investment_offers(status);
CREATE INDEX IF NOT EXISTS idx_investment_offers_startup_fee_paid ON public.investment_offers(startup_scouting_fee_paid);
CREATE INDEX IF NOT EXISTS idx_investment_offers_investor_fee_paid ON public.investment_offers(investor_scouting_fee_paid);

CREATE INDEX IF NOT EXISTS idx_scouting_fee_config_country ON public.scouting_fee_configurations(country);
CREATE INDEX IF NOT EXISTS idx_scouting_fee_config_user_type ON public.scouting_fee_configurations(user_type);
CREATE INDEX IF NOT EXISTS idx_scouting_fee_config_active ON public.scouting_fee_configurations(is_active);

CREATE INDEX IF NOT EXISTS idx_payment_records_offer_id ON public.payment_records(offer_id);
CREATE INDEX IF NOT EXISTS idx_payment_records_payer_id ON public.payment_records(payer_id);
CREATE INDEX IF NOT EXISTS idx_payment_records_payment_type ON public.payment_records(payment_type);
CREATE INDEX IF NOT EXISTS idx_payment_records_status ON public.payment_records(payment_status);

CREATE INDEX IF NOT EXISTS idx_contact_access_offer_id ON public.contact_details_access(offer_id);
CREATE INDEX IF NOT EXISTS idx_contact_access_user_id ON public.contact_details_access(user_id);
CREATE INDEX IF NOT EXISTS idx_contact_access_active ON public.contact_details_access(is_active);

CREATE INDEX IF NOT EXISTS idx_investment_ledger_offer_id ON public.investment_ledger(offer_id);
CREATE INDEX IF NOT EXISTS idx_investment_ledger_activity_type ON public.investment_ledger(activity_type);

-- 13. Create helper functions (if not already done)

-- Function to calculate scouting fees based on configuration
CREATE OR REPLACE FUNCTION calculate_scouting_fee(
    p_country TEXT,
    p_user_type TEXT,
    p_offer_amount DECIMAL(15,2)
) RETURNS TABLE (
    startup_fee DECIMAL(15,2),
    investor_fee DECIMAL(15,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        CASE 
            WHEN sfc.startup_scouting_fee_percentage > 0 
            THEN (p_offer_amount * sfc.startup_scouting_fee_percentage / 100)
            ELSE sfc.startup_scouting_fee_fixed
        END as startup_fee,
        CASE 
            WHEN sfc.investor_scouting_fee_percentage > 0 
            THEN (p_offer_amount * sfc.investor_scouting_fee_percentage / 100)
            ELSE sfc.investor_scouting_fee_fixed
        END as investor_fee
    FROM public.scouting_fee_configurations sfc
    WHERE sfc.country = p_country
    AND sfc.user_type = p_user_type
    AND sfc.is_active = TRUE
    AND p_offer_amount >= sfc.amount_raised_min
    AND (sfc.amount_raised_max IS NULL OR p_offer_amount <= sfc.amount_raised_max)
    ORDER BY sfc.amount_raised_min DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if contact details should be revealed
CREATE OR REPLACE FUNCTION should_reveal_contact_details(
    p_offer_id INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    offer_record RECORD;
    has_investment_advisor BOOLEAN := FALSE;
BEGIN
    -- Get offer details
    SELECT 
        io.*,
        s.investment_advisor_code as startup_advisor_code,
        u.investment_advisor_code_entered as investor_advisor_code
    INTO offer_record
    FROM public.investment_offers io
    LEFT JOIN public.startups s ON io.startup_id = s.id
    LEFT JOIN public.users u ON io.investor_id = u.id
    WHERE io.id = p_offer_id;
    
    -- Check if either startup or investor has an investment advisor
    has_investment_advisor := (
        offer_record.startup_advisor_code IS NOT NULL OR 
        offer_record.investor_advisor_code IS NOT NULL
    );
    
    -- Contact details should be revealed if:
    -- 1. Offer is accepted AND
    -- 2. Either startup or investor has an investment advisor OR
    -- 3. Neither has an investment advisor (direct contact)
    RETURN (
        offer_record.status = 'offer_accepted' AND
        (has_investment_advisor OR (offer_record.startup_advisor_code IS NULL AND offer_record.investor_advisor_code IS NULL))
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get offers for investment advisor
CREATE OR REPLACE FUNCTION get_offers_for_investment_advisor(
    p_advisor_id UUID
) RETURNS TABLE (
    offer_id INTEGER,
    investor_name TEXT,
    investor_email TEXT,
    startup_name TEXT,
    offer_amount DECIMAL(15,2),
    equity_percentage DECIMAL(5,2),
    status TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    startup_fee_paid BOOLEAN,
    investor_fee_paid BOOLEAN,
    contact_details_revealed BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        io.id as offer_id,
        COALESCE(u.name, io.investor_email) as investor_name,
        io.investor_email,
        io.startup_name,
        io.offer_amount,
        io.equity_percentage,
        io.status::TEXT,
        io.created_at,
        io.startup_scouting_fee_paid,
        io.investor_scouting_fee_paid,
        io.contact_details_revealed
    FROM public.investment_offers io
    LEFT JOIN public.users u ON io.investor_id = u.id
    LEFT JOIN public.startups s ON io.startup_id = s.id
    WHERE (
        -- Offers from investors with this advisor
        u.investment_advisor_code_entered = (SELECT investment_advisor_code FROM public.users WHERE id = p_advisor_id)
        OR
        -- Offers to startups with this advisor
        s.investment_advisor_code = (SELECT investment_advisor_code FROM public.users WHERE id = p_advisor_id)
    )
    ORDER BY io.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create investment offer with scouting fee and advisor approval workflow
CREATE OR REPLACE FUNCTION create_investment_offer_with_fee(
    p_investor_email VARCHAR(255),
    p_startup_name VARCHAR(255),
    p_startup_id INTEGER,
    p_offer_amount DECIMAL(15,2),
    p_equity_percentage DECIMAL(5,2),
    p_country VARCHAR(100),
    p_startup_amount_raised DECIMAL(15,2)
) RETURNS INTEGER AS $$
DECLARE
    offer_id INTEGER;
    scouting_fee DECIMAL(15,2);
    investor_id UUID;
    investor_has_advisor BOOLEAN := FALSE;
    startup_has_advisor BOOLEAN := FALSE;
    initial_status TEXT;
    investor_advisor_status TEXT;
    startup_advisor_status TEXT;
BEGIN
    -- Get investor ID
    SELECT id INTO investor_id FROM public.users WHERE email = p_investor_email;
    
    -- Check if investor has an advisor
    SELECT (investment_advisor_code_entered IS NOT NULL) INTO investor_has_advisor
    FROM public.users WHERE id = investor_id;
    
    -- Check if startup has an advisor
    SELECT (investment_advisor_code IS NOT NULL) INTO startup_has_advisor
    FROM public.startups WHERE id = p_startup_id;
    
    -- Calculate startup scouting fee
    SELECT startup_fee INTO scouting_fee
    FROM calculate_scouting_fee(p_country, 'Investor', p_offer_amount)
    LIMIT 1;
    
    -- Determine initial status and advisor approval requirements
    IF investor_has_advisor AND startup_has_advisor THEN
        initial_status := 'pending_investor_advisor_approval';
        investor_advisor_status := 'pending';
        startup_advisor_status := 'pending';
    ELSIF investor_has_advisor THEN
        initial_status := 'pending_investor_advisor_approval';
        investor_advisor_status := 'pending';
        startup_advisor_status := 'not_required';
    ELSIF startup_has_advisor THEN
        initial_status := 'pending_startup_advisor_approval';
        investor_advisor_status := 'not_required';
        startup_advisor_status := 'pending';
    ELSE
        initial_status := 'pending';
        investor_advisor_status := 'not_required';
        startup_advisor_status := 'not_required';
    END IF;
    
    -- Create the investment offer
    INSERT INTO public.investment_offers (
        investor_email,
        startup_name,
        startup_id,
        investor_id,
        offer_amount,
        equity_percentage,
        status,
        startup_scouting_fee_paid,
        startup_scouting_fee_amount,
        startup_payment_id,
        investor_advisor_approval_status,
        startup_advisor_approval_status
    ) VALUES (
        p_investor_email,
        p_startup_name,
        p_startup_id,
        investor_id,
        p_offer_amount,
        p_equity_percentage,
        initial_status,
        TRUE,
        scouting_fee,
        'payment_' || extract(epoch from now())::text,
        investor_advisor_status,
        startup_advisor_status
    ) RETURNING id INTO offer_id;
    
    -- Log the activity
    INSERT INTO public.investment_ledger (offer_id, activity_type, amount, description)
    VALUES (offer_id, 'offer_made', p_offer_amount, 'Investment offer made');
    
    IF scouting_fee > 0 THEN
        INSERT INTO public.investment_ledger (offer_id, activity_type, amount, description)
        VALUES (offer_id, 'startup_fee_paid', scouting_fee, 'Startup scouting fee paid by investor');
    END IF;
    
    RETURN offer_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to accept investment offer with investor scouting fee
CREATE OR REPLACE FUNCTION accept_investment_offer_with_fee(
    p_offer_id INTEGER,
    p_country VARCHAR(100),
    p_startup_amount_raised DECIMAL(15,2)
) RETURNS BOOLEAN AS $$
DECLARE
    offer_record RECORD;
    investor_fee DECIMAL(15,2);
    has_advisor BOOLEAN := false;
BEGIN
    -- Get the offer details
    SELECT * INTO offer_record FROM public.investment_offers WHERE id = p_offer_id;
    
    IF NOT FOUND THEN
        RETURN false;
    END IF;
    
    -- Check if either startup or investor has an investment advisor
    SELECT EXISTS(
        SELECT 1 FROM public.users u1 
        JOIN public.startups s ON s.user_id = u1.id 
        WHERE s.id = offer_record.startup_id 
        AND u1.investment_advisor_code IS NOT NULL
    ) OR EXISTS(
        SELECT 1 FROM public.users u2 
        WHERE u2.email = offer_record.investor_email 
        AND u2.investment_advisor_code IS NOT NULL
    ) INTO has_advisor;
    
    -- Calculate investor scouting fee
    SELECT investor_fee INTO investor_fee
    FROM calculate_scouting_fee(p_country, 'Startup', offer_record.offer_amount)
    LIMIT 1;
    
    -- Update the offer
    UPDATE public.investment_offers 
    SET status = 'accepted',
        investor_scouting_fee_paid = TRUE,
        investor_scouting_fee_amount = investor_fee,
        investor_payment_id = 'payment_' || extract(epoch from now())::text,
        contact_details_revealed = NOT has_advisor,
        contact_details_revealed_at = CASE WHEN NOT has_advisor THEN NOW() ELSE NULL END
    WHERE id = p_offer_id;
    
    -- Log the activities
    INSERT INTO public.investment_ledger (offer_id, activity_type, amount, description)
    VALUES (p_offer_id, 'offer_accepted', offer_record.offer_amount, 'Investment offer accepted by startup');
    
    IF investor_fee > 0 THEN
        INSERT INTO public.investment_ledger (offer_id, activity_type, amount, description)
        VALUES (p_offer_id, 'investor_fee_paid', investor_fee, 'Investor scouting fee paid by startup');
    END IF;
    
    IF NOT has_advisor THEN
        INSERT INTO public.investment_ledger (offer_id, activity_type, description)
        VALUES (p_offer_id, 'contact_revealed', 'Contact details revealed to both parties');
    END IF;
    
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to reveal contact details (for investment advisors)
CREATE OR REPLACE FUNCTION reveal_contact_details(p_offer_id INTEGER) RETURNS BOOLEAN AS $$
BEGIN
    UPDATE public.investment_offers 
    SET contact_details_revealed = true,
        contact_details_revealed_at = NOW()
    WHERE id = p_offer_id;
    
    INSERT INTO public.investment_ledger (offer_id, activity_type, description)
    VALUES (p_offer_id, 'contact_revealed', 'Contact details revealed by investment advisor');
    
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 14. Insert default scouting fee configurations (if not already done)
INSERT INTO public.scouting_fee_configurations (country, user_type, amount_raised_min, amount_raised_max, startup_scouting_fee_percentage, investor_scouting_fee_percentage)
VALUES 
    ('Global', 'Investor', 0, 100000, 2.0, 1.0),
    ('Global', 'Investor', 100000, 500000, 1.5, 0.8),
    ('Global', 'Investor', 500000, 1000000, 1.0, 0.5),
    ('Global', 'Investor', 1000000, NULL, 0.5, 0.3),
    ('Global', 'Startup', 0, 100000, 1.0, 2.0),
    ('Global', 'Startup', 100000, 500000, 0.8, 1.5),
    ('Global', 'Startup', 500000, 1000000, 0.5, 1.0),
    ('Global', 'Startup', 1000000, NULL, 0.3, 0.5)
ON CONFLICT (country, user_type, amount_raised_min, amount_raised_max) DO NOTHING;

-- 15. Grant permissions (if not already done)
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.scouting_fee_configurations TO authenticated;
GRANT ALL ON public.payment_records TO authenticated;
GRANT ALL ON public.contact_details_access TO authenticated;
GRANT ALL ON public.investment_ledger TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_scouting_fee(TEXT, TEXT, DECIMAL) TO authenticated;
GRANT EXECUTE ON FUNCTION should_reveal_contact_details(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_offers_for_investment_advisor(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_investment_offer_with_fee(VARCHAR, VARCHAR, INTEGER, DECIMAL, DECIMAL, VARCHAR, DECIMAL) TO authenticated;
GRANT EXECUTE ON FUNCTION accept_investment_offer_with_fee(INTEGER, VARCHAR, DECIMAL) TO authenticated;
GRANT EXECUTE ON FUNCTION reveal_contact_details(INTEGER) TO authenticated;

-- Function to approve/reject offer by investor advisor
CREATE OR REPLACE FUNCTION approve_investor_advisor_offer(
    p_offer_id INTEGER,
    p_approval_action TEXT -- 'approve' or 'reject'
) RETURNS BOOLEAN AS $$
DECLARE
    offer_record RECORD;
    new_status TEXT;
BEGIN
    -- Get offer details
    SELECT * INTO offer_record FROM public.investment_offers WHERE id = p_offer_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Offer not found';
    END IF;
    
    -- Check if investor advisor approval is required and pending
    IF offer_record.investor_advisor_approval_status != 'pending' THEN
        RAISE EXCEPTION 'Investor advisor approval not required or already processed';
    END IF;
    
    -- Determine new status based on action and startup advisor requirement
    IF p_approval_action = 'approve' THEN
        IF offer_record.startup_advisor_approval_status = 'pending' THEN
            new_status := 'pending_startup_advisor_approval';
        ELSE
            new_status := 'pending';
        END IF;
        
        -- Update offer
        UPDATE public.investment_offers 
        SET 
            status = new_status,
            investor_advisor_approval_status = 'approved',
            investor_advisor_approval_at = NOW()
        WHERE id = p_offer_id;
        
        -- Log activity
        INSERT INTO public.investment_ledger (offer_id, activity_type, amount, description)
        VALUES (p_offer_id, 'investor_advisor_approved', offer_record.offer_amount, 'Offer approved by investor advisor');
        
    ELSIF p_approval_action = 'reject' THEN
        -- Update offer
        UPDATE public.investment_offers 
        SET 
            status = 'investor_advisor_rejected',
            investor_advisor_approval_status = 'rejected',
            investor_advisor_approval_at = NOW()
        WHERE id = p_offer_id;
        
        -- Log activity
        INSERT INTO public.investment_ledger (offer_id, activity_type, amount, description)
        VALUES (p_offer_id, 'investor_advisor_rejected', offer_record.offer_amount, 'Offer rejected by investor advisor');
        
    ELSE
        RAISE EXCEPTION 'Invalid approval action. Must be "approve" or "reject"';
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to approve/reject offer by startup advisor
CREATE OR REPLACE FUNCTION approve_startup_advisor_offer(
    p_offer_id INTEGER,
    p_approval_action TEXT -- 'approve' or 'reject'
) RETURNS BOOLEAN AS $$
DECLARE
    offer_record RECORD;
BEGIN
    -- Get offer details
    SELECT * INTO offer_record FROM public.investment_offers WHERE id = p_offer_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Offer not found';
    END IF;
    
    -- Check if startup advisor approval is required and pending
    IF offer_record.startup_advisor_approval_status != 'pending' THEN
        RAISE EXCEPTION 'Startup advisor approval not required or already processed';
    END IF;
    
    -- Determine new status based on action
    IF p_approval_action = 'approve' THEN
        -- Update offer
        UPDATE public.investment_offers 
        SET 
            status = 'pending',
            startup_advisor_approval_status = 'approved',
            startup_advisor_approval_at = NOW()
        WHERE id = p_offer_id;
        
        -- Log activity
        INSERT INTO public.investment_ledger (offer_id, activity_type, amount, description)
        VALUES (p_offer_id, 'startup_advisor_approved', offer_record.offer_amount, 'Offer approved by startup advisor');
        
    ELSIF p_approval_action = 'reject' THEN
        -- Update offer
        UPDATE public.investment_offers 
        SET 
            status = 'startup_advisor_rejected',
            startup_advisor_approval_status = 'rejected',
            startup_advisor_approval_at = NOW()
        WHERE id = p_offer_id;
        
        -- Log activity
        INSERT INTO public.investment_ledger (offer_id, activity_type, amount, description)
        VALUES (p_offer_id, 'startup_advisor_rejected', offer_record.offer_amount, 'Offer rejected by startup advisor');
        
    ELSE
        RAISE EXCEPTION 'Invalid approval action. Must be "approve" or "reject"';
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions for new functions
GRANT EXECUTE ON FUNCTION approve_investor_advisor_offer(INTEGER, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION approve_startup_advisor_offer(INTEGER, TEXT) TO authenticated;

-- Create co-investment recommendations table
CREATE TABLE IF NOT EXISTS public.co_investment_recommendations (
    id SERIAL PRIMARY KEY,
    investment_opportunity_id INTEGER NOT NULL,
    advisor_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    investor_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    recommended_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'viewed', 'interested', 'not_interested')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(investment_opportunity_id, advisor_id, investor_id)
);

-- Enable RLS on co-investment recommendations
ALTER TABLE public.co_investment_recommendations ENABLE ROW LEVEL SECURITY;

-- Create policies for co-investment recommendations
CREATE POLICY co_investment_rec_select_own ON public.co_investment_recommendations 
FOR SELECT TO authenticated USING (
    investor_id = auth.uid() OR 
    advisor_id = auth.uid() OR
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() AND role = 'Admin'
    )
);

CREATE POLICY co_investment_rec_insert_advisor ON public.co_investment_recommendations 
FOR INSERT TO authenticated WITH CHECK (
    advisor_id = auth.uid() AND
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() AND role = 'Investment Advisor'
    )
);

CREATE POLICY co_investment_rec_update_investor ON public.co_investment_recommendations 
FOR UPDATE TO authenticated USING (
    investor_id = auth.uid()
);

CREATE POLICY co_investment_rec_admin_all ON public.co_investment_recommendations 
FOR ALL TO authenticated USING (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() AND role = 'Admin'
    )
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_co_investment_rec_advisor_id ON public.co_investment_recommendations(advisor_id);
CREATE INDEX IF NOT EXISTS idx_co_investment_rec_investor_id ON public.co_investment_recommendations(investor_id);
CREATE INDEX IF NOT EXISTS idx_co_investment_rec_opportunity_id ON public.co_investment_recommendations(investment_opportunity_id);
CREATE INDEX IF NOT EXISTS idx_co_investment_rec_status ON public.co_investment_recommendations(status);

-- Function to recommend co-investment opportunity to investors
CREATE OR REPLACE FUNCTION recommend_co_investment_opportunity(
    p_opportunity_id INTEGER,
    p_advisor_id UUID,
    p_investor_ids UUID[]
) RETURNS INTEGER AS $$
DECLARE
    recommendation_count INTEGER := 0;
    investor_id UUID;
BEGIN
    -- Loop through each investor ID and create recommendations
    FOREACH investor_id IN ARRAY p_investor_ids
    LOOP
        -- Insert recommendation (ON CONFLICT DO NOTHING to avoid duplicates)
        INSERT INTO public.co_investment_recommendations (
            investment_opportunity_id,
            advisor_id,
            investor_id
        ) VALUES (
            p_opportunity_id,
            p_advisor_id,
            investor_id
        ) ON CONFLICT (investment_opportunity_id, advisor_id, investor_id) DO NOTHING;
        
        -- Count successful insertions
        IF FOUND THEN
            recommendation_count := recommendation_count + 1;
        END IF;
    END LOOP;
    
    RETURN recommendation_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get recommended co-investment opportunities for an investor
CREATE OR REPLACE FUNCTION get_recommended_co_investment_opportunities(
    p_investor_id UUID
) RETURNS TABLE (
    recommendation_id INTEGER,
    opportunity_id INTEGER,
    startup_name TEXT,
    sector TEXT,
    investment_amount DECIMAL(15,2),
    equity_percentage DECIMAL(5,2),
    lead_investor TEXT,
    compliance_status TEXT,
    recommended_at TIMESTAMP WITH TIME ZONE,
    recommendation_status TEXT,
    advisor_name TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cir.id as recommendation_id,
        cir.investment_opportunity_id as opportunity_id,
        io.name as startup_name,
        io.sector,
        io.investment_value as investment_amount,
        io.equity_allocation as equity_percentage,
        'Lead Investor Name' as lead_investor, -- TODO: Get actual lead investor
        io.compliance_status,
        cir.recommended_at,
        cir.status as recommendation_status,
        COALESCE(u.name, u.email) as advisor_name
    FROM public.co_investment_recommendations cir
    JOIN public.new_investments io ON cir.investment_opportunity_id = io.id
    JOIN public.users u ON cir.advisor_id = u.id
    WHERE cir.investor_id = p_investor_id
    ORDER BY cir.recommended_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update recommendation status
CREATE OR REPLACE FUNCTION update_co_investment_recommendation_status(
    p_recommendation_id INTEGER,
    p_status TEXT
) RETURNS BOOLEAN AS $$
BEGIN
    UPDATE public.co_investment_recommendations 
    SET 
        status = p_status,
        updated_at = NOW()
    WHERE id = p_recommendation_id;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions for co-investment functions
GRANT EXECUTE ON FUNCTION recommend_co_investment_opportunity(INTEGER, UUID, UUID[]) TO authenticated;
GRANT EXECUTE ON FUNCTION get_recommended_co_investment_opportunities(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_co_investment_recommendation_status(INTEGER, TEXT) TO authenticated;