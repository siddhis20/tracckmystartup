# Compliance System Diagnostic Guide

## Current Issue
The Compliance tab is not showing tasks even after selecting country and company type in the profile.

## Step-by-Step Diagnosis

### 1. First, run this diagnostic SQL in Supabase SQL Editor:

```sql
-- Check if compliance_rules table exists and has data
SELECT 'compliance_rules table:' as test;
SELECT country_code, rules FROM compliance_rules ORDER BY country_code;

-- Check if the RPC function exists
SELECT 'RPC function exists:' as test;
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_name = 'generate_compliance_tasks_for_startup';

-- Check startup profile data
SELECT 'Startup profile data:' as test;
SELECT id, name, country_of_registration, company_type, registration_date 
FROM startups 
ORDER BY id;

-- Check subsidiaries data
SELECT 'Subsidiaries data:' as test;
SELECT id, startup_id, country, company_type, registration_date 
FROM subsidiaries 
ORDER BY startup_id, id;

-- Check international operations data
SELECT 'International operations data:' as test;
SELECT id, startup_id, country, company_type, start_date 
FROM international_ops 
ORDER BY startup_id, id;
```

### 2. If the RPC function doesn't exist, run this SQL:

```sql
-- Helper: normalize textual country to rule country_code
CREATE OR REPLACE FUNCTION normalize_country_code(country_text text)
RETURNS text
LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE
    WHEN country_text IS NULL OR trim(country_text) = '' THEN 'default'
    WHEN lower(country_text) IN ('in','india') THEN 'IN'
    WHEN lower(country_text) IN ('us','usa','united states','united states of america') THEN 'US'
    WHEN lower(country_text) IN ('uk','united kingdom','great britain','england') THEN 'UK'
    ELSE 'default'
  END
$$;

-- Main generator
DROP FUNCTION IF EXISTS generate_compliance_tasks_for_startup(integer);
CREATE OR REPLACE FUNCTION generate_compliance_tasks_for_startup(startup_id_param integer)
RETURNS TABLE (
  task_id text,
  entity_identifier text,
  entity_display_name text,
  year integer,
  task_name text,
  ca_required boolean,
  cs_required boolean,
  task_type text
) AS $$
DECLARE
  s_country text;
  s_company_type text;
  s_reg_date date;
  current_year integer := EXTRACT(YEAR FROM CURRENT_DATE);
  reg_year integer;
  rules_json jsonb;
  rule_set jsonb;
  r jsonb;
  sub_rec record;
  intl_rec record;
  sub_index integer := 0;
  intl_index integer := 0;
BEGIN
  -- Parent company profile
  SELECT country_of_registration, company_type, registration_date
  INTO s_country, s_company_type, s_reg_date
  FROM startups
  WHERE id = startup_id_param;

  IF s_reg_date IS NOT NULL THEN
    reg_year := EXTRACT(YEAR FROM s_reg_date);

    SELECT c.rules INTO rules_json
    FROM compliance_rules c
    WHERE c.country_code = normalize_country_code(s_country)
    LIMIT 1;

    IF rules_json IS NULL THEN
      SELECT c.rules INTO rules_json
      FROM compliance_rules c
      WHERE c.country_code = 'default'
      LIMIT 1;
    END IF;

    rule_set := COALESCE(rules_json -> s_company_type, rules_json -> 'default');

    IF rule_set IS NOT NULL AND jsonb_typeof(rule_set) = 'object' THEN
      FOR y IN reg_year..current_year LOOP
        IF y = reg_year THEN
          FOR r IN SELECT jsonb_array_elements(COALESCE(rule_set -> 'firstYear', '[]'::jsonb)) LOOP
            year := y;
            task_id := 'parent-' || y || '-fy-' || (r ->> 'id');
            entity_identifier := 'parent';
            entity_display_name := 'Parent Company (' || s_country || ')';
            task_name := r ->> 'name';
            ca_required := COALESCE((r ->> 'caRequired')::boolean, false);
            cs_required := COALESCE((r ->> 'csRequired')::boolean, false);
            task_type := 'firstYear';
            RETURN NEXT;
          END LOOP;
        END IF;

        FOR r IN SELECT jsonb_array_elements(COALESCE(rule_set -> 'annual', '[]'::jsonb)) LOOP
          year := y;
          task_id := 'parent-' || y || '-an-' || (r ->> 'id');
          entity_identifier := 'parent';
          entity_display_name := 'Parent Company (' || s_country || ')';
          task_name := r ->> 'name';
          ca_required := COALESCE((r ->> 'caRequired')::boolean, false);
          cs_required := COALESCE((r ->> 'csRequired')::boolean, false);
          task_type := 'annual';
          RETURN NEXT;
        END LOOP;
      END LOOP;
    END IF;
  END IF;

  -- Subsidiaries for this startup
  FOR sub_rec IN
    SELECT id, country, company_type, registration_date
    FROM subsidiaries
    WHERE startup_id = startup_id_param
    ORDER BY id
  LOOP
    sub_index := sub_index + 1;
    IF sub_rec.registration_date IS NULL THEN CONTINUE; END IF;

    reg_year := EXTRACT(YEAR FROM sub_rec.registration_date);

    SELECT c.rules INTO rules_json
    FROM compliance_rules c
    WHERE c.country_code = normalize_country_code(sub_rec.country)
    LIMIT 1;

    IF rules_json IS NULL THEN
      SELECT c.rules INTO rules_json
      FROM compliance_rules c
      WHERE c.country_code = 'default'
      LIMIT 1;
    END IF;

    rule_set := COALESCE(rules_json -> sub_rec.company_type, rules_json -> 'default');

    IF rule_set IS NULL OR jsonb_typeof(rule_set) <> 'object' THEN
      CONTINUE;
    END IF;

    FOR y IN reg_year..current_year LOOP
      IF y = reg_year THEN
        FOR r IN SELECT jsonb_array_elements(COALESCE(rule_set -> 'firstYear', '[]'::jsonb)) LOOP
          year := y;
          task_id := 'sub-' || (sub_index - 1) || '-' || y || '-fy-' || (r ->> 'id');
          entity_identifier := 'sub-' || (sub_index - 1);
          entity_display_name := 'Subsidiary ' || sub_index || ' (' || sub_rec.country || ')';
          task_name := r ->> 'name';
          ca_required := COALESCE((r ->> 'caRequired')::boolean, false);
          cs_required := COALESCE((r ->> 'csRequired')::boolean, false);
          task_type := 'firstYear';
          RETURN NEXT;
        END LOOP;
      END IF;

      FOR r IN SELECT jsonb_array_elements(COALESCE(rule_set -> 'annual', '[]'::jsonb)) LOOP
        year := y;
        task_id := 'sub-' || (sub_index - 1) || '-' || y || '-an-' || (r ->> 'id');
        entity_identifier := 'sub-' || (sub_index - 1);
        entity_display_name := 'Subsidiary ' || sub_index || ' (' || sub_rec.country || ')';
        task_name := r ->> 'name';
        ca_required := COALESCE((r ->> 'caRequired')::boolean, false);
        cs_required := COALESCE((r ->> 'csRequired')::boolean, false);
        task_type := 'annual';
        RETURN NEXT;
      END LOOP;
    END LOOP;
  END LOOP;

  -- International Operations for this startup
  FOR intl_rec IN
    SELECT id, country, company_type, start_date
    FROM international_ops
    WHERE startup_id = startup_id_param
    ORDER BY id
  LOOP
    intl_index := intl_index + 1;
    IF intl_rec.start_date IS NULL THEN CONTINUE; END IF;

    reg_year := EXTRACT(YEAR FROM intl_rec.start_date);

    SELECT c.rules INTO rules_json
    FROM compliance_rules c
    WHERE c.country_code = normalize_country_code(intl_rec.country)
    LIMIT 1;

    IF rules_json IS NULL THEN
      SELECT c.rules INTO rules_json
      FROM compliance_rules c
      WHERE c.country_code = 'default'
      LIMIT 1;
    END IF;

    -- Use the company type from international operations, fallback to 'default'
    rule_set := COALESCE(rules_json -> intl_rec.company_type, rules_json -> 'default');

    IF rule_set IS NULL OR jsonb_typeof(rule_set) <> 'object' THEN
      CONTINUE;
    END IF;

    FOR y IN reg_year..current_year LOOP
      IF y = reg_year THEN
        FOR r IN SELECT jsonb_array_elements(COALESCE(rule_set -> 'firstYear', '[]'::jsonb)) LOOP
          year := y;
          task_id := 'intl-' || (intl_index - 1) || '-' || y || '-fy-' || (r ->> 'id');
          entity_identifier := 'intl-' || (intl_index - 1);
          entity_display_name := 'International Operation ' || intl_index || ' (' || intl_rec.country || ')';
          task_name := r ->> 'name';
          ca_required := COALESCE((r ->> 'caRequired')::boolean, false);
          cs_required := COALESCE((r ->> 'csRequired')::boolean, false);
          task_type := 'firstYear';
          RETURN NEXT;
        END LOOP;
      END IF;

      FOR r IN SELECT jsonb_array_elements(COALESCE(rule_set -> 'annual', '[]'::jsonb)) LOOP
        year := y;
        task_id := 'intl-' || (intl_index - 1) || '-' || y || '-an-' || (r ->> 'id');
        entity_identifier := 'intl-' || (intl_index - 1);
        entity_display_name := 'International Operation ' || intl_index || ' (' || intl_rec.country || ')';
        task_name := r ->> 'name';
        ca_required := COALESCE((r ->> 'caRequired')::boolean, false);
        cs_required := COALESCE((r ->> 'csRequired')::boolean, false);
        task_type := 'annual';
        RETURN NEXT;
      END LOOP;
    END LOOP;
  END LOOP;

  RETURN;
END;
$$ LANGUAGE plpgsql;
```

### 3. If no compliance rules exist, add some sample rules:

```sql
-- Add default rules if none exist
INSERT INTO compliance_rules (country_code, rules)
VALUES ('default', jsonb_build_object('default', jsonb_build_object('annual','[]'::jsonb,'firstYear','[]'::jsonb)))
ON CONFLICT (country_code) DO NOTHING;

-- Add sample rules for India
INSERT INTO compliance_rules (country_code, rules) VALUES (
  'IN',
  jsonb_build_object(
    'Private Limited',
    jsonb_build_object(
      'firstYear', jsonb_build_array(
        jsonb_build_object('id','inc-articles','name','Articles of Incorporation','caRequired',true,'csRequired',false),
        jsonb_build_object('id','inc-moa','name','Memorandum of Association','caRequired',true,'csRequired',false)
      ),
      'annual', jsonb_build_array(
        jsonb_build_object('id','annual-return','name','Annual Return Filing','caRequired',true,'csRequired',true),
        jsonb_build_object('id','audit-report','name','Audit Report','caRequired',true,'csRequired',false)
      )
    )
  )
)
ON CONFLICT (country_code) DO UPDATE SET rules = EXCLUDED.rules;
```

### 4. Test the RPC function:

```sql
-- Test with your startup ID (replace 1 with actual startup ID)
SELECT * FROM generate_compliance_tasks_for_startup(1);
```

### 5. Check the browser console:

1. Open browser DevTools (F12)
2. Go to Console tab
3. Navigate to Compliance tab
4. Look for these log messages:
   - `🔍 Generating compliance tasks from profile for startup: X`
   - `🔍 Generated compliance tasks: [...]`
   - Any error messages

## Expected Flow:

1. **Profile Tab**: Select country (e.g., "IN") and company type (e.g., "Private Limited")
2. **Save Profile**: This triggers `syncComplianceTasks`
3. **Compliance Tab**: Should show tasks like:
   - Parent Company (IN) - Articles of Incorporation
   - Parent Company (IN) - Memorandum of Association
   - Parent Company (IN) - Annual Return Filing
   - Parent Company (IN) - Audit Report

## Common Issues:

1. **No RPC function**: Run step 2 SQL
2. **No compliance rules**: Run step 3 SQL
3. **Profile not saved**: Check if country/company type are actually saved to database
4. **Wrong country format**: Make sure country matches the rules (e.g., "IN" not "India")

Run the diagnostic SQL first and let me know what you find!
