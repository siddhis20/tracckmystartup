-- Allow facilitators to request diligence before application acceptance
-- Safe to run multiple times

-- Recreate request_diligence to remove dependency on application.status = 'accepted'
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc WHERE proname = 'request_diligence'
  ) THEN
    DROP FUNCTION IF EXISTS request_diligence(UUID);
  END IF;
END $$;

CREATE OR REPLACE FUNCTION request_diligence(
  p_application_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_facilitator_id UUID;
  v_opportunity_id UUID;
  v_updated INT;
BEGIN
  -- Verify caller is the facilitator who owns the linked opportunity
  SELECT io.facilitator_id, io.id
  INTO v_facilitator_id, v_opportunity_id
  FROM opportunity_applications oa
  JOIN incubation_opportunities io ON io.id = oa.opportunity_id
  WHERE oa.id = p_application_id;

  IF v_facilitator_id IS NULL THEN
    RAISE EXCEPTION 'Application not found: %', p_application_id;
  END IF;

  IF v_facilitator_id <> auth.uid() THEN
    RAISE EXCEPTION 'Not authorized to request diligence for this application';
  END IF;

  -- Set diligence_status to requested regardless of current application status
  UPDATE opportunity_applications
  SET diligence_status = 'requested', updated_at = NOW()
  WHERE id = p_application_id
    AND (diligence_status IS NULL OR diligence_status = 'none');

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  RETURN v_updated > 0;
END;
$$;

GRANT EXECUTE ON FUNCTION request_diligence(UUID) TO authenticated;


