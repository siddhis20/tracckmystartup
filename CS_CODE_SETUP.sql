-- CS Code Setup: create cs_code on users, generator function, trigger, and basic assignment function

-- 1) Add cs_code column to users if missing
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'cs_code'
    ) THEN
        ALTER TABLE public.users ADD COLUMN cs_code VARCHAR(20) UNIQUE;
    END IF;
END$$;

-- 2) Generator for CS code: CS-XXXXXX
CREATE OR REPLACE FUNCTION public.generate_cs_code()
RETURNS VARCHAR(20) AS $$
DECLARE
    new_code VARCHAR(20);
BEGIN
    LOOP
        new_code := 'CS-' || upper(substring(replace(gen_random_uuid()::text,'-','') from 1 for 6));
        EXIT WHEN NOT EXISTS (SELECT 1 FROM public.users WHERE cs_code = new_code);
    END LOOP;
    RETURN new_code;
END;
$$ LANGUAGE plpgsql;

-- 3) Trigger to auto-generate cs_code when role is CS and cs_code is NULL
CREATE OR REPLACE FUNCTION public.handle_cs_code_generation()
RETURNS trigger AS $$
BEGIN
    IF NEW.role = 'CS' AND NEW.cs_code IS NULL THEN
        NEW.cs_code := public.generate_cs_code();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_generate_cs_code') THEN
        CREATE TRIGGER trigger_generate_cs_code
        BEFORE INSERT ON public.users
        FOR EACH ROW
        EXECUTE FUNCTION public.handle_cs_code_generation();
    END IF;
END$$;

-- 4) Backfill: assign codes to existing CS users
UPDATE public.users
SET cs_code = public.generate_cs_code()
WHERE role = 'CS' AND cs_code IS NULL;

-- 5) Table for CS assignments (mirrors ca_assignments)
CREATE TABLE IF NOT EXISTS public.cs_assignments (
    id BIGSERIAL PRIMARY KEY,
    cs_code VARCHAR(20) NOT NULL,
    startup_id BIGINT NOT NULL REFERENCES public.startups(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'active',
    notes TEXT,
    assignment_date TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(cs_code, startup_id)
);

CREATE INDEX IF NOT EXISTS idx_cs_assignments_code ON public.cs_assignments(cs_code);
CREATE INDEX IF NOT EXISTS idx_cs_assignments_startup ON public.cs_assignments(startup_id);

-- 6) RPC to get startups assigned to a CS
CREATE OR REPLACE FUNCTION public.get_cs_startups(cs_code_param VARCHAR(20))
RETURNS TABLE (
    startup_id BIGINT,
    startup_name TEXT,
    assignment_date TIMESTAMPTZ,
    status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT s.id, s.name, ca.assignment_date, ca.status
    FROM public.cs_assignments ca
    JOIN public.startups s ON s.id = ca.startup_id
    WHERE ca.cs_code = cs_code_param AND ca.status = 'active';
END;
$$ LANGUAGE plpgsql STABLE;

-- Optional: simple RLS allowing CS to read their assignments (requires RLS enabled as per your policy)
-- ALTER TABLE public.cs_assignments ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY cs_assignments_select ON public.cs_assignments
--     FOR SELECT USING (true);

-- 7) Quick smoke test rows (safe if duplicates)
-- INSERT INTO public.cs_assignments (cs_code, startup_id, status)
-- SELECT u.cs_code, s.id, 'active'
-- FROM public.users u CROSS JOIN LATERAL (
--   SELECT id FROM public.startups ORDER BY id LIMIT 1
-- ) s
-- WHERE u.role = 'CS' AND u.cs_code IS NOT NULL
-- ON CONFLICT (cs_code, startup_id) DO NOTHING;

-- 8) Test the RPC for any existing CS code
-- DO $$
-- DECLARE test_cs_code VARCHAR(20);
-- BEGIN
--   SELECT cs_code INTO test_cs_code FROM public.users WHERE role='CS' AND cs_code IS NOT NULL LIMIT 1;
--   IF test_cs_code IS NOT NULL THEN
--     RAISE NOTICE 'Testing get_cs_startups with CS code: %', test_cs_code;
--     PERFORM * FROM public.get_cs_startups(test_cs_code);
--   END IF;
-- END$$;



