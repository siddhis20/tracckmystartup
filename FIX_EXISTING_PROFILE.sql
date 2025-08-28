-- Fix Existing User Profile - Update with Verification Documents
-- This will update the existing profile with the documents that were uploaded

-- 1. First, let's see what we're updating
SELECT 
  'Before Update' as info,
  id,
  email,
  name,
  role,
  government_id,
  ca_license,
  verification_documents,
  updated_at
FROM public.users 
WHERE id = 'fe28e158-c531-4bed-89f0-02e9dd905830';

-- 2. Update the profile with verification documents
UPDATE public.users 
SET 
  government_id = 'https://dlesebbmlrewsbmqvuza.supabase.co/storage/v1/object/public/verification-documents/olympiad_support1@startupnationindia.com/government-id_2025-08-24T09-16-56-803Z_TAM, SAM, SOM Template (1) (2).pdf',
  ca_license = 'https://dlesebbmlrewsbmqvuza.supabase.co/storage/v1/object/public/verification-documents/olympiad_support1@startupnationindia.com/ca-license_2025-08-24T09-16-57-341Z_Equity Division in Founders Template.pdf',
  verification_documents = ARRAY[
    'https://dlesebbmlrewsbmqvuza.supabase.co/storage/v1/object/public/verification-documents/olympiad_support1@startupnationindia.com/government-id_2025-08-24T09-16-56-803Z_TAM, SAM, SOM Template (1) (2).pdf',
    'https://dlesebbmlrewsbmqvuza.supabase.co/storage/v1/object/public/verification-documents/olympiad_support1@startupnationindia.com/ca-license_2025-08-24T09-16-57-341Z_Equity Division in Founders Template.pdf'
  ],
  updated_at = NOW()
WHERE id = 'fe28e158-c531-4bed-89f0-02e9dd905830';

-- 3. Verify the update worked
SELECT 
  'After Update' as info,
  id,
  email,
  name,
  role,
  government_id,
  ca_license,
  verification_documents,
  updated_at
FROM public.users 
WHERE id = 'fe28e158-c531-4bed-89f0-02e9dd905830';

-- 4. Check if there are any other users that need fixing
SELECT 
  'Other Users Needing Fix' as info,
  id,
  email,
  name,
  role,
  government_id,
  ca_license,
  verification_documents,
  created_at
FROM public.users 
WHERE (government_id IS NULL OR ca_license IS NULL OR verification_documents IS NULL)
  AND role IN ('CA', 'CS')
  AND created_at >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY created_at DESC;
