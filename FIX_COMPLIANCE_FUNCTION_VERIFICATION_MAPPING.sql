-- =====================================================
-- FIX COMPLIANCE FUNCTION VERIFICATION MAPPING
-- =====================================================
-- This script fixes the generate_compliance_tasks_for_startup function
-- to properly map verification_required field to CA/CS requirements

-- Drop the old function
DROP FUNCTION IF EXISTS generate_compliance_tasks_for_startup(integer);

-- Create the fixed function with proper verification mapping
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
  rule_rec record;
  sub_rec record;
  sub_index integer := 0;
  ca_req boolean;
  cs_req boolean;
BEGIN
  -- Parent company profile
  SELECT country_of_registration, company_type, registration_date
  INTO s_country, s_company_type, s_reg_date
  FROM startups
  WHERE id = startup_id_param;

  IF s_reg_date IS NOT NULL THEN
    reg_year := EXTRACT(YEAR FROM s_reg_date);

    -- Generate tasks for parent company using comprehensive rules
    FOR rule_rec IN
      SELECT 
        compliance_name,
        frequency,
        verification_required,
        ca_type,
        cs_type
      FROM compliance_rules_comprehensive
      WHERE country_code = s_country
        AND company_type = s_company_type
    LOOP
      -- Map verification_required to CA/CS requirements
      CASE 
        WHEN rule_rec.verification_required = 'CA' THEN
          ca_req := true;
          cs_req := false;
        WHEN rule_rec.verification_required = 'CS' THEN
          ca_req := false;
          cs_req := true;
        WHEN rule_rec.verification_required = 'both' THEN
          ca_req := true;
          cs_req := true;
        WHEN rule_rec.verification_required ILIKE '%tax advisor%' OR rule_rec.verification_required ILIKE '%auditor%' THEN
          ca_req := true;
          cs_req := false;
        WHEN rule_rec.verification_required ILIKE '%management%' OR rule_rec.verification_required ILIKE '%lawyer%' THEN
          ca_req := false;
          cs_req := true;
        ELSE
          ca_req := true;
          cs_req := true;
      END CASE;

      -- Generate tasks for each year from registration to current
      FOR y IN reg_year..current_year LOOP
        year := y;
        task_id := 'parent-' || y || '-' || rule_rec.frequency || '-' || rule_rec.compliance_name;
        entity_identifier := 'parent';
        entity_display_name := 'Parent Company (' || s_country || ')';
        task_name := rule_rec.compliance_name;
        ca_required := ca_req;
        cs_required := cs_req;
        task_type := rule_rec.frequency;
        RETURN NEXT;
      END LOOP;
    END LOOP;
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

    -- Generate tasks for this subsidiary using comprehensive rules
    FOR rule_rec IN
      SELECT 
        compliance_name,
        frequency,
        verification_required,
        ca_type,
        cs_type
      FROM compliance_rules_comprehensive
      WHERE country_code = sub_rec.country
        AND company_type = sub_rec.company_type
    LOOP
      -- Map verification_required to CA/CS requirements
      CASE 
        WHEN rule_rec.verification_required = 'CA' THEN
          ca_req := true;
          cs_req := false;
        WHEN rule_rec.verification_required = 'CS' THEN
          ca_req := false;
          cs_req := true;
        WHEN rule_rec.verification_required = 'both' THEN
          ca_req := true;
          cs_req := true;
        WHEN rule_rec.verification_required ILIKE '%tax advisor%' OR rule_rec.verification_required ILIKE '%auditor%' THEN
          ca_req := true;
          cs_req := false;
        WHEN rule_rec.verification_required ILIKE '%management%' OR rule_rec.verification_required ILIKE '%lawyer%' THEN
          ca_req := false;
          cs_req := true;
        ELSE
          ca_req := true;
          cs_req := true;
      END CASE;

      -- Generate tasks for each year from registration to current
      FOR y IN reg_year..current_year LOOP
        year := y;
        task_id := 'sub-' || (sub_index - 1) || '-' || y || '-' || rule_rec.frequency || '-' || rule_rec.compliance_name;
        entity_identifier := 'sub-' || (sub_index - 1);
        entity_display_name := 'Subsidiary ' || sub_index || ' (' || sub_rec.country || ')';
        task_name := rule_rec.compliance_name;
        ca_required := ca_req;
        cs_required := cs_req;
        task_type := rule_rec.frequency;
        RETURN NEXT;
      END LOOP;
    END LOOP;
  END LOOP;

  RETURN;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TEST THE FIXED FUNCTION
-- =====================================================

-- Test the function for startup ID 41
SELECT * FROM generate_compliance_tasks_for_startup(41);
