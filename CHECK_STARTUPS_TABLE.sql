-- Check startups table structure
-- This will show us what columns actually exist

SELECT 
  'startups table columns' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'startups'
ORDER BY ordinal_position;

-- Check if there are any startups
SELECT 
  'Startups count' as info,
  COUNT(*) as total_startups
FROM startups;

-- Show sample startup data
SELECT 
  'Sample startup' as info,
  *
FROM startups 
LIMIT 1;

