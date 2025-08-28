-- TEST_VIDEO_URLS.sql
-- Check video URLs in fundraising_details table

-- 1. Check all fundraising details with video URLs
SELECT 
    fd.id as fundraising_id,
    fd.startup_id,
    s.name as startup_name,
    fd.pitch_video_url,
    fd.pitch_deck_url,
    fd.active,
    fd.type,
    fd.value,
    fd.equity
FROM fundraising_details fd
LEFT JOIN startups s ON fd.startup_id = s.id
WHERE fd.active = true
ORDER BY fd.startup_id;

-- 2. Check if video URLs are properly formatted
SELECT 
    fd.startup_id,
    s.name as startup_name,
    fd.pitch_video_url,
    CASE 
        WHEN fd.pitch_video_url LIKE '%youtube.com/watch?v=%' THEN 'YouTube Watch URL'
        WHEN fd.pitch_video_url LIKE '%youtu.be/%' THEN 'YouTube Short URL'
        WHEN fd.pitch_video_url LIKE '%youtube.com/embed/%' THEN 'YouTube Embed URL'
        WHEN fd.pitch_video_url IS NULL THEN 'No Video URL'
        ELSE 'Other Format'
    END as url_type
FROM fundraising_details fd
LEFT JOIN startups s ON fd.startup_id = s.id
WHERE fd.active = true
ORDER BY fd.startup_id;
