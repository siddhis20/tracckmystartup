-- ADD_INVESTOR_CODE_TO_STARTUP_REQUESTS.sql
-- Add investor_code and status to startup_addition_requests for investor approvals

ALTER TABLE startup_addition_requests
ADD COLUMN IF NOT EXISTS investor_code TEXT,
ADD COLUMN IF NOT EXISTS status TEXT CHECK (status IN ('pending','approved','rejected')) DEFAULT 'pending';

CREATE INDEX IF NOT EXISTS idx_startup_addition_requests_investor_code
ON startup_addition_requests(investor_code);

