-- Add status column to recognition_records table
-- This will allow facilitators to approve/reject recognition requests

-- Add status column with default value 'pending'
ALTER TABLE public.recognition_records 
ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'pending';

-- Update existing records to have 'pending' status if they don't have one
UPDATE public.recognition_records 
SET status = 'pending' 
WHERE status IS NULL;

-- Add constraint to ensure status is one of the allowed values
ALTER TABLE public.recognition_records 
ADD CONSTRAINT check_status_values 
CHECK (status IN ('pending', 'approved', 'rejected'));

-- Create index on status for better query performance
CREATE INDEX IF NOT EXISTS idx_recognition_records_status 
ON public.recognition_records(status);

-- Verify the changes
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'recognition_records' 
AND column_name = 'status';

-- Show sample data with new status column
SELECT id, startup_id, program_name, facilitator_code, status, created_at 
FROM public.recognition_records 
LIMIT 5;
