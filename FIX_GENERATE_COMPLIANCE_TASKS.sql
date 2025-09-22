-- Fix dynamic compliance task generation to strictly follow Profile → Compliance logic
-- 1) Adds a small country normalizer
-- 2) Rewrites generate_compliance_tasks_for_startup to only emit tasks for:
--    - Parent company (using startups.country_of_registration, company_type, registration_date)
--    - Subsidiaries of that startup (country, company_type, registration_date)
-- 3) Uses compliance_rules table with fallbacks to 'default'

-- No normalization needed - admin dashboard controls country codes directly

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
    WHERE c.country_code = s_country
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
    WHERE c.country_code = sub_rec.country
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
    WHERE c.country_code = intl_rec.country
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

-- Optional: quick resync for a given startup (replace :sid)
-- DELETE FROM compliance_checks WHERE startup_id = :sid;
-- INSERT INTO compliance_checks (
--   startup_id, task_id, entity_identifier, entity_display_name, year, task_name,
--   ca_required, cs_required, task_type, ca_status, cs_status
-- )
-- SELECT :sid, t.task_id, t.entity_identifier, t.entity_display_name, t.year, t.task_name,
--        t.ca_required, t.cs_required, t.task_type, 'pending', 'pending'
-- FROM generate_compliance_tasks_for_startup(:sid) t;


