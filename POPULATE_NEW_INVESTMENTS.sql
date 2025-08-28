-- POPULATE_NEW_INVESTMENTS.sql
-- Populate the new_investments table with mock data to fix foreign key constraints

-- First, clear any existing data
DELETE FROM new_investments;

-- Reset the sequence to start from 101
ALTER SEQUENCE new_investments_id_seq RESTART WITH 101;

-- Insert mock data from constants.ts
INSERT INTO new_investments (
    id, name, investment_type, investment_value, equity_allocation, 
    sector, total_funding, total_revenue, registration_date, 
    pitch_deck_url, pitch_video_url, compliance_status, created_at
) VALUES 
    (101, 'QuantumLeap', 'Seed', 150000, 7, 'DeepTech', 150000, 0, '2024-02-01', '#', 'https://www.youtube.com/watch?v=QJ21TaeN9K0', 'Compliant', NOW()),
    (102, 'AgroFuture', 'SeriesA', 1200000, 18, 'AgriTech', 2500000, 400000, '2023-08-15', '#', 'https://www.youtube.com/watch?v=gt_l_4TfG4k', 'Pending', NOW()),
    (103, 'CyberGuard', 'SeriesB', 3000000, 10, 'Cybersecurity', 5000000, 1000000, '2022-07-22', '#', 'https://www.youtube.com/watch?v=rok_p26_Z5o', 'Compliant', NOW()),
    (104, 'BioSynth', 'Seed', 500000, 15, 'BioTech', 500000, 50000, '2024-01-05', '#', 'https://www.youtube.com/watch?v=8aGhZQkoFbQ', 'Compliant', NOW()),
    (105, 'RetailNext', 'SeriesA', 2500000, 12, 'RetailTech', 4000000, 800000, '2023-05-18', '#', 'https://www.youtube.com/watch?v=Y_N1_Jj9-KA', 'Pending', NOW()),
    (106, 'GameOn', 'Seed', 750000, 20, 'Gaming', 750000, 150000, '2023-11-30', '#', 'https://www.youtube.com/watch?v=d_HlPboL_sA', 'Compliant', NOW()),
    (107, 'PropTech Pro', 'PreSeed', 100000, 5, 'Real Estate', 100000, 10000, '2024-03-01', '#', 'https://www.youtube.com/watch?v=uK67H2PAmn8', 'Pending', NOW()),
    (108, 'LogiChain', 'SeriesA', 1800000, 9, 'Logistics', 3000000, 600000, '2022-09-10', '#', 'https://www.youtube.com/watch?v=uJg4B5a-a28', 'Compliant', NOW()),
    (109, 'EduKids', 'Seed', 300000, 10, 'EdTech', 300000, 60000, '2023-10-25', '#', 'https://www.youtube.com/watch?v=GGlY3g_2Q_E', 'NonCompliant', NOW()),
    (110, 'QuantumLeap 2', 'Seed', 150000, 7, 'DeepTech', 150000, 0, '2024-02-01', '#', 'https://www.youtube.com/watch?v=P1ww1X2-S1U', 'Compliant', NOW()),
    (111, 'SpaceHaul', 'SeriesB', 10000000, 15, 'Aerospace', 25000000, 500000, '2021-12-01', '#', 'https://www.youtube.com/watch?v=sO-tjb4Edb8', 'Compliant', NOW()),
    (112, 'MindWell', 'Seed', 400000, 12, 'HealthTech', 400000, 80000, '2024-04-10', '#', 'https://www.youtube.com/watch?v=4x7_v-2-a3I', 'Compliant', NOW()),
    (113, 'CleanPlate', 'Seed', 200000, 8, 'FoodTech', 200000, 40000, '2023-09-05', '#', 'https://www.youtube.com/watch?v=ysz5S6PUM-U', 'Pending', NOW()),
    (114, 'Solaris', 'SeriesA', 2200000, 11, 'GreenTech', 3500000, 700000, '2022-11-20', '#', 'https://www.youtube.com/watch?v=o0u4M6vppCI', 'Compliant', NOW()),
    (115, 'LegalEase', 'PreSeed', 120000, 6, 'LegalTech', 120000, 25000, '2024-05-15', '#', 'https://www.youtube.com/watch?v=J132shgI_Ns', 'Pending', NOW()),
    (116, 'TravelBug', 'Seed', 600000, 14, 'TravelTech', 600000, 120000, '2023-03-12', '#', 'https://www.youtube.com/watch?v=T_i-T58-S2E', 'Compliant', NOW()),
    (117, 'DataWeave', 'SeriesB', 4500000, 10, 'Data Analytics', 8000000, 1500000, '2021-10-01', '#', 'https://www.youtube.com/watch?v=R2vXbFp5C9o', 'Compliant', NOW()),
    (118, 'AutoDrive', 'SeriesA', 5000000, 18, 'Automotive', 10000000, 800000, '2022-06-01', '#', 'https://www.youtube.com/watch?v=uA8X54c_w18', 'NonCompliant', NOW());

-- Verify the data was inserted
SELECT COUNT(*) as total_investments FROM new_investments;

-- Show the inserted data
SELECT id, name, investment_type, investment_value, equity_allocation, sector, compliance_status 
FROM new_investments 
ORDER BY id;
