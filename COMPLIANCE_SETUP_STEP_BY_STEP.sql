-- =====================================================
-- COMPLIANCE SETUP - STEP BY STEP (SAFE VERSION)
-- =====================================================
-- Run each section separately to avoid deadlocks
-- =====================================================

-- STEP 1: Create Tables (Run this first)
-- =====================================================

-- Create compliance_checks table
CREATE TABLE IF NOT EXISTS public.compliance_checks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    startup_id INTEGER NOT NULL REFERENCES public.startups(id) ON DELETE CASCADE,
    task_id TEXT NOT NULL,
    entity_identifier TEXT NOT NULL,
    entity_display_name TEXT NOT NULL,
    year INTEGER NOT NULL,
    task_name TEXT NOT NULL,
    ca_required BOOLEAN DEFAULT false,
    cs_required BOOLEAN DEFAULT false,
    ca_status TEXT DEFAULT 'Pending' CHECK (ca_status IN ('Pending', 'Verified', 'Rejected', 'Not Required')),
    cs_status TEXT DEFAULT 'Pending' CHECK (cs_status IN ('Pending', 'Verified', 'Rejected', 'Not Required')),
    ca_updated_by TEXT,
    cs_updated_by TEXT,
    ca_updated_at TIMESTAMP WITH TIME ZONE,
    cs_updated_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(startup_id, task_id)
);

-- Create compliance_uploads table
CREATE TABLE IF NOT EXISTS public.compliance_uploads (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    startup_id INTEGER NOT NULL REFERENCES public.startups(id) ON DELETE CASCADE,
    task_id TEXT NOT NULL,
    file_name TEXT NOT NULL,
    file_url TEXT NOT NULL,
    uploaded_by TEXT NOT NULL,
    file_size INTEGER NOT NULL,
    file_type TEXT NOT NULL,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_compliance_checks_startup_id ON public.compliance_checks(startup_id);
CREATE INDEX IF NOT EXISTS idx_compliance_checks_task_id ON public.compliance_checks(task_id);
CREATE INDEX IF NOT EXISTS idx_compliance_checks_year ON public.compliance_checks(year);
CREATE INDEX IF NOT EXISTS idx_compliance_checks_entity ON public.compliance_checks(entity_identifier);

CREATE INDEX IF NOT EXISTS idx_compliance_uploads_startup_id ON public.compliance_uploads(startup_id);
CREATE INDEX IF NOT EXISTS idx_compliance_uploads_task_id ON public.compliance_uploads(task_id);
CREATE INDEX IF NOT EXISTS idx_compliance_uploads_uploaded_at ON public.compliance_uploads(uploaded_at);

-- Enable RLS
ALTER TABLE public.compliance_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.compliance_uploads ENABLE ROW LEVEL SECURITY;

-- Grant permissions
GRANT ALL ON public.compliance_checks TO authenticated;
GRANT ALL ON public.compliance_uploads TO authenticated;

-- =====================================================
-- STEP 2: Create Storage Bucket (Run this second)
-- =====================================================

-- Create storage bucket for compliance documents
INSERT INTO storage.buckets (id, name, public) 
VALUES ('compliance-documents', 'compliance-documents', true)
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- STEP 3: Create RLS Policies (Run this third)
-- =====================================================

-- Drop existing policies safely
DO $$ 
BEGIN
    -- Drop compliance_checks policies
    DROP POLICY IF EXISTS "Startups can view their own compliance checks" ON public.compliance_checks;
    DROP POLICY IF EXISTS "Startups can update their own compliance checks" ON public.compliance_checks;
    DROP POLICY IF EXISTS "CA/CS users can view all compliance checks" ON public.compliance_checks;
    DROP POLICY IF EXISTS "CA/CS users can update compliance checks" ON public.compliance_checks;
    DROP POLICY IF EXISTS "Admins can view all compliance checks" ON public.compliance_checks;
    
    -- Drop compliance_uploads policies
    DROP POLICY IF EXISTS "Startups can view their own uploads" ON public.compliance_uploads;
    DROP POLICY IF EXISTS "Startups can insert their own uploads" ON public.compliance_uploads;
    DROP POLICY IF EXISTS "Startups can delete their own uploads" ON public.compliance_uploads;
    DROP POLICY IF EXISTS "CA/CS users can view all uploads" ON public.compliance_uploads;
    DROP POLICY IF EXISTS "Admins can manage all uploads" ON public.compliance_uploads;
    
    -- Drop storage policies
    DROP POLICY IF EXISTS "Startups can upload their own compliance documents" ON storage.objects;
    DROP POLICY IF EXISTS "Startups can view their own compliance documents" ON storage.objects;
    DROP POLICY IF EXISTS "CA/CS users can view all compliance documents" ON storage.objects;
    DROP POLICY IF EXISTS "Admins can manage all compliance documents" ON storage.objects;
END $$;

-- Create RLS policies for compliance_checks
CREATE POLICY "Startups can view their own compliance checks" ON public.compliance_checks
    FOR SELECT USING (
        startup_id IN (
            SELECT id FROM public.startups 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Startups can update their own compliance checks" ON public.compliance_checks
    FOR UPDATE USING (
        startup_id IN (
            SELECT id FROM public.startups 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "CA/CS users can view all compliance checks" ON public.compliance_checks
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role IN ('CA', 'CS')
        )
    );

CREATE POLICY "CA/CS users can update compliance checks" ON public.compliance_checks
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role IN ('CA', 'CS')
        )
    );

CREATE POLICY "Admins can view all compliance checks" ON public.compliance_checks
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role = 'Admin'
        )
    );

-- Create RLS policies for compliance_uploads
CREATE POLICY "Startups can view their own uploads" ON public.compliance_uploads
    FOR SELECT USING (
        startup_id IN (
            SELECT id FROM public.startups 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Startups can insert their own uploads" ON public.compliance_uploads
    FOR INSERT WITH CHECK (
        startup_id IN (
            SELECT id FROM public.startups 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Startups can delete their own uploads" ON public.compliance_uploads
    FOR DELETE USING (
        startup_id IN (
            SELECT id FROM public.startups 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "CA/CS users can view all uploads" ON public.compliance_uploads
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role IN ('CA', 'CS')
        )
    );

CREATE POLICY "Admins can manage all uploads" ON public.compliance_uploads
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role = 'Admin'
        )
    );

-- Create storage policies for compliance documents
CREATE POLICY "Startups can upload their own compliance documents" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'compliance-documents' AND
        (storage.foldername(name))[1]::integer IN (
            SELECT id FROM public.startups 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Startups can view their own compliance documents" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'compliance-documents' AND
        (storage.foldername(name))[1]::integer IN (
            SELECT id FROM public.startups 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "CA/CS users can view all compliance documents" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'compliance-documents' AND
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role IN ('CA', 'CS')
        )
    );

CREATE POLICY "Admins can manage all compliance documents" ON storage.objects
    FOR ALL USING (
        bucket_id = 'compliance-documents' AND
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role = 'Admin'
        )
    );

-- =====================================================
-- STEP 4: Create Functions (Run this fourth)
-- =====================================================

-- Drop existing functions safely
DROP FUNCTION IF EXISTS public.create_compliance_tasks() CASCADE;
DROP FUNCTION IF EXISTS public.update_subsidiary_compliance_tasks() CASCADE;

-- Create function to automatically create compliance tasks when profile is updated
CREATE OR REPLACE FUNCTION public.create_compliance_tasks()
RETURNS TRIGGER AS $$
DECLARE
    profile_data RECORD;
    current_year INTEGER;
    registration_year INTEGER;
    task_id TEXT;
    entity_identifier TEXT;
    entity_display_name TEXT;
BEGIN
    -- Get current year
    current_year := EXTRACT(YEAR FROM NOW());
    
    -- Get profile data
    SELECT * INTO profile_data FROM public.startups WHERE id = NEW.id;
    
    IF profile_data IS NULL THEN
        RETURN NEW;
    END IF;
    
    -- Get registration year
    registration_year := EXTRACT(YEAR FROM profile_data.registration_date::date);
    
    -- Create tasks for parent company
    entity_identifier := 'parent';
    entity_display_name := 'Parent Company (' || profile_data.country || ')';
    
    -- Create annual tasks for each year from registration to current
    FOR year IN registration_year..current_year LOOP
        -- Annual Report task
        task_id := entity_identifier || '-' || year || '-an-annual_report';
        INSERT INTO public.compliance_checks (
            startup_id, task_id, entity_identifier, entity_display_name, 
            year, task_name, ca_required, cs_required
        ) VALUES (
            NEW.id, task_id, entity_identifier, entity_display_name,
            year, 'Annual Report', true, false
        ) ON CONFLICT (startup_id, task_id) DO NOTHING;
        
        -- Board Meeting Minutes task
        task_id := entity_identifier || '-' || year || '-an-board_minutes';
        INSERT INTO public.compliance_checks (
            startup_id, task_id, entity_identifier, entity_display_name, 
            year, task_name, ca_required, cs_required
        ) VALUES (
            NEW.id, task_id, entity_identifier, entity_display_name,
            year, 'Board Meeting Minutes', false, true
        ) ON CONFLICT (startup_id, task_id) DO NOTHING;
        
        -- First year tasks (only for registration year)
        IF year = registration_year THEN
            -- Articles of Incorporation
            task_id := entity_identifier || '-' || year || '-fy-incorporation';
            INSERT INTO public.compliance_checks (
                startup_id, task_id, entity_identifier, entity_display_name, 
                year, task_name, ca_required, cs_required
            ) VALUES (
                NEW.id, task_id, entity_identifier, entity_display_name,
                year, 'Articles of Incorporation', true, false
            ) ON CONFLICT (startup_id, task_id) DO NOTHING;
        END IF;
    END LOOP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create function to update compliance tasks when subsidiaries are added/updated
CREATE OR REPLACE FUNCTION public.update_subsidiary_compliance_tasks()
RETURNS TRIGGER AS $$
DECLARE
    current_year INTEGER;
    registration_year INTEGER;
    task_id TEXT;
    entity_identifier TEXT;
    entity_display_name TEXT;
    subsidiary_index INTEGER;
BEGIN
    -- Get current year
    current_year := EXTRACT(YEAR FROM NOW());
    
    -- Get registration year
    registration_year := EXTRACT(YEAR FROM NEW.registration_date::date);
    
    -- Get subsidiary index
    SELECT COUNT(*) INTO subsidiary_index 
    FROM public.subsidiaries 
    WHERE startup_id = NEW.startup_id AND id <= NEW.id;
    
    entity_identifier := 'sub-' || (subsidiary_index - 1);
    entity_display_name := 'Subsidiary ' || subsidiary_index || ' (' || NEW.country || ')';
    
    -- Create tasks for subsidiary
    FOR year IN registration_year..current_year LOOP
        -- Annual Report task
        task_id := entity_identifier || '-' || year || '-an-annual_report';
        INSERT INTO public.compliance_checks (
            startup_id, task_id, entity_identifier, entity_display_name, 
            year, task_name, ca_required, cs_required
        ) VALUES (
            NEW.startup_id, task_id, entity_identifier, entity_display_name,
            year, 'Annual Report', true, false
        ) ON CONFLICT (startup_id, task_id) DO NOTHING;
        
        -- Board Meeting Minutes task
        task_id := entity_identifier || '-' || year || '-an-board_minutes';
        INSERT INTO public.compliance_checks (
            startup_id, task_id, entity_identifier, entity_display_name, 
            year, task_name, ca_required, cs_required
        ) VALUES (
            NEW.startup_id, task_id, entity_identifier, entity_display_name,
            year, 'Board Meeting Minutes', false, true
        ) ON CONFLICT (startup_id, task_id) DO NOTHING;
        
        -- First year tasks (only for registration year)
        IF year = registration_year THEN
            -- Articles of Incorporation
            task_id := entity_identifier || '-' || year || '-fy-incorporation';
            INSERT INTO public.compliance_checks (
                startup_id, task_id, entity_identifier, entity_display_name, 
                year, task_name, ca_required, cs_required
            ) VALUES (
                NEW.startup_id, task_id, entity_identifier, entity_display_name,
                year, 'Articles of Incorporation', true, false
            ) ON CONFLICT (startup_id, task_id) DO NOTHING;
        END IF;
    END LOOP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- STEP 5: Create Triggers (Run this last)
-- =====================================================

-- Drop existing triggers safely
DROP TRIGGER IF EXISTS trigger_create_compliance_tasks ON public.startups;
DROP TRIGGER IF EXISTS trigger_update_subsidiary_compliance_tasks ON public.subsidiaries;

-- Create trigger to automatically create compliance tasks
CREATE TRIGGER trigger_create_compliance_tasks
    AFTER INSERT OR UPDATE ON public.startups
    FOR EACH ROW
    EXECUTE FUNCTION public.create_compliance_tasks();

-- Create trigger for subsidiary compliance tasks
CREATE TRIGGER trigger_update_subsidiary_compliance_tasks
    AFTER INSERT OR UPDATE ON public.subsidiaries
    FOR EACH ROW
    EXECUTE FUNCTION public.update_subsidiary_compliance_tasks();

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Compliance database setup completed successfully!';
    RAISE NOTICE '📋 Tables created: compliance_checks, compliance_uploads';
    RAISE NOTICE '🗂️ Storage bucket created: compliance-documents';
    RAISE NOTICE '🔒 RLS policies and triggers configured';
    RAISE NOTICE '🎯 You can now refresh your application and test the compliance system!';
END $$;

